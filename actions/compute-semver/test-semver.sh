#!/usr/bin/env bash
set -euo pipefail

FAILS=0
SCRIPT="./compute-semver.sh"
MAJOR_TYPES="BREAKING CHANGE,BREAKING-CHANGE,!"
MINOR_TYPES="feat,feature"

run_test() {
  local name="$1"
  local commits="$2"
  local latest="$3"
  local package_path="$4"
  local trunk="$5"
  local expected="$6"

  export GITHUB_OUTPUT="$(mktemp)"

  "$SCRIPT" \
    "$commits" \
    "$package_path" \
    "$latest" \
    "v" \
    "alpha" \
    "$trunk" \
    "$MAJOR_TYPES" \
    "$MINOR_TYPES"

  actual="$(grep '^SEMVER=' "$GITHUB_OUTPUT" | cut -d= -f2)"
  actual_tag="$(grep '^TAG_NAME=' "$GITHUB_OUTPUT" | cut -d= -f2)"

  echo "Test: $name (actual: $actual, tag: $actual_tag)"

  if [[ "$actual" == "$expected" && "$actual" != "" && "$actual_tag" != "" ]]; then
    echo "$name → $actual"
  fi
  if [[ "$actual" != "$expected" || -z "$actual" || -z "$expected" || "$actual" == ""  ]]; then
    echo "$name"
    echo "   expected: $expected"
    echo "   actual:   $actual"
    echo "   actual tag:   $actual_tag"
    FAILS=$((FAILS+1))
  fi
}

# ---------------- PATCH ----------------
run_test "patch fix" \
  $'fix: bug\n==END==\n' \
  "v1.2.3" \
  "" \
  true \
  "v1.2.4"

run_test "docs patch" \
  $'docs: readme\n==END==\n' \
  "v1.2.3" \
  "" \
  true \
  "v1.2.4"

# ---------------- MINOR ----------------
run_test "feat minor" \
  $'feat: add feature\n==END==\n' \
  "v1.2.3" \
  "" \
  true \
  "v1.3.0"

run_test "scoped feat" \
  $'feat(api): add\n==END==\n' \
  "v1.2.3" \
  "" \
  true \
  "v1.3.0"

run_test "feature alias" \
  $'feature: add\n==END==\n' \
  "v1.2.3" \
  "" \
  true \
  "v1.3.0"

# ---------------- MAJOR ----------------
run_test "bang header" \
  $'feat!: breaking change\n==END==\n' \
  "v1.2.3" \
  "" \
  true \
  "v2.0.0"

run_test "scoped bang" \
  $'feat(core)!: breaking\n==END==\n' \
  "v1.2.3" \
  "" \
  true \
  "v2.0.0"

run_test "breaking footer" \
  $'fix: x\nBREAKING CHANGE: y\n==END==\n' \
  "v1.2.3" \
  "" \
  true \
  "v2.0.0"

run_test "breaking hyphen footer" \
  $'fix: x\n\nBREAKING-CHANGE: y\n==END==\n' \
  "v1.2.3" \
  "" \
  true \
  "v2.0.0"

# ---------------- MIXED ----------------
run_test "minor then major" \
  $'feat: a\n==END==\nfix!: b\n==END==\n' \
  "v0.1.0" \
  "" \
  true \
  "v1.0.0"

run_test "major anywhere wins" \
  $'fix: a\n==END==\nfeat: b\n==END==\nchore!: boom\n==END==\n' \
  "v3.4.5" \
  "" \
  true \
  "v4.0.0"

# ---------------- PRERELEASE ----------------
run_test "alpha first" \
  $'fix: a\n==END==\n' \
  "v1.0.0" \
  "" \
  false \
  "v1.0.1-alpha.1"

run_test "alpha increments only if same base" \
  $'fix: a\n==END==\n' \
  "v1.0.1-alpha.1" \
  "" \
  false \
  "v1.0.2-alpha.1"

run_test "minor alpha" \
  $'feat: a\n==END==\n' \
  "v1.2.3" \
  "" \
  false \
  "v1.3.0-alpha.1"

run_test "major alpha" \
  $'feat!: a\n==END==\n' \
  "v1.2.3" \
  "" \
  false \
  "v2.0.0-alpha.1"

# ---------------- MONOREPO PREFIX ----------------
run_test "package path preserved" \
  $'fix: a\n==END==\n' \
  "packages/api/v1.0.0" \
  "packages/api" \
  false \
  "v1.0.1-alpha.1"

if (( FAILS > 0 )); then
  echo
  echo "$FAILS tests failed"
  exit 1
else
  echo
  echo "All tests passed"
fi