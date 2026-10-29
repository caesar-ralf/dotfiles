# Lazy-load pyenv. Shims are already on PATH (see _path.zsh), so the default
# python works right away. The full init (needed for `pyenv shell`, rehash,
# virtualenv, completions) runs on the first `pyenv` invocation only.
if command -v pyenv >/dev/null; then
  pyenv() {
    unset -f pyenv
    eval "$(command pyenv init - zsh)"
    # eval "$(command pyenv virtualenv-init - zsh)"
    pyenv "$@"
  }
fi
