# .github

A repository for GitHub Actions, reusable workflows and other GitHub-related resources for Compairifuel.

## Reusable workflows

All reusable workflows are located in the `.github/workflows` directory.
Each workflow is defined in a separate YAML file and can be referenced in other workflows.

- [`reusable-codesecscan.yml`](./.github/workflows/reusable-codesecscan.yml): A reusable workflow for running Semgrep, a static code analysis tool. This workflow can be used to identify security vulnerabilities and code quality issues in the code.
- [`reusable-commitlinter.yml`](./.github/workflows/reusable-commitlinter.yml): A reusable workflow for linting commit messages using a custom GitHub Action. This workflow ensures that commit messages follow a specified format and helps maintain a clean commit history.
- [`reusable-containerregistrypusher.yml`](./.github/workflows/reusable-containerregistrypusher.yml): A reusable workflow for pushing container images to a container registry. This workflow can be used to automate the process of building and deploying container images to a registry such as Docker Hub or GitHub Container Registry.
- [`reusable-createrelease.yml`](./.github/workflows/reusable-createrelease.yml): A reusable workflow for creating releases on GitHub. This workflow can be used to automate the process of creating a new release, including tagging the release and generating release notes.
- [`reusable-labelsync.yml`](./.github/workflows/reusable-labelsync.yml): A reusable workflow for synchronizing labels across repositories. This workflow can be used to ensure that labels are consistent across multiple repositories, making it easier to manage issues and pull requests.
- [`reusable-nextsemver.yml`](./.github/workflows/reusable-nextsemver.yml): A reusable workflow for determining the next semantic version based on commit messages. This workflow can be used to automate the process of versioning a project according to the Semantic Versioning specification.

## GitHub Actions

All custom GitHub Actions are located in the `actions` directory.
Each action is defined in a separate directory and includes an `action.yml` file that specifies the action's metadata and inputs/outputs.

- [`compute-semver`](./actions/compute-semver): A custom GitHub Action for computing the next semantic version based on commit messages. This action is used within the `reusable-nextsemver.yml` workflow to automate versioning.
- [`validate-commits`](./actions/validate-commits): A custom GitHub Action for validating commit messages against a specified format. This action is used within the `reusable-commitlinter.yml` workflow to maintain a clean commit history.
- [`labelsync`](./actions/labelsync): A custom GitHub Action for synchronizing labels across repositories. This action is used within the `reusable-labelsync.yml` workflow to ensure consistent labeling across multiple repositories.

## Profile README

This repository also contains the profile README for the Compairifuel GitHub organization. Its file is located in `profile/README.md`.
The profile README is displayed on the organization's main page and provides an overview of the overall project's requirements, features and other project related information.