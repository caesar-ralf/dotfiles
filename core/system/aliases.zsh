# GNU ls with colours: `gls` from Homebrew coreutils on macOS, plain `ls` on
# Linux. (eza, when installed, overrides these in core/zsh/aliases.zsh.)
if (( $+commands[gls] )); then
  _ls=gls
elif ls --version >/dev/null 2>&1; then
  _ls=ls
fi
if [ -n "${_ls:-}" ]; then
  alias ls="$_ls -F --color"
  alias l="$_ls -lAh --color"
  alias ll="$_ls -l --color"
  alias la="$_ls -A --color"
fi
unset _ls
