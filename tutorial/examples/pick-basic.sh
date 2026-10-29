#!/usr/bin/env bash
#
# pick-basic -- the smallest correct fzf picker: choose a file, print its path.
#
# Usage: pick-basic [QUERY]
#
#   QUERY   pre-fill the search box. With exactly one match the file is
#           picked without showing the UI; with none, exit 1 at once.
#
# Exit codes: 0 picked, 1 no match, 2 usage, 130 cancelled (Esc / Ctrl-C).

set -o errexit -o nounset -o pipefail

PROG="${0##*/}"
usage() { awk 'NR > 2 { if (!/^#/) exit; sub(/^# ?/, ""); print }' "$0"; }
die()   { printf '%s: %s\n' "$PROG" "$*" >&2; exit 1; }

case "${1:-}" in -h|--help) usage; exit 0 ;; esac
[ $# -le 1 ] || { usage >&2; exit 2; }

command -v fzf >/dev/null 2>&1 || die "fzf is required (brew install fzf)"

# The candidates: one per line on stdout. fd is faster and respects
# .gitignore; find is the fallback that exists everywhere.
list_files() {
    if command -v fd >/dev/null 2>&1; then
        fd --type f --hidden --exclude .git
    else
        find . -type f -not -path '*/.git/*' | sed 's|^\./||'
    fi
}

# `set +o pipefail` inside the substitution: when fzf exits early, list_files
# gets SIGPIPE (exit 141). With pipefail that 141 would hide fzf's own exit
# code, so we'd treat a normal pick as an error.
rc=0
choice="$(set +o pipefail
          list_files | fzf --height 40% --layout reverse --prompt 'file> ' \
                           --query "${1:-}" --select-1 --exit-0)" || rc=$?

case "$rc" in
    0)   printf '%s\n' "$choice" ;;          # the result, and nothing else, on stdout
    1)   die "no match" ;;
    130) exit 130 ;;                         # user cancelled: quiet, but non-zero
    *)   die "fzf failed (exit $rc)" ;;
esac
