export EDITOR='vim'
export GITHUB_USER='caesar-ralf'

# Syntax-highlighted man pages via bat (falls back to default pager if absent).
if command -v bat >/dev/null 2>&1; then
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    export MANROFFOPT='-c'
fi

# --- Secrets ---------------------------------------------------------------
# NEVER hard-code secrets in this file: it is committed to git.
#
# Two supported ways to provide secrets (both git-ignored):
#
#   1. macOS Keychain (recommended). Store once, e.g. copy the value from
#      Proton Pass and run:
#          secret-set GITHUB_TOKEN
#      It is then loaded automatically on every shell start (see below).
#
#   2. A local file: system/env.local.zsh (git-ignored, auto-sourced).
#      Copy system/env.local.zsh.example to get started.
#
# `secret NAME`      -> prints a secret from the login Keychain (empty if unset)
# `secret-set NAME`  -> stores/updates a secret in the login Keychain (no echo)
secret() { security find-generic-password -a "$USER" -s "$1" -w 2>/dev/null; }
secret-set() { security add-generic-password -a "$USER" -s "$1" -U -w; }

# Load secrets from the Keychain when present. Nothing is exported if the
# Keychain entry does not exist, so this is safe on a fresh machine.
GITHUB_TOKEN="$(secret GITHUB_TOKEN)"
[ -n "$GITHUB_TOKEN" ] && export GITHUB_TOKEN

# Maven / Artifactory credentials are referenced by ~/.m2/settings.xml via
# ${env.ARTIFACTORY_USER} / ${env.ARTIFACTORY_TOKEN}.
ARTIFACTORY_USER="cfranzho"
ARTIFACTORY_TOKEN="$(secret ARTIFACTORY_TOKEN)"
[ -n "$ARTIFACTORY_USER" ] && export ARTIFACTORY_USER
[ -n "$ARTIFACTORY_TOKEN" ] && export ARTIFACTORY_TOKEN
