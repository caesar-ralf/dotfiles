# direnv: load and unload environment variables per directory (via .envrc).
# Drop an `.envrc` in a project, run `direnv allow`, and its env is applied
# whenever you cd in, and removed when you leave. https://direnv.net
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"
