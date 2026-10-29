# shellcheck shell=bash
#
# lib.sh: shared helpers for `secret` and `with-secrets`.
#
# Secrets are NEVER stored by these dotfiles. A feature that needs one declares
# a *reference* to a Proton Pass item in a `secrets.refs` file next to it:
#
#     $DOTFILES/<feature>/secrets.refs
#     ~/.config/dotfiles/profile/<feature>/secrets.refs   (active profile only)
#
# One reference per line (blank lines and lines starting with # are ignored):
#
#     NAME=pass://<vault name>/<item title>/<field>
#
# e.g.  GITHUB_TOKEN=pass://Personal/GitHub Token/password
#
# The item title may contain "/" (everything between the first and the last "/"
# is the title). When the same NAME is declared twice, the active profile wins.
#
# Written for the bash 3.2 that ships with macOS (no mapfile/assoc arrays).

SECRETS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES="${DOTFILES:-$(cd "${SECRETS_LIB_DIR}/.." && pwd -P)}"
DOTFILES_PROFILE_LINK="${DOTFILES_PROFILE_LINK:-$HOME/.config/dotfiles/profile}"

# Every secrets.refs file currently in effect: global ones first, then the
# active profile's, so later (profile) entries override earlier (global) ones.
secrets_ref_files() {
    local f
    for f in "${DOTFILES}"/*/secrets.refs "${DOTFILES_PROFILE_LINK}"/*/secrets.refs; do
        [ -f "$f" ] && printf '%s\n' "$f"
    done
    return 0
}

# Print "NAME<TAB>REFERENCE<TAB>FILE" for every declared reference.
secrets_list() {
    local file line name ref
    while IFS= read -r file; do
        while IFS= read -r line || [ -n "$line" ]; do
            [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
            [[ "$line" == *=* ]] || continue
            name="${line%%=*}"
            name="${name//[[:space:]]/}"
            ref="${line#*=}"
            ref="${ref#"${ref%%[![:space:]]*}"}"   # trim leading whitespace
            ref="${ref%"${ref##*[![:space:]]}"}"   # trim trailing whitespace
            printf '%s\t%s\t%s\n' "$name" "$ref" "$file"
        done < "$file"
    done < <(secrets_ref_files)
}

# Unique NAMEs, in declaration order.
secrets_names() {
    secrets_list | awk -F'\t' '!seen[$1]++ { print $1 }'
}

# The reference for NAME (last declaration wins). Fails if NAME is unknown.
secrets_ref() {
    secrets_list | awk -F'\t' -v n="$1" '$1 == n { r = $2 } END { if (r == "") exit 1; print r }'
}

secrets_have_cli() {
    command -v pass-cli >/dev/null 2>&1
}

# Is there an authenticated Proton Pass session?
secrets_logged_in() {
    secrets_have_cli && pass-cli test >/dev/null 2>&1
}

# Resolve a pass://<vault>/<item title>/<field> reference and print the value.
secrets_resolve() {
    local ref="$1" rest vault item field
    case "$ref" in
        pass://*) ;;
        *) printf 'secret: not a pass:// reference: %s\n' "$ref" >&2; return 2 ;;
    esac
    rest="${ref#pass://}"
    vault="${rest%%/*}"
    rest="${rest#*/}"
    item="${rest%/*}"
    field="${rest##*/}"
    if [ -z "$vault" ] || [ -z "$item" ] || [ -z "$field" ] || [ "$item" = "$rest" ]; then
        printf 'secret: malformed reference (want pass://<vault>/<item>/<field>): %s\n' "$ref" >&2
        return 2
    fi
    if ! secrets_have_cli; then
        printf 'secret: pass-cli (Proton Pass CLI) not found on PATH\n' >&2
        return 127
    fi
    pass-cli item view --vault-name "$vault" --item-title "$item" --field "$field"
}
