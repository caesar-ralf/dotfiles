#!/bin/sh
#
# fzf-tab (https://github.com/Aloxaf/fzf-tab)
#
# Replaces zsh's default completion selection menu with an fzf picker.
# It is NOT available in Homebrew core, so we clone it ourselves.
#
# The plugin is cloned into ~/.zsh/fzf-tab and sourced by zsh/zshrc.symlink
# (which checks that path). Sourcing must happen AFTER compinit and BEFORE
# zsh-autosuggestions / zsh-syntax-highlighting — the zshrc already handles that.

FZF_TAB_DIR="$HOME/.zsh/fzf-tab"

if [ ! -d "$FZF_TAB_DIR" ]
then
  echo "  Installing fzf-tab for you."
  git clone --depth 1 https://github.com/Aloxaf/fzf-tab "$FZF_TAB_DIR"
else
  echo "  Updating fzf-tab."
  git -C "$FZF_TAB_DIR" pull --ff-only || true
fi

exit 0
