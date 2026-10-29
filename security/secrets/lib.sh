# shellcheck shell=bash
#
# lib.sh: shared helpers for `secret` and `with-secrets`.
#
# SOURCE OF TRUTH: Proton Pass. These dotfiles never store a secret in git or
# in a profile. A feature that needs one declares a *reference* in a
# `secrets.refs` file next to it:
#
#     $DOTFILES/<feature>/secrets.refs              (git/, packages/maven/, ...)
#     ~/.config/dotfiles/profile/<feature>/secrets.refs   (active profile only)
#
# One reference per line (blank lines and lines starting with # are ignored):
#
#     NAME=pass://<vault name>/<item title>/<field>       # default cache TTL
#     NAME:12h=pass://<vault name>/<item title>/<field>   # custom TTL (s/m/h/d)
#     NAME:0=pass://...                                   # never cache
#     NAME:forever=pass://...                             # cache until refreshed
#
# The item title may contain "/" (everything between the first and the last "/"
# is the title). When the same NAME is declared twice, the active profile wins.
#
# CACHE: values fetched from Proton Pass are cached in the OS secret store (macOS
# Keychain, or the Linux desktop keyring via secret-tool; see "Cache" below)
# as generic passwords named "dotfiles:<NAME>". The item comment holds
# "<fetched-epoch> <hash of the reference>", so changing a reference
# invalidates its cache. Default TTL: $DOTFILES_SECRET_TTL (7d). Multi-line
# values are never cached. Values reach `security` through stdin (`security -i`),
# never as process arguments.
#
# Written for the bash 3.2 that ships with macOS (no mapfile/assoc arrays).

SECRETS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES="${DOTFILES:-$(cd "${SECRETS_LIB_DIR}/../.." && pwd -P)}"
DOTFILES_PROFILE_LINK="${DOTFILES_PROFILE_LINK:-$HOME/.config/dotfiles/profile}"
SECRETS_DEFAULT_TTL="${DOTFILES_SECRET_TTL:-7d}"
SECRETS_KC_PREFIX="dotfiles:"

secrets_err() { printf '%s\n' "$*" >&2; }

# --- References ------------------------------------------------------------

# Every secrets.refs file currently in effect: global ones first, then the
# active profile's, so later (profile) entries override earlier (global) ones.
# Features are top-level (git/) or one level inside a category (packages/maven/);
# profiles/ is skipped (only the ACTIVE profile counts, via its link).
secrets_ref_files() {
    local f
    for f in "${DOTFILES}"/*/secrets.refs "${DOTFILES}"/*/*/secrets.refs "${DOTFILES_PROFILE_LINK}"/*/secrets.refs; do
        case "$f" in "${DOTFILES}"/profiles/*) continue ;; esac
        [ -f "$f" ] && printf '%s\n' "$f"
    done
    return 0
}

# Print "NAME<TAB>REFERENCE<TAB>TTL<TAB>FILE" for every declared reference.
secrets_list() {
    local file line lhs name ttl ref
    while IFS= read -r file; do
        while IFS= read -r line || [ -n "$line" ]; do
            [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
            [[ "$line" == *=* ]] || continue
            lhs="${line%%=*}"
            lhs="${lhs//[[:space:]]/}"
            name="${lhs%%:*}"
            ttl=""
            [[ "$lhs" == *:* ]] && ttl="${lhs#*:}"
            [ -n "$ttl" ] || ttl="$SECRETS_DEFAULT_TTL"
            ref="${line#*=}"
            ref="${ref#"${ref%%[![:space:]]*}"}"   # trim leading whitespace
            ref="${ref%"${ref##*[![:space:]]}"}"   # trim trailing whitespace
            printf '%s\t%s\t%s\t%s\n' "$name" "$ref" "$ttl" "$file"
        done < "$file"
    done < <(secrets_ref_files)
}

# Unique NAMEs, in declaration order.
secrets_names() {
    secrets_list | awk -F'\t' '!seen[$1]++ { print $1 }'
}

# "REFERENCE<TAB>TTL<TAB>FILE" for NAME (last declaration wins). Fails if unknown.
secrets_entry() {
    secrets_list | awk -F'\t' -v n="$1" '$1 == n { r = $2 "\t" $3 "\t" $4 } END { if (r == "") exit 1; print r }'
}

# TTL string -> seconds. 0 = never cache, -1 = forever. Invalid -> default.
secrets_ttl_seconds() {
    local ttl="$1" num
    case "$ttl" in
        0|never|no)      echo 0; return ;;
        forever|inf)     echo -1; return ;;
    esac
    num="${ttl%[smhd]}"
    if ! [[ "$num" =~ ^[0-9]+$ ]]; then
        secrets_err "secret: invalid TTL '$ttl', using $SECRETS_DEFAULT_TTL"
        [ "$ttl" = "$SECRETS_DEFAULT_TTL" ] && { echo 604800; return; }
        secrets_ttl_seconds "$SECRETS_DEFAULT_TTL"
        return
    fi
    case "$ttl" in
        *m) echo $(( num * 60 )) ;;
        *h) echo $(( num * 3600 )) ;;
        *d) echo $(( num * 86400 )) ;;
        *)  echo "$num" ;;
    esac
}

# --- Proton Pass -----------------------------------------------------------

secrets_have_cli() {
    command -v pass-cli >/dev/null 2>&1
}

# Is there an authenticated Proton Pass session?
secrets_logged_in() {
    secrets_have_cli && pass-cli info >/dev/null 2>&1
}

# Split pass://<vault>/<item title>/<field> into SECRET_VAULT/ITEM/FIELD.
secrets_parse_ref() {
    local ref="$1" rest
    case "$ref" in
        pass://*) ;;
        *) secrets_err "secret: not a pass:// reference: $ref"; return 2 ;;
    esac
    rest="${ref#pass://}"
    SECRET_VAULT="${rest%%/*}"
    rest="${rest#*/}"
    SECRET_ITEM="${rest%/*}"
    SECRET_FIELD="${rest##*/}"
    if [ -z "$SECRET_VAULT" ] || [ -z "$SECRET_ITEM" ] || [ -z "$SECRET_FIELD" ] || [ "$SECRET_ITEM" = "$rest" ]; then
        secrets_err "secret: malformed reference (want pass://<vault>/<item>/<field>): $ref"
        return 2
    fi
}

