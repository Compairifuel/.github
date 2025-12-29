#!/usr/bin/env bash
set -euo pipefail

FAILS=0
SCRIPT="./validate-commits.sh"
ALLOWED_TYPES="build,chore,ci,docs,feat,fix,perf,refactor,revert,style,test"

run_test() {
  local name="$1"
  local commits="$2"
  local should_pass="$3"

  echo "Running test: $name"

  if "$SCRIPT" "$commits" "$ALLOWED_TYPES" > /tmp/test.out 2>&1; then
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
run_test "invalid footer format" \
  $'fix: bug\n\nnot a footer\n==END==\n' \
  false

run_test "footer missing space" \
  $'fix: bug\n\nBREAKING CHANGE:nope\n==END==\n' \
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

# ---------------- RESULT ----------------
if (( FAILS > 0 )); then
  echo "$FAILS tests failed"
  exit 1
else
  echo "All tests passed"
fi
