#!/bin/sh
#
# Linux (Debian/Ubuntu) prerequisites that Homebrew does not cover: what
# Linuxbrew itself needs, zsh, the clipboard/open helpers used by
# platform/linux-bin, and secret-tool for the secrets cache.
# No-op on macOS and on non-apt distros (prints the list instead).

[ "$(uname -s)" = "Linux" ] || exit 0

PKGS="zsh build-essential procps curl file git lsof xdg-utils libsecret-tools xclip wl-clipboard"

missing=""
for p in $PKGS; do
  dpkg -s "$p" >/dev/null 2>&1 || missing="$missing $p"
done
[ -n "$missing" ] || exit 0

if command -v apt-get >/dev/null 2>&1; then
  echo "  Installing apt packages:$missing"
  # shellcheck disable=SC2086
  sudo apt-get update -qq && sudo apt-get install -y $missing \
    || echo "  ! apt install failed; install manually:$missing"
else
  echo "  ! Not an apt system. Install the equivalents of:$missing"
fi

exit 0