# Fetch a reference from Proton Pass (no cache) and print the value.
secrets_resolve() {
    local ref="$1" value
    secrets_parse_ref "$ref" || return $?
    if ! secrets_have_cli; then
        secrets_err "secret: pass-cli (Proton Pass CLI) not found on PATH"
        return 127
    fi
    if ! value="$(pass-cli item view --vault-name "$SECRET_VAULT" --item-title "$SECRET_ITEM" --field "$SECRET_FIELD" 2>/dev/null)" || [ -z "$value" ]; then
        secrets_err "secret: could not fetch $ref from Proton Pass (logged in? try: secret login)"
        return 1
    fi
    printf '%s\n' "$value"
}

# --- Cache (OS secret store) -----------------------------------------------
#
# Backends, picked automatically (override: DOTFILES_SECRET_CACHE=keychain|libsecret|none):
#   keychain   macOS login Keychain via `security`. Items: service "dotfiles:<NAME>",
#              comment "<epoch> <hash(ref)>". Values go in through `security -i` (stdin).
#   libsecret  Linux desktop keyring (GNOME Keyring/KWallet) via `secret-tool`
#              (apt install libsecret-tools). Attributes: service=dotfiles name=<NAME>
#              fetched=<epoch> refhash=<hash>. Values go in on stdin.
#   none       no cache (headless Linux without a keyring); every lookup hits Proton Pass.

secrets_cache_backend() {
    if [ -z "${SECRETS_BACKEND:-}" ]; then
        case "${DOTFILES_SECRET_CACHE:-auto}" in
            keychain|libsecret|none) SECRETS_BACKEND="$DOTFILES_SECRET_CACHE" ;;
            *)
                if command -v security >/dev/null 2>&1 && [ "$(uname -s)" = "Darwin" ]; then
                    SECRETS_BACKEND=keychain
                elif command -v secret-tool >/dev/null 2>&1 && [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
                    SECRETS_BACKEND=libsecret
                else
                    SECRETS_BACKEND=none
                fi
                ;;
        esac
    fi
    printf '%s\n' "$SECRETS_BACKEND"
}

secrets_hash() {
    if command -v shasum >/dev/null 2>&1; then
        printf '%s' "$1" | shasum | cut -c1-16
    else
        printf '%s' "$1" | sha1sum | cut -c1-16
    fi
}

# secret-tool can block on a GUI unlock prompt (e.g. a locked keyring over SSH).
# The cache is best effort, so never let it hang a command.
_secret_tool() {
    if command -v timeout >/dev/null 2>&1; then
        timeout "${DOTFILES_SECRET_TOOL_TIMEOUT:-5}" secret-tool "$@"
    else
        secret-tool "$@"
    fi
}

