import { getInput, info, debug, warning, setFailed } from "@actions/core";
import { context, getOctokit } from "@actions/github";
import { existsSync } from "node:fs";
import { readFile } from "node:fs/promises";
import { parse } from "yaml";

function getRepoDataFromTag(repoTag) {
    const parsed = /^(.+)\/(.+):(.+)$/.exec(repoTag);
    if (!parsed) {
        throw new Error(`Invalid repository tag format: ${repoTag}`);
    }
    return {
        owner: parsed[1],
        repo: parsed[2],
        path: parsed[3],
    };
}

function getYamlFromRepo(octokit, options) {
    info("Fetching YAML from repository: " + `${options.owner}/${options.repo}:${options.path}`);
    return octokit.rest.repos.getContent(options)
        .then((res) => {
            debug("Response from GitHub API: " + JSON.stringify(res));
            if (res.status !== 200) {
                throw new Error(`Failed to fetch labels from repository: ${res.status}`);
            }
            if (res.data.type !== "file") {
                throw new Error("Invalid response: expected a file");
            }
            return Buffer.from(res.data.content, "base64").toString("utf8");
        });
}

async function getLabelsFromExtends(octokit, extendsTag) {
    debug("Found extends tag: " + extendsTag);

    if (typeof extendsTag === "string") {
        debug("Fetching labels from extends tag: " + extendsTag);
        const data = getRepoDataFromTag(extendsTag);
        debug("Parsed extends tag: " + JSON.stringify(data));
        const yaml = await getYamlFromRepo(octokit, data);
        debug("Parsed YAML from extends tag: " + yaml);
        return getLabelsFromYaml(octokit, yaml);
    }

    if (Array.isArray(extendsTag)) {
        debug("Fetching labels from extends tags: " + extendsTag.join(", "));
        if (extendsTag.length === 0) return [];
        if (extendsTag.some(tag => typeof tag !== "string")) {
            throw new Error("Invalid extends tag: must be a string or an array of strings");
        }
        return Promise.all(extendsTag.map(tag => getLabelsFromExtends(octokit, tag)));
    }

    throw new Error("Invalid extends tag: must be a string or an array of strings");
}

async function getLabelsFromYaml(octokit, yaml) {
    const parsed = parse(yaml);

    if (!("labels" in parsed)) {
        throw new Error("Invalid labels file: missing 'labels' key");
    }

    if (!Array.isArray(parsed.labels)) {
        throw new Error("Invalid labels file: 'labels' key must be an array");
    }

    return [
        ...parsed.labels,
        ...(parsed.extends ? await getLabelsFromExtends(octokit, parsed.extends) : []),
    ].flat();
}

function validateLabel(label) {
    debug("Processing label: " + JSON.stringify(label));
    if (typeof label !== "object" || label === null || Array.isArray(label)) {
        warning("Invalid label, must be an object. Skipping: " + JSON.stringify(label));
        return false;
    }
    if (!("name" in label) || typeof label.name !== "string") {
        warning("Invalid label, must have a name that is a string. Skipping: " + JSON.stringify(label));
        return false;
    }
    if (!("color" in label) || !/^[a-fA-F0-9]{6}|[a-fA-F0-9]{3}$/.test(label.color)) {
        warning("Invalid label, must have a color that is a hexadecimal color string without a #. Skipping: "
            + JSON.stringify(label));
        return false;
    }
    if ("description" in label && typeof label.description !== "string") {
        warning("Invalid label description, must be a string. Skipping: " + JSON.stringify(label));
        return false;
    }
    return true;
}

async function* labelsWithExistsGenerator(octokit, labels) {
    for (const label of labels) {
        info(`Processing label: ${JSON.stringify(label)}`);
        if (!validateLabel(label)) {
            continue;
        }
        yield octokit.rest.issues.getLabel({
            ...context.repo,
            name: label.name
        }).then(() => ({
            label,
            exists: true,
        })).catch(() => ({
            label,
            exists: false,
        }));
    }
}

