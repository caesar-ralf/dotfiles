# GRC colorizes nifty unix tools all over the place
if (( $+commands[grc] )); then
  source "${BREW_PREFIX:-$(brew --prefix)}/etc/grc.zsh"
fi