# Read the cache entry for NAME into CACHE_STAMP, CACHE_HASH (and CACHE_VALUE
# when the 2nd arg is "value"). Fails when there is no entry.
secrets_cache_read() {
    local name="$1" want="${2:-}" meta comment line
    CACHE_STAMP="" CACHE_HASH="" CACHE_VALUE=""
    case "$(secrets_cache_backend)" in
        keychain)
            meta="$(security find-generic-password -a "$USER" -s "${SECRETS_KC_PREFIX}${name}" 2>/dev/null)" || return 1
            comment="$(printf '%s\n' "$meta" | sed -n 's/^ *"icmt"<blob>="\(.*\)"$/\1/p')"
            CACHE_STAMP="${comment%% *}"
            CACHE_HASH="${comment#* }"
            if [ "$want" = "value" ]; then
                CACHE_VALUE="$(security find-generic-password -a "$USER" -s "${SECRETS_KC_PREFIX}${name}" -w 2>/dev/null)" || return 1
            fi
            ;;
        libsecret)
            # `search` prints the secret on stdout and the attributes on STDERR,
            # so capture both (in memory only).
            meta="$(_secret_tool search service dotfiles name "$name" 2>&1)" || return 1
            while IFS= read -r line; do
                case "$line" in
                    "attribute.fetched = "*) CACHE_STAMP="${line#attribute.fetched = }" ;;
                    "attribute.refhash = "*) CACHE_HASH="${line#attribute.refhash = }" ;;
                    "secret = "*)            [ "$want" = "value" ] && CACHE_VALUE="${line#secret = }" ;;
                esac
            done <<< "$meta"
            ;;
        *) return 1 ;;
    esac
    [[ "$CACHE_STAMP" =~ ^[0-9]+$ ]]
}

# Print the cached value of NAME if it is fresh for REF and TTL (seconds).
secrets_cache_get() {
    local name="$1" ref="$2" ttl="$3"
    [ "$ttl" != 0 ] || return 1
    secrets_cache_read "$name" value || return 1
    [ "$CACHE_HASH" = "$(secrets_hash "$ref")" ] || return 1
    if [ "$ttl" -gt 0 ] && [ $(( $(date +%s) - CACHE_STAMP )) -ge "$ttl" ]; then
        return 1
    fi
    [ -n "$CACHE_VALUE" ] && printf '%s\n' "$CACHE_VALUE"
}

# Cache VALUE for NAME (fetched now, for REF). Silently skips what it can't cache.
secrets_cache_put() {
    local name="$1" ref="$2" value="$3" esc now hash
    case "$value" in *$'\n'*) return 0 ;; esac
    now="$(date +%s)"
    hash="$(secrets_hash "$ref")"
    case "$(secrets_cache_backend)" in
        keychain)
            esc="$(printf '%s' "$value" | sed 's/\\/\\\\/g; s/"/\\"/g')"
            secrets_cache_forget "$name"
            printf 'add-generic-password -a "%s" -s "%s" -l "%s" -j "%s %s" -w "%s"\n' \
                "$USER" "${SECRETS_KC_PREFIX}${name}" "dotfiles secret ${name} (cache of Proton Pass)" \
                "$now" "$hash" "$esc" \
                | security -i >/dev/null 2>&1 || true
            ;;
        libsecret)
            secrets_cache_forget "$name"
            printf '%s' "$value" | _secret_tool store --label="dotfiles secret ${name} (cache of Proton Pass)" \
                service dotfiles name "$name" fetched "$now" refhash "$hash" >/dev/null 2>&1 || true
            ;;
    esac
    return 0
}

secrets_cache_forget() {
    case "$(secrets_cache_backend)" in
        keychain)  security delete-generic-password -a "$USER" -s "${SECRETS_KC_PREFIX}$1" >/dev/null 2>&1 ;;
        libsecret) _secret_tool clear service dotfiles name "$1" >/dev/null 2>&1 ;;
    esac
    return 0
}

# Age of the cached value in seconds, or empty when nothing is cached.
secrets_cache_age() {
    secrets_cache_read "$1" || return 0
    echo $(( $(date +%s) - CACHE_STAMP ))
}

# --- High level ------------------------------------------------------------

# Print the value of NAME: OS cache when fresh, else Proton Pass (and
# re-cache). Pass --refresh as 2nd arg to skip the cache.
secrets_get() {
    local name="$1" refresh="${2:-}" entry ref ttl secs value
    entry="$(secrets_entry "$name")" || { secrets_err "secret: no reference named $name (see: secret list)"; return 1; }
    ref="$(printf '%s' "$entry" | cut -f1)"
    ttl="$(printf '%s' "$entry" | cut -f2)"
    secs="$(secrets_ttl_seconds "$ttl")"
    if [ "$refresh" != "--refresh" ] && value="$(secrets_cache_get "$name" "$ref" "$secs")" && [ -n "$value" ]; then
        printf '%s\n' "$value"
        return 0
    fi
    value="$(secrets_resolve "$ref")" || return $?
    [ "$secs" != 0 ] && secrets_cache_put "$name" "$ref" "$value"
    printf '%s\n' "$value"
}

# Human-friendly duration.
secrets_human_age() {
    local s="$1"
    if   [ "$s" -lt 3600 ];  then echo "$(( s / 60 ))m"
    elif [ "$s" -lt 86400 ]; then echo "$(( s / 3600 ))h"
    else echo "$(( s / 86400 ))d"
    fi
}
