#!/usr/bin/env bash
set -euo pipefail

FAILS=0
SCRIPT="./validate-commits.sh"
ALLOWED_TYPES="build,chore,ci,docs,feat,fix,perf,refactor,revert,style,test"

run_test() {
  local name="$1"
  local commits="$2"
  local should_pass="$3"

  COMMITS_FILE="$(mktemp)"
  printf '%s\n' "$commits" > "$COMMITS_FILE"

  echo "Running test: $name"

  if "$SCRIPT" "$COMMITS_FILE" "$ALLOWED_TYPES" > /tmp/test.out 2>&1; then
    if [[ "$should_pass" == "true" ]]; then
      echo "$name"
    else
      echo "$name (expected failure, but passed)"
      cat /tmp/test.out
      FAILS=$((FAILS+1))
    fi
  else
    if [[ "$should_pass" == "false" ]]; then
      echo "$name (failed as expected)"
    else
      echo "$name (unexpected failure)"
      cat /tmp/test.out
      FAILS=$((FAILS+1))
    fi
  fi

  echo
}

# ---------------- VALID (case-insensitive) ----------------
run_test "lowercase feat" \
  $'feat: add feature\n==END==\n' \
  true

run_test "uppercase FEAT" \
  $'FEAT: add feature\n==END==\n' \
  true

run_test "mixed case Fix" \
  $'Fix: bug fix\n==END==\n' \
  true

run_test "scoped mixed case" \
  $'Feat(Api): add endpoint\n==END==\n' \
  true

run_test "bang breaking uppercase" \
  $'FEAT!: breaking change\n==END==\n' \
  true

run_test "breaking footer uppercase" \
  $'fix: bug\n\nBREAKING CHANGE: api changed\n==END==\n' \
  true

run_test "breaking footer lowercase" \
  $'fix: bug\n\nbreaking change: api changed\n==END==\n' \
  true

run_test "multiple commits mixed case" \
  $'Fix: bug\n==END==\nCHORE: cleanup\n==END==\n' \
  true

run_test "commit with body and breaking change footer" \
  $'fix(core): handle nil pointer\n\nGuard against nil inputs during init.\n\nRefs: #42\nBREAKING CHANGE: init() now panics on nil\n==END==\n' \
  true

# ---------------- INVALID ----------------
run_test "unknown type mixed case" \
  $'Foobar: no\n==END==\n' \
  false

run_test "missing colon" \
  $'feat add feature\n==END==\n' \
  false

run_test "empty subject" \
  $'fix:\n==END==\n' \
  false

# ---------------- INVALID FOOTERS ----------------
run_test "commit with invalid footer after valid footer" \
  $'fix(core): handle nil pointer\n\nRefs: #42\nmore text\n==END==\n' \
  false

run_test "commit with invalid footer" \
  $'fix(core): handle nil pointer\nRefs: #42\n==END==\n' \
  false

# ---------------- MIXED ----------------
run_test "one bad commit fails all" \
  $'Fix: ok\n==END==\nbad commit\n==END==\n' \
  false

run_test "major + valid mixed case" \
  $'Feat!: big change\n==END==\nFix: ok\n==END==\n' \
  true

# ---------------- EDGE CASES ----------------
run_test "trailing whitespace" \
  $'FIX: bug   \n==END==\n' \
  true

run_test "empty input" \
  $'==END==\n' \
  true

run_test "only blank commits" \
  $'\n==END==\n\n==END==\n' \
  true

# ---------------- RESULT ----------------
if (( FAILS > 0 )); then
  echo "$FAILS tests failed"
  exit 1
else
  echo "All tests passed"
fi
