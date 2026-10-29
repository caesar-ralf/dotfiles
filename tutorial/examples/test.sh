#!/usr/bin/env bash
#
# test.sh -- checks for the tutorial examples. Fully non-interactive: it only
# exercises the argument, error and no-terminal paths, never the fzf UI.
#
# Usage: tutorial/examples/test.sh

set -o errexit -o nounset -o pipefail

cd "$(dirname "$0")"

PASS=0
FAIL=0
ok()  { PASS=$((PASS + 1)); printf '  ok    %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf '  FAIL  %s\n' "$1"; }

# expect WANT_EXIT NAME CMD...: run CMD without a terminal on stdin; keep its
# stdout in $OUT for further checks.
OUT=""
expect() {
    local want="$1" name="$2" rc=0
    shift 2
    OUT="$("$@" </dev/null 2>/dev/null)" || rc=$?
    if [ "$rc" = "$want" ]; then ok "$name"; else bad "$name (exit $rc, want $want)"; fi
}
# contains NAME TEXT: $OUT contains TEXT.
contains() {
    case "$OUT" in *"$2"*) ok "$1" ;; *) bad "$1 (output: $OUT)" ;; esac
}

TMP="$(mktemp -d "${TMPDIR:-/tmp}/tutorial-test.XXXXXX")"
SLEEP_PID=""
cleanup() {
    rm -rf "$TMP"
    if [ -n "$SLEEP_PID" ]; then kill "$SLEEP_PID" 2>/dev/null || true; fi
}
trap cleanup EXIT

echo "syntax (/bin/bash = 3.2 on macOS)"
for f in *.sh; do
    if /bin/bash -n "$f"; then ok "$f"; else bad "$f"; fi
done
if command -v shellcheck >/dev/null 2>&1; then
    if shellcheck -S warning ./*.sh; then ok "shellcheck"; else bad "shellcheck"; fi
fi
for f in skeleton pick-basic pick-commits pick-env fkill; do
    expect 0 "$f --help" ./"$f".sh --help
    contains "$f --help prints usage" "Usage:"
done

echo "skeleton"
printf 'data\n' > "$TMP/a.txt"
mkdir "$TMP/out"
expect 2 "no FILE = usage error"        ./skeleton.sh
expect 2 "unknown option = usage error" ./skeleton.sh --bogus "$TMP/a.txt"
expect 2 "-d needs an argument"         ./skeleton.sh -d
expect 0 "dry run"                      ./skeleton.sh -n "$TMP/a.txt"
if [ -e "$TMP/a.txt.bak" ]; then bad "dry run changed nothing"; else ok "dry run changed nothing"; fi
expect 0 "copy into -d DIR"             ./skeleton.sh -d "$TMP/out" "$TMP/a.txt"
contains "prints the copy's path" "$TMP/out/a.txt.bak"
if [ -f "$TMP/out/a.txt.bak" ]; then ok "copy exists"; else bad "copy exists"; fi
expect 1 "missing FILE = runtime error" ./skeleton.sh "$TMP/nope"

echo "pick-env"
expect 0 "argument skips the picker"    ./pick-env.sh dev
contains "prints the choice" "dev"
expect 2 "unknown environment"          ./pick-env.sh nope
expect 2 "no argument, no terminal"     ./pick-env.sh
expect 1 "prod without --yes, no terminal" ./pick-env.sh prod
expect 0 "prod with --yes"              ./pick-env.sh --yes prod

echo "pick-commits"
expect 2 "-n must be a number"          ./pick-commits.sh -n abc
expect 1 "outside a git repo"           sh -c "cd '$TMP' && GIT_CEILING_DIRECTORIES='$TMP' '$PWD/pick-commits.sh'"

if command -v fzf >/dev/null 2>&1; then
    echo "fkill (dry run only)"
    sleep 31337 &
    SLEEP_PID=$!
    expect 2 "unknown signal"           ./fkill.sh -s NOPE -q x
    expect 2 "no terminal needs -q"     ./fkill.sh -n
    expect 0 "--filter selects by query" ./fkill.sh -n -q "'sleep '31337"
    contains "selected our sleep" "$SLEEP_PID"
    expect 1 "no match"                 ./fkill.sh -n -q "'no-such-process-xyzzy"
    expect 1 "no terminal, no --yes: refuses" ./fkill.sh -q "'sleep '31337"
    if kill -0 "$SLEEP_PID" 2>/dev/null; then ok "nothing was killed"; else bad "nothing was killed"; fi
else
    echo "fkill: SKIP (fzf not installed)"
fi

echo
if [ "$FAIL" -eq 0 ]; then
    echo "ALL TUTORIAL CHECKS PASSED ($PASS)"
else
    echo "$FAIL FAILED, $PASS passed"
    exit 1
fi
