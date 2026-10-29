# GRC colorizes nifty unix tools all over the place.
# Homebrew installs grc.zsh under its prefix; apt puts it in /etc.
if (( $+commands[grc] )); then
  for _grc in "$BREW_PREFIX/etc/grc.zsh" /etc/grc.zsh; do
    [ -f "$_grc" ] && { source "$_grc"; break; }
  done
  unset _grc
fi
