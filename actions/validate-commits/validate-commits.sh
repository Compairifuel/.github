#!/usr/bin/env bash
set -euo pipefail
set -f

COMMITS="$(cat "$1")"
ALLOWED_TYPES="$2"

IFS=',' read -r -a ALLOWED_TYPES_ARRAY <<< "$ALLOWED_TYPES"

is_allowed_type() {
  local type="$1"
  for allowed in "${ALLOWED_TYPES_ARRAY[@],,}"; do
    [[ "$type" == "$allowed" ]] && return 0
  done
  return 1
}

validate_commit() {
  local msg="$1"

  # Header = first line
  local header
  header="$(printf "%s\n" "$msg" | head -n1)"

  if [[ ! "$header" =~ ^([a-zA-Z]+)(\([a-zA-Z0-9_-]+\))?(!)?:\ .+ ]]; then
    echo "Invalid commit header: $header"
    return 1
  fi

  local type="${BASH_REMATCH[1],,}"
  if ! is_allowed_type "$type"; then
    echo "Invalid type '$type'. Allowed: ${ALLOWED_TYPES_ARRAY[*],,}"
    return 1
  fi

  # Everything after header
  local rest
  rest="$(printf "%s\n" "$msg" | tail -n +2)"

  [[ -z "$rest" ]] && return 0

  local in_footer=0
  local saw_blank_before_footer=0
  local footer=""

  # Track line numbers to enforce blank line after header
  local lineno=0
  while IFS= read -r line; do
    ((lineno++))

    # Skip blank lines
    if [[ -z "$line" ]]; then
      # Mark that a blank line has been seen (important for footer detection)
      saw_blank_before_footer=1
      continue
    fi

    # --- Header ↔ body check ---
    if (( lineno == 1 )) && [[ $line =~ ^[^[:space:]] ]]; then
      echo "Body must be separated from header by a blank line"
      return 1
    fi

    # --- Footer detection ---
    if [[ $saw_blank_before_footer -eq 1 &&
          "$line" =~ ^(BREAKING[[:space:]-]CHANGE|[^:]+):\ .+ ]]; then
      in_footer=1
      footer+="$line"$'\n'
      continue
    fi

    # --- Non-footer line after footer started → invalid ---
    if [[ $in_footer -eq 1 ]]; then
      echo "Footer must be the final block and preceded by a blank line"
      return 1
    fi

    # --- Body content ---
    saw_blank_before_footer=0

  done <<< "$rest"

  [[ -z "$footer" ]] && return 0

  # Validate footer lines
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    if [[ "$line" =~ ^BREAKING[[:space:]-]CHANGE:\ .+ ]]; then
      continue
    elif [[ "$line" =~ ^[^:]+:\ .+ ]]; then
      continue
    else
      echo "Invalid footer line: $line"
      return 1
    fi
  done <<< "$footer"
}

mapfile -d '' -t COMMITS_ARRAY < <(
  printf '%s' "$COMMITS" | sed 's/==END==/\x0/g'
)

invalid=0
for commit in "${COMMITS_ARRAY[@]}"; do
  commit="${commit#"${commit%%[![:space:]]*}"}"
  commit="${commit%"${commit##*[![:space:]]}"}"
  [[ -z "$commit" ]] && continue

  if ! validate_commit "$commit"; then
    invalid=1
  fi
done

if [[ "$invalid" -eq 0 ]]; then
  echo "All commits are valid."
else
  echo "Some commits are invalid."
  exit 1
fi