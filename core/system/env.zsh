export EDITOR='vim'
export GITHUB_USER='caesar-ralf'

# Syntax-highlighted man pages via bat (falls back to default pager if absent).
if command -v bat >/dev/null 2>&1; then
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    export MANROFFOPT='-c'
fi

# Secrets are NOT loaded here (this file is committed). They are fetched from
# Proton Pass on demand: `secret NAME`, or `with-secrets -- <cmd>` to inject
# them into a single command. See security/secrets/lib.sh and the README.
#
# Machine-local, git-ignored overrides: core/system/env.local.zsh (auto-sourced).
