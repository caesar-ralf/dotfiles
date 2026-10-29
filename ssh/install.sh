#!/bin/sh
#
# Make ~/.ssh/config include ssh/config (Proton Pass agent + active profile).
# Only adds one Include line at the top; the rest of ~/.ssh/config is yours.

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
SSH_CONFIG="$HOME/.ssh/config"
INCLUDE_LINE="Include $DOTFILES/ssh/config"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
[ -f "$SSH_CONFIG" ] || { touch "$SSH_CONFIG"; chmod 600 "$SSH_CONFIG"; }

if ! grep -qxF "$INCLUDE_LINE" "$SSH_CONFIG"; then
  tmp="$(mktemp)"
  { echo "$INCLUDE_LINE"; echo; cat "$SSH_CONFIG"; } > "$tmp"
  cat "$tmp" > "$SSH_CONFIG"
  rm -f "$tmp"
  echo "  Added '$INCLUDE_LINE' to ~/.ssh/config"
fi

exit 0
