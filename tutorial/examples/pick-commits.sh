#!/usr/bin/env bash
#
# pick-commits -- advanced fzf: a hidden key column, a preview, multi-select,
# and a different action per key.
#
# Usage: pick-commits [-n COUNT] [QUERY]
#
#   -n COUNT   how many commits to list (default 200)
#   QUERY      pre-fill the search box
#
# Keys in the picker:
#   Enter    print the selected hashes, one per line
#   Ctrl-Y   copy the selected hashes to the clipboard
#   Ctrl-S   print `git show --stat` of each selected commit
#   Tab      mark / unmark a commit (select several)
#   ?        show / hide the preview
#
# Exit codes: 0 ok, 1 error or no match, 2 usage, 130 cancelled.

set -o errexit -o nounset -o pipefail

PROG="${0##*/}"
usage()       { awk 'NR > 2 { if (!/^#/) exit; sub(/^# ?/, ""); print }' "$0"; }
die()         { printf '%s: %s\n' "$PROG" "$*" >&2; exit 1; }
usage_error() { printf '%s: %s\nTry "%s --help".\n' "$PROG" "$*" "$PROG" >&2; exit 2; }

COUNT=200
while [ $# -gt 0 ]; do
    case "$1" in
        -n) [ $# -ge 2 ] || usage_error "-n needs a number"; COUNT="$2"; shift ;;
        -h|--help) usage; exit 0 ;;
        -?*) usage_error "unknown option: $1" ;;
        *) break ;;
    esac
    shift
done
case "$COUNT" in ''|*[!0-9]*) usage_error "-n needs a number, got '$COUNT'" ;; esac
[ $# -le 1 ] || usage_error "too many arguments"

command -v fzf >/dev/null 2>&1 || die "fzf is required (brew install fzf)"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "not inside a git repository"

TAB="$(printf '\t')"

# One commit per line: HASH <TAB> AGE <TAB> SUBJECT.
# Field 1 (the hash) is what we need afterwards, but it's noise for the user:
# --with-nth 2,3 hides it in the list, while {1} in --preview and the selected
# lines we get back still contain it.
list_commits() {
    git log -n "$COUNT" --format='%h%x09%cr%x09%s'
}

rc=0
out="$(set +o pipefail
       list_commits | fzf \
           --multi --height 80% --layout reverse --border \
           --delimiter "$TAB" --with-nth 2,3 \
           --prompt 'commit> ' --query "${1:-}" \
           --header 'Enter: print   Ctrl-Y: copy   Ctrl-S: show   Tab: mark   ?: preview' \
           --preview 'git show --stat --color=always {1}' \
           --preview-window 'right,60%,wrap' \
           --bind '?:toggle-preview' \
           --expect 'ctrl-y,ctrl-s')" || rc=$?

case "$rc" in
    0)   ;;
    1)   die "no commit matches" ;;
    130) exit 130 ;;
    *)   die "fzf failed (exit $rc)" ;;
esac

# With --expect the first line is the key that ended fzf (empty for Enter);
# the selected lines follow. Cut the hidden hash column back out.
key="$(printf '%s\n' "$out" | sed -n 1p)"
hashes="$(printf '%s\n' "$out" | sed 1d | cut -f1)"

case "$key" in
    ctrl-y)
        command -v pbcopy >/dev/null 2>&1 || die "pbcopy not found (Linux: see core/platform/linux-bin)"
        printf '%s\n' "$hashes" | pbcopy
        printf '%s: copied %s hash(es)\n' "$PROG" "$(printf '%s\n' "$hashes" | wc -l | tr -d ' ')" >&2
        ;;
    ctrl-s)
        for h in $hashes; do git --no-pager show --stat "$h"; done
        ;;
    *)
        printf '%s\n' "$hashes"
        ;;
esac
