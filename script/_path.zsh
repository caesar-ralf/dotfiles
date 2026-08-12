# Put the dotfiles scripts on PATH so `dot`, `bootstrap` and `secrets` are
# runnable from anywhere (previously this pointed at the `dot` file itself,
# which is a file, not a directory, so nothing was actually added).
export PATH="$DOTFILES/script:$PATH"
