#!/usr/bin/env bash
set -euo pipefail
set -f

COMMITS="$(cat "$1")"
PACKAGE_PATH="$2"
LATEST_TAG="$3"
VERSION_PREFIX="$4"
ALPHA_SUFFIX="$5"
ISTRUNK="$6"
MAJOR_TYPES_RAW="$7"
MINOR_TYPES_RAW="$8"

readarray -t MAJOR_TYPES < <(printf '%s\n' "$MAJOR_TYPES_RAW" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
readarray -t MINOR_TYPES < <(printf '%s\n' "$MINOR_TYPES_RAW" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

matches_type() {
  local commit="$1"
  local type="$2"
  local regex

  commit="${commit#"${commit%%[![:space:]]*}"}"
  commit="${commit%"${commit##*[![:space:]]}"}"

  case "$type" in
    "!")
      regex='^[a-zA-Z0-9]+(\([^)]*\))?!:'
      ;;
    "BREAKING CHANGE"|"BREAKING-CHANGE")
      regex='BREAKING[ -]CHANGE:'
      ;;
    *)
      regex="^${type}(\([^)]*\))?:"
      ;;
  esac

  [[ "$commit" =~ $regex ]]
}

# === Determine bump type and changelog ===
OVERALL_BUMP="patch"
CHANGELOG_ENTRIES=()

bump_rank() {
  case "$1" in
    patch) echo 0 ;;
    minor) echo 1 ;;
    major) echo 2 ;;
  esac
}

mapfile -d '' -t COMMIT_ARRAY < <(
  printf '%s' "$COMMITS" | sed 's/==END==/\x0/g'
)


for commit in "${COMMIT_ARRAY[@]}"; do
  commit="${commit#"${commit%%[![:space:]]*}"}"
  commit="${commit%"${commit##*[![:space:]]}"}"
  [[ -z "$commit" ]] && continue

  COMMIT_BUMP="patch"
  TYPE_LABEL="PATCH"

  for t in "${MAJOR_TYPES[@]}"; do
    if matches_type "$commit" "$t"; then
      COMMIT_BUMP="major"
      TYPE_LABEL="MAJOR"
      break
    fi
  done

  if [[ "$COMMIT_BUMP" != "major" ]]; then
    for t in "${MINOR_TYPES[@]}"; do
      if matches_type "$commit" "$t"; then
        COMMIT_BUMP="minor"
        TYPE_LABEL="MINOR"
        break
      fi
    done
  fi

  if (( $(bump_rank "$COMMIT_BUMP") > $(bump_rank "$OVERALL_BUMP") )); then
    OVERALL_BUMP="$COMMIT_BUMP"
  fi

  CHANGELOG_ENTRIES+=("[$TYPE_LABEL] $commit")
done

# === Extract version numbers from latest tag ===
BASE_VERSION="$(basename "$LATEST_TAG")"       # remove path prefix if any
BASE_VERSION="${BASE_VERSION#$VERSION_PREFIX}"  # remove "v" prefix
BASE_VERSION="${BASE_VERSION%%-*}"    # remove prerelease suffix if any

IFS='.' read -r MAJOR MINOR PATCH <<< "$BASE_VERSION"

# === Increment version according to bump type ===
case "$OVERALL_BUMP" in
  major)
    (( MAJOR+=1 ))
    MINOR=0
    PATCH=0
    ;;
  minor)
    (( MINOR+=1 ))
    PATCH=0
    ;;
  patch)
    (( PATCH+=1 ))
    ;;
esac


SEMVER_BASE="${MAJOR}.${MINOR}.${PATCH}"

if [[ "$ISTRUNK" != "true" ]]; then
  PRERELEASE_NUM=1

  if [[ "$(basename "$LATEST_TAG")" =~ ^${VERSION_PREFIX}?${SEMVER_BASE}-${ALPHA_SUFFIX}\.([0-9]+)$ ]]; then
    PRERELEASE_NUM="${BASH_REMATCH[1]}"
    ((PRERELEASE_NUM+=1))
  fi

  SEMVER="${VERSION_PREFIX}${SEMVER_BASE}-${ALPHA_SUFFIX}.${PRERELEASE_NUM}"
else
  SEMVER="${VERSION_PREFIX}${SEMVER_BASE}"
fi

TAG_NAME="${PACKAGE_PATH:+$PACKAGE_PATH/}${SEMVER}"

# === Prepare changelog as newline-separated string ===
CHANGELOG="$(printf "%s\n" "${CHANGELOG_ENTRIES[@]}")"

# === Output variables for composite action ===
echo "SEMVER=$SEMVER" >> $GITHUB_OUTPUT
echo "TAG_NAME=$TAG_NAME" >> $GITHUB_OUTPUT
echo "CHANGELOG<<EOF" >> $GITHUB_OUTPUT
echo "$CHANGELOG" >> $GITHUB_OUTPUT
echo "EOF" >> $GITHUB_OUTPUT
