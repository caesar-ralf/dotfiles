# Cross-platform glue. Sourced first (as a _path.zsh) so everything after it can
# rely on DOTFILES_OS and on macOS-style commands existing everywhere.
case "$(uname -s)" in
  Darwin) export DOTFILES_OS=macos ;;
  Linux)  export DOTFILES_OS=linux ;;
  *)      export DOTFILES_OS=other ;;
esac

# On Linux, provide pbcopy / pbpaste / open shims (see core/platform/linux-bin/), so
# aliases, fzf bindings and scripts can use the macOS names on both systems.
[ "$DOTFILES_OS" = linux ] && export PATH="$PATH:$DOTFILES/core/platform/linux-bin"
