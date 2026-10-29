# Lazy-load rbenv. Shims are already on PATH (see _path.zsh), so the default
# ruby works right away. Full init runs on the first `rbenv` invocation only.
if command -v rbenv >/dev/null; then
  rbenv() {
    unset -f rbenv
    eval "$(command rbenv init - zsh)"
    rbenv "$@"
  }
fi
