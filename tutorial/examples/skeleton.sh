#!/usr/bin/env bash
#
# skeleton -- template for a well-behaved command: copy each FILE to FILE.bak.
# Copy this file, rename it, and replace the body of main().
#
# Usage: skeleton [-n] [-v] [-d DIR] FILE...
#
#   -n, --dry-run   show what would happen, change nothing
#   -v, --verbose   say what is being done (on stderr)
#   -d, --dir DIR   put the copies in DIR instead of next to each FILE
#   -h, --help      show this help
#
# Output: the path of every copy, one per line (stdout), so it can be piped.
# Exit codes: 0 ok, 1 runtime error, 2 usage error.

set -o errexit -o nounset -o pipefail

PROG="${0##*/}"

# The help text IS the header comment above: one source of truth.
usage() { awk 'NR > 2 { if (!/^#/) exit; sub(/^# ?/, ""); print }' "$0"; }

# Humans read stderr, programs read stdout.
die()         { printf '%s: %s\n' "$PROG" "$*" >&2; exit 1; }
usage_error() { printf '%s: %s\nTry "%s --help".\n' "$PROG" "$*" "$PROG" >&2; exit 2; }
log()         { if [ "$VERBOSE" = 1 ]; then printf '%s: %s\n' "$PROG" "$*" >&2; fi; }

# run CMD...: execute, or only print it in dry-run mode.
run() {
    if [ "$DRY_RUN" = 1 ]; then
        printf 'would run:' >&2; printf ' %q' "$@" >&2; printf '\n' >&2
    else
        "$@"
    fi
}

# --- options -----------------------------------------------------------------
DRY_RUN=0
VERBOSE=0
DEST_DIR=""

while [ $# -gt 0 ]; do
    case "$1" in
        -n|--dry-run) DRY_RUN=1 ;;
        -v|--verbose) VERBOSE=1 ;;
        -d|--dir)
            [ $# -ge 2 ] || usage_error "$1 needs an argument"
            DEST_DIR="$2"; shift ;;
        --dir=*)      DEST_DIR="${1#*=}" ;;
        -h|--help)    usage; exit 0 ;;
        --)           shift; break ;;          # everything after -- is a FILE
        -?*)          usage_error "unknown option: $1" ;;
        *)            break ;;                 # first FILE: stop parsing options
    esac
    shift
done

[ $# -ge 1 ] || usage_error "missing FILE"
if [ -n "$DEST_DIR" ] && [ ! -d "$DEST_DIR" ]; then
    usage_error "not a directory: $DEST_DIR"
fi

# --- main --------------------------------------------------------------------
main() {
    local file dest status=0
    for file in "$@"; do
        if [ ! -f "$file" ]; then
            printf '%s: no such file: %s\n' "$PROG" "$file" >&2
            status=1
            continue                            # keep going, fail at the end
        fi
        if [ -n "$DEST_DIR" ]; then
            dest="$DEST_DIR/${file##*/}.bak"
        else
            dest="$file.bak"
        fi
        log "copying $file -> $dest"
        run cp -p -- "$file" "$dest"
        printf '%s\n' "$dest"
    done
    return "$status"
}

main "$@"