async function* createLabelsGenerator(octokit, labels, dryRun) {
    for await (const { label, exists } of labelsWithExistsGenerator(octokit, labels)) {
        info(`Label ${exists ? "already exists, updating" : "does not exist, creating"}: ${JSON.stringify(label)}`);
        if (dryRun) {
            yield {
                status: 200,
                data: label,
            };
            continue;
        }
        if (exists) {
            yield octokit.rest.issues.updateLabel({
                ...context.repo,
                ...label
            });
        } else {
            yield octokit.rest.issues.createLabel({
                ...context.repo,
                ...label
            });
        }
    }
}

async function createLabels(octokit, labels, dryRun) {
    if (dryRun) {
        warning("Running in dry run mode, no labels will be created");
    }
    if (!Array.isArray(labels)) {
        throw new Error("Invalid labels: must be an array");
    }
    if (labels.length === 0) return;
    for await (const res of createLabelsGenerator(octokit, labels, dryRun)) {
        if (res.status !== 200 && res.status !== 201) {
            throw new Error(`Failed to create label: ${res.status}`);
        }
        info(`Created label: ${res.data.name} (${res.data.color})`);
    }
}

function getRepoLabels(octokit) {
    return octokit.paginate(octokit.rest.issues.listLabelsForRepo, {
        ...context.repo,
    }).then((labels) => labels.map(label => ({
        name: label.name,
        color: label.color,
        description: label.description || "",
    })));
}

function deleteLabels(octokit, repoLabels, labels, dryRun) {
    if (dryRun) {
        warning("Running in dry run mode, no labels will be deleted");
    }
    if (!Array.isArray(repoLabels)) {
        throw new Error("Invalid repo labels: must be an array");
    }
    if (!Array.isArray(labels)) {
        throw new Error("Invalid labels: must be an array");
    }
    return Promise.all(repoLabels
        .filter(label => !labels.some(l => l.name === label.name))
        .map(label => {
            info(`Deleting label: ${label.name}`);
            if (dryRun) {
                return Promise.resolve({
                    status: 200,
                    data: label,
                });
            }
            return octokit.rest.issues.deleteLabel({
                ...context.repo,
                name: label.name,
            });
        }));
}

function getInputs() {
    const githubToken = getInput("github-token", {required: true});
    const labelsFile = getInput("labels-file", {required: true});
    const skipDelete = getInput("skip-delete", {required: true});
    const dryRun = getInput("dry-run", {required: true});

    if (skipDelete !== "true" && skipDelete !== "false") {
        throw new Error("Invalid skip-delete input: must be 'true' or 'false'");
    }

    if (dryRun !== "true" && dryRun !== "false") {
        throw new Error("Invalid dry-run input: must be 'true' or 'false'");
    }

    return {
        githubToken,
        labelsFile,
        skipDelete: skipDelete === "true",
        dryRun: dryRun === "true",
    };
}

async function run() {
    try {
        const {githubToken, labelsFile, skipDelete, dryRun} = getInputs();

        if (!existsSync(labelsFile)) {
            setFailed(`Cannot find labels file ${labelsFile}`);
            return;
        }

        const octokit = getOctokit(githubToken);

        info(`Using labels file ${labelsFile}`);

        const labelsYaml = await readFile(labelsFile, {encoding: "utf8"});
        const labels = await getLabelsFromYaml(octokit, labelsYaml);
        const repoLabels = await getRepoLabels(octokit);

        debug("Current labels in repository: " + JSON.stringify(repoLabels, null, 2));
        debug(`Parsed labels: ${JSON.stringify(labels, null, 2)}`);

        if (!skipDelete) {
            await deleteLabels(octokit, repoLabels, labels, dryRun);
        }

        await createLabels(octokit, labels, dryRun);
    } catch (error) {
        setFailed(error.message);
    }
}

await run();
