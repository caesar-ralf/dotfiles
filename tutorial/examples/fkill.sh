#!/usr/bin/env bash
#
# fkill -- the complete example: pick processes with fzf and signal them.
# Puts every chapter of the tutorial together.
#
# Usage: fkill [-n] [-y] [-s SIGNAL] [-q QUERY]
#
#   -q, --query QUERY    pre-fill the search. Without a terminal, QUERY is
#                        required and selects every matching process
#                        (fzf --filter), so fkill also works in scripts.
#   -s, --signal SIGNAL  signal to send (default TERM), e.g. KILL, HUP, 9
#   -n, --dry-run        show what would be signalled, send nothing
#   -y, --yes            don't ask for confirmation
#   -h, --help           show this help
#
# Keys in the picker: Tab marks several processes, ? toggles the preview.
# Output: the PIDs that were (or would be) signalled, one per line.
# Exit codes: 0 ok, 1 nothing matched / declined / kill failed, 2 usage, 130 cancelled.

set -o errexit -o nounset -o pipefail

PROG="${0##*/}"
usage()       { awk 'NR > 2 { if (!/^#/) exit; sub(/^# ?/, ""); print }' "$0"; }
die()         { printf '%s: %s\n' "$PROG" "$*" >&2; exit 1; }
usage_error() { printf '%s: %s\nTry "%s --help".\n' "$PROG" "$*" "$PROG" >&2; exit 2; }
is_interactive() { [ -t 0 ] && [ -t 2 ]; }

QUERY="" SIGNAL="TERM" DRY_RUN=0 ASSUME_YES=0
while [ $# -gt 0 ]; do
    case "$1" in
        -q|--query)  [ $# -ge 2 ] || usage_error "$1 needs an argument"; QUERY="$2"; shift ;;
        --query=*)   QUERY="${1#*=}" ;;
        -s|--signal) [ $# -ge 2 ] || usage_error "$1 needs an argument"; SIGNAL="${2#SIG}"; shift ;;
        --signal=*)  SIGNAL="${1#*=}"; SIGNAL="${SIGNAL#SIG}" ;;
        -n|--dry-run) DRY_RUN=1 ;;
        -y|--yes)    ASSUME_YES=1 ;;
        -h|--help)   usage; exit 0 ;;
        *)           usage_error "unknown argument: $1" ;;
    esac
    shift
done

# Validate early, before any UI: a typo should not cost a selection round.
kill -l "$SIGNAL" >/dev/null 2>&1 || usage_error "unknown signal: $SIGNAL"
command -v fzf >/dev/null 2>&1 || die "fzf is required (brew install fzf)"

# Header line + one process per line. Leave out this script and its own
# subshells (same command line, parent = us), or they'd match QUERY too.
list_processes() {
    ps -A -o pid,ppid,user,%cpu,%mem,command | awk -v me="$$" 'NR == 1 || ($1 != me && $2 != me)'
}

# Snapshot first, pick second: if ps ran while fzf was already running,
# `fzf --filter QUERY` would be in the list and match its own QUERY.
processes="$(list_processes)"

rc=0
if is_interactive; then
    selected="$(printf '%s\n' "$processes" | fzf \
                    --multi --height 80% --layout reverse --border \
                    --header-lines 1 --header "Tab: mark   ?: preview   signal: $SIGNAL" \
                    --prompt 'process> ' --query "$QUERY" \
                    --preview 'ps -ww -o pid,ppid,user,etime,command -p {1}' \
                    --preview-window 'down,5,wrap' \
                    --bind '?:toggle-preview')" || rc=$?
else
    [ -n "$QUERY" ] || usage_error "no terminal: pass -q QUERY to select processes"
    selected="$(printf '%s\n' "$processes" | sed 1d | fzf --filter "$QUERY")" || rc=$?
fi
case "$rc" in
    0)   ;;
    1)   die "no process matches${QUERY:+ '$QUERY'}" ;;
    130) exit 130 ;;
    *)   die "fzf failed (exit $rc)" ;;
esac

pids="$(printf '%s\n' "$selected" | awk '{ print $1 }')"
count="$(printf '%s\n' "$pids" | wc -l | tr -d ' ')"

# Show exactly what will happen, on stderr.
printf '%s\n' "$selected" | sed 's/^/  /' >&2

if [ "$DRY_RUN" = 1 ]; then
    printf '%s: dry run, would send SIG%s to %s process(es)\n' "$PROG" "$SIGNAL" "$count" >&2
    printf '%s\n' "$pids"
    exit 0
fi

if [ "$ASSUME_YES" != 1 ]; then
    is_interactive || die "no terminal to confirm; pass --yes"
    printf 'Send SIG%s to %s process(es)? [y/N] ' "$SIGNAL" "$count" >&2
    read -r reply || reply=""
    case "$reply" in [yY]|[yY][eE][sS]) ;; *) die "cancelled" ;; esac
fi

status=0
for pid in $pids; do
    if kill -s "$SIGNAL" "$pid" 2>/dev/null; then
        printf '%s\n' "$pid"
    else
        printf '%s: could not signal %s (gone, or not yours?)\n' "$PROG" "$pid" >&2
        status=1
    fi
done
exit "$status"
