#!/bin/sh
#
# Proton Pass CLI (pass-cli) backs `secret`, `with-secrets` and the SSH agent.
# It is not in Homebrew, so only check for it here.

if ! command -v pass-cli >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/pass-cli" ]; then
  echo "  ! Proton Pass CLI (pass-cli) not found."
  echo "    Install it from https://proton.me/pass/download (CLI section),"
  echo "    then run: secret login"
fi

exit 0
