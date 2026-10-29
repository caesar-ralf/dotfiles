#!/usr/bin/env bash
#
# Tests the global git hooks (git/git_global.symlink) and the Jira ticket
# detection end-to-end with real commits in a throwaway repo. Uses THIS
# checkout's hooks (not ~/.git_global), so it works before bootstrap too.
#
#   script/test/git-hooks.sh
DOTFILES="${DOTFILES:-$(cd "$(dirname "$0")/../.." && pwd -P)}"
set -u
PATH="$DOTFILES/git/bin:$PATH"
tmp="$(mktemp -d)"; cd "$tmp" || exit 1
git init -q -b main . && git config user.email t@example.com && git config user.name T
git config commit.verbose false; git config core.hooksPath "$DOTFILES/git/git_global.symlink/hooks"
git commit -q --allow-empty -m "init" 2>/dev/null
FAILS=0
expect() { # name, expected footer/last-line check
    local got; got="$(git log -1 --format=%B | sed '/^$/d' | tail -n1)"
    if [ "$got" = "$2" ]; then echo "PASS $1"; else echo "FAIL $1: last line=[$got] want=[$2]"; FAILS=1; fi
}
c() { git commit -q --allow-empty -m "$1" 2>/dev/null; }
br() { git switch -q -c "$1"; }

br feature/WEAV-1234-fix-login;        c "Fix login";                     expect "uppercase key"            "WEAV-1234"
br bugfix/weav-12-lower;               c "Lower";                         expect "lowercase branch"         "WEAV-12"
br feature/utf-8-support;              c "UTF8";                          expect "UTF-8 is not a ticket"    "UTF8"
br feature/sha-256-and-iso-8601;       c "hashes";                        expect "SHA/ISO ignored"          "hashes"
br WEAV-1-and-ABC-2;                   c "ambiguous";                     expect "ambiguous -> nothing"     "ambiguous"
br feature/WEAV-9-x;                   c "Support SHA-256 in tokens";     expect "SHA-256 in msg ignored"   "WEAV-9"
                                       c "Refs WEAV-77";                  expect "msg already has ticket"   "Refs WEAV-77"
                                       c "$(printf 'Pair\n\nCo-authored-by: A <a@x>')"
    got="$(git log -1 --format=%B | sed '/^$/d' | tr '\n' '|')"
    [ "$got" = "Pair|WEAV-9|Co-authored-by: A <a@x>|" ] && echo "PASS ticket before trailers" || { echo "FAIL trailers: $got"; FAILS=1; }
                                       c "fixup! Fix login";              expect "fixup! skipped"           "fixup! Fix login"
git switch -q main;                    c "on main";                       expect "main skipped"             "on main"
br ABC-1-WEAV-2;  git config hooks.ticketProjects "weav"; c "projects"; expect "projects filter picks WEAV" "WEAV-2"
git config --unset hooks.ticketProjects
br feature/no-ticket-here;             git ticket PLAT-55 >/dev/null; c "override"; expect "git ticket override" "PLAT-55"
                                       git ticket none >/dev/null;    c "none";     expect "git ticket none"     "none"
br feature/WEAV-3-chain
printf '#!/bin/sh\necho LOCAL >> "$1"\n' > .git/hooks/commit-msg; chmod +x .git/hooks/commit-msg
c "chain"; got="$(git log -1 --format=%B | sed '/^$/d' | tr '\n' '|')"
[ "$got" = "chain|LOCAL|WEAV-3|" ] && echo "PASS repo hook chained, then ours" || { echo "FAIL chain: $got"; FAILS=1; }
printf '#!/bin/sh\n# append the JIRA ticket parsed from the branch name\necho LEGACY >> "$1"\n' > .git/hooks/commit-msg
c "legacy"; expect "legacy copy skipped" "WEAV-3"
printf '#!/bin/sh\nexit 1\n' > .git/hooks/pre-commit; chmod +x .git/hooks/pre-commit
if git commit -q --allow-empty -m "blocked" 2>/dev/null; then echo "FAIL repo pre-commit not enforced"; FAILS=1; else echo "PASS repo pre-commit still enforced"; fi
rm .git/hooks/pre-commit
echo "--- git ticket output:"; git ticket
cd /; rm -rf "$tmp"
[ "$FAILS" = 0 ] && echo "ALL HOOK CHECKS PASSED" || echo "SOME HOOK CHECKS FAILED"
exit "$FAILS"
