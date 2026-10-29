#!/bin/sh
#
# Homebrew (macOS) / Homebrew on Linux ("Linuxbrew"). Same installer for both.
# On Linux, platform/install.sh provides its apt prerequisites
# (build-essential, procps, curl, file, git).

if ! command -v brew >/dev/null 2>&1 \
   && [ ! -x /opt/homebrew/bin/brew ] && [ ! -x /usr/local/bin/brew ] \
   && [ ! -x /home/linuxbrew/.linuxbrew/bin/brew ]
then
  echo "  Installing Homebrew for you."
  NONINTERACTIVE="${DOTFILES_YES:+1}" \
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

exit 0
