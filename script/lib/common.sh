#!/usr/bin/env bash
#
# common.sh — shared helpers for the scripts in this folder.
#
# Source it from any script:
#     source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
#
# It provides:
#   - Consistent, colourful output helpers (info/success/warn/fail/…)
#   - Section headers and step runners
#   - A cowsay-style `wizard` 🧙 (with happy/neutral/sad faces)
#   - Small utilities (command_exists, is_macos, confirm, …)
#
# Colours are automatically disabled when stdout is not a TTY or when the
# NO_COLOR environment variable is set (https://no-color.org).

# Guard against being sourced twice.
[ -n "${__DOTFILES_COMMON_SOURCED:-}" ] && return 0
__DOTFILES_COMMON_SOURCED=1

# --- Paths -----------------------------------------------------------------
# Resolve the repo root regardless of where a script is invoked from.
DOTFILES_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES_ROOT="$(cd "${DOTFILES_LIB_DIR}/../.." && pwd -P)"
export DOTFILES="${DOTFILES:-$DOTFILES_ROOT}"

# --- Colours ---------------------------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    C_RESET="$(tput sgr0)"
    C_BOLD="$(tput bold)"
    C_DIM="$(tput dim)"
    C_RED="$(tput setaf 1)"
    C_GREEN="$(tput setaf 2)"
    C_YELLOW="$(tput setaf 3)"
    C_BLUE="$(tput setaf 4)"
    C_MAGENTA="$(tput setaf 5)"
    C_CYAN="$(tput setaf 6)"
else
    C_RESET="" C_BOLD="" C_DIM="" C_RED="" C_GREEN="" C_YELLOW="" C_BLUE="" C_MAGENTA="" C_CYAN=""
fi

# --- Output helpers --------------------------------------------------------
# A big, obvious banner for the start of a run.
banner() {
    printf '\n%s%s╭──────────────────────────────────────────────────────────╮%s\n' "$C_BOLD" "$C_MAGENTA" "$C_RESET"
    printf '%s%s│ %-56s │%s\n' "$C_BOLD" "$C_MAGENTA" "$1" "$C_RESET"
    printf '%s%s╰──────────────────────────────────────────────────────────╯%s\n\n' "$C_BOLD" "$C_MAGENTA" "$C_RESET"
}

# A section header to separate phases of a script.
header() {
    printf '\n%s%s==>%s %s%s%s\n' "$C_BOLD" "$C_BLUE" "$C_RESET" "$C_BOLD" "$1" "$C_RESET"
}

info()    { printf '  %s•%s %s\n'   "$C_BLUE"    "$C_RESET" "$1"; }
success() { printf '  %s✔%s %s\n'   "$C_GREEN"   "$C_RESET" "$1"; }
warn()    { printf '  %s!%s %s\n'   "$C_YELLOW"  "$C_RESET" "$1" >&2; }
note()    { printf '  %s%s%s\n'     "$C_DIM"     "$1"       "$C_RESET"; }
user()    { printf '  %s?%s %s\n'   "$C_YELLOW"  "$C_RESET" "$1"; }
fail()    { printf '  %s✖ %s%s\n'   "$C_RED"     "$1"       "$C_RESET" >&2; exit 1; }

# --- Utilities -------------------------------------------------------------
command_exists() { command -v "$1" >/dev/null 2>&1; }
is_macos()       { [ "$(uname -s)" = "Darwin" ]; }
is_linux()       { [ "$(uname -s)" = "Linux" ]; }

# confirm "Question?"  -> returns 0 for yes, 1 for no. Defaults to No.
# Honours DOTFILES_YES=1 (assume yes) for non-interactive runs.
confirm() {
    [ "${DOTFILES_YES:-0}" = "1" ] && return 0
    local reply
    printf '  %s?%s %s %s[y/N]%s ' "$C_YELLOW" "$C_RESET" "$1" "$C_DIM" "$C_RESET"
    read -r reply
    case "$reply" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

# Run a command as a named step, showing a spinner-free status line.
# Usage: step "Description" cmd arg1 arg2 ...
step() {
    local desc="$1"; shift
    info "$desc"
    if "$@"; then
        return 0
    else
        fail "$desc failed"
    fi
}

# --- The wizard 🧙 ----------------------------------------------------------
# A little ASCII wizard casting a spell, speaking your message next to the
# sparkles. Different colours for the hat, body, spell and text.
#
#   wizard "Hello there!"            # neutral face + fading spell
#   wizard --happy "It worked!"      # cheerful face + sparkles
#   wizard --sad  "It broke."        # gloomy face + rain
#
# Long messages wrap and line up under the first line. Honours NO_COLOR.
wizard() {
    local mood="neutral"
    case "${1:-}" in
        --happy|-h) mood="happy"; shift ;;
        --sad|-s)   mood="sad";   shift ;;
        --neutral)  mood="neutral"; shift ;;
    esac

    local msg="$*"
    [ -z "$msg" ] && msg="..."

    # Word-wrap the message; the first line sits next to the spell, the rest
    # are indented to line up underneath it.
    local -a lines=()
    local line
    while IFS= read -r line; do
        lines+=("$line")
    done < <(printf '%s\n' "$msg" | fold -s -w 50 | sed 's/[[:space:]]*$//')

    # Mood decides the face, the spell being cast, and the text colour:
    # green when it worked, red when it failed, normal colour when neutral.
    local face_inner spell spell_color text_color
    case "$mood" in
        happy) face_inner='(   ͡● ᴗ●)'; spell='✨✨✨'; spell_color="$C_YELLOW"; text_color="$C_GREEN" ;;
        sad)   face_inner='(   ͡●︵●)'; spell='💧💧💧'; spell_color="$C_BLUE";   text_color="$C_RED" ;;
        *)     face_inner='(   ͡● ｰ●)'; spell='· · ·'; spell_color="$C_CYAN";   text_color="" ;;
    esac

    local hat="$C_MAGENTA" body="$C_CYAN" text="$text_color" R="$C_RESET"

    echo
    # Pointy hat.
    printf '  %s     </  \%s\n'     "$hat" "$R"
    printf '  %s   　/　　＼%s\n'     "$hat" "$R"
    printf "  %s    / , =＝=\%s\n" "$hat" "$R"
    # Face: the ＜__ and _＞ corners are purple (hat), the face itself cyan.
    printf '  %s＜__%s%s%s_＞%s\n'     "$hat" "$body" "$face_inner" "$hat" "$R"
    # Arms casting the spell, with the first line of the message beside it.
    printf '  %s     ⊂　　  つ━━%s%s%s %s%s%s\n' \
        "$body" "$spell_color" "$spell" "$R" "$text" "${lines[0]}" "$R"
    # Legs — printed right after the arms so the body never wobbles, no matter
    # how long the message is.
    printf '  %s     しーーＪ%s\n'   "$body" "$R"
    # Any remaining message lines flow below the wizard, aligned under the first.
    local i
    for (( i = 1; i < ${#lines[@]}; i++ )); do
        printf '  %*s%s%s%s\n' 27 '' "$text" "${lines[i]}" "$R"
    done
    echo
}

# Print a mood-aware farewell based on an exit code. Intended for an EXIT trap:
#     trap 'wizard_farewell $?' EXIT
wizard_farewell() {
    local code=${1:-0}
    if [ "$code" -eq 0 ]; then
        wizard --happy "All done! Your setup is ready. May your builds be green and your prompts glorious."
    else
        wizard --sad "Something went wrong (exit $code). Scroll up for the details, then try again."
    fi
}
