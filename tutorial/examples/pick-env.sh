#!/usr/bin/env bash
#
# pick-env -- choose from a fixed list: fzf if it's installed, the bash
# `select` menu otherwise, and no prompt at all when the choice is given as an
# argument. Asks before a dangerous choice.
#
# Usage: pick-env [-y] [ENVIRONMENT]
#
#   ENVIRONMENT   dev, staging or prod. Skips the picker (scripts, CI).
#   -y, --yes     don't ask for confirmation
#
# Environment: NO_FZF=1 forces the `select` fallback, to try it out.
# Output: the chosen environment on stdout.
# Exit codes: 0 ok, 1 declined, 2 usage, 130 cancelled.

set -o errexit -o nounset -o pipefail

PROG="${0##*/}"
ENVS=(dev staging prod)

usage()       { awk 'NR > 2 { if (!/^#/) exit; sub(/^# ?/, ""); print }' "$0"; }
usage_error() { printf '%s: %s\nTry "%s --help".\n' "$PROG" "$*" "$PROG" >&2; exit 2; }

# Colour only for humans: stderr is a terminal and NO_COLOR is not set.
if [ -t 2 ] && [ -z "${NO_COLOR:-}" ]; then
    C_WARN="$(printf '\033[0;33m')"; C_RST="$(printf '\033[0m')"
else
    C_WARN=""; C_RST=""
fi

is_interactive() { [ -t 0 ] && [ -t 2 ]; }

# choose PROMPT OPTION...: print the chosen option. The UI goes to the
# terminal/stderr, so this works inside $(...).
choose() {
    local prompt="$1"; shift
    if [ -z "${NO_FZF:-}" ] && command -v fzf >/dev/null 2>&1; then
        printf '%s\n' "$@" | fzf --height 40% --layout reverse --prompt "$prompt> "
        return                                  # fzf's exit code: 0, 1 or 130
    fi
    # bash `select` prints the numbered menu and PS3 on stderr, reads stdin.
    local PS3="$prompt (number, Ctrl-D to cancel): " opt
    select opt in "$@"; do
        if [ -n "$opt" ]; then printf '%s\n' "$opt"; return 0; fi
        printf 'not a valid number: %s\n' "$REPLY" >&2
    done
    echo >&2
    return 130                                  # Ctrl-D ends `select`
}

# confirm QUESTION: 0 = yes. Default is NO, and without a terminal we never
# assume yes: the caller must pass --yes.
confirm() {
    [ "$ASSUME_YES" = 1 ] && return 0
    if ! is_interactive; then
        printf '%s: %s -- no terminal to ask; pass --yes\n' "$PROG" "$1" >&2
        return 1
    fi
    local reply
    printf '%s%s%s [y/N] ' "$C_WARN" "$1" "$C_RST" >&2
    read -r reply || return 1
    case "$reply" in [yY]|[yY][eE][sS]) return 0 ;; *) return 1 ;; esac
}

is_valid() {
    local e
    for e in "${ENVS[@]}"; do [ "$e" = "$1" ] && return 0; done
    return 1
}

ASSUME_YES=0
while [ $# -gt 0 ]; do
    case "$1" in
        -y|--yes)  ASSUME_YES=1 ;;
        -h|--help) usage; exit 0 ;;
        -?*)       usage_error "unknown option: $1" ;;
        *)         break ;;
    esac
    shift
done
[ $# -le 1 ] || usage_error "too many arguments"

env="${1:-}"
if [ -z "$env" ]; then
    # No argument: ask -- but only if a human is there to answer.
    is_interactive || usage_error "no ENVIRONMENT given and no terminal to ask (one of: ${ENVS[*]})"
    rc=0
    env="$(choose environment "${ENVS[@]}")" || rc=$?
    case "$rc" in 0) ;; 130) exit 130 ;; *) exit 1 ;; esac
fi
is_valid "$env" || usage_error "unknown environment '$env' (one of: ${ENVS[*]})"

if [ "$env" = prod ]; then
    confirm "Really use PROD?" || { echo "$PROG: cancelled" >&2; exit 1; }
fi

printf '%s\n' "$env"
