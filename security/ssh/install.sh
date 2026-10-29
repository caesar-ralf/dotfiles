#!/bin/sh
#
# Make ~/.ssh/config include security/ssh/config (Proton Pass agent + active profile).
# Only adds one Include line at the top; the rest of ~/.ssh/config is yours.

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
SSH_CONFIG="$HOME/.ssh/config"
INCLUDE_LINE="Include $DOTFILES/security/ssh/config"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
[ -f "$SSH_CONFIG" ] || { touch "$SSH_CONFIG"; chmod 600 "$SSH_CONFIG"; }

# Drop the Include line from before the repo was reorganised (ssh/ -> security/ssh/).
OLD_INCLUDE_LINE="Include $DOTFILES/ssh/config"
if grep -qxF "$OLD_INCLUDE_LINE" "$SSH_CONFIG"; then
  tmp="$(mktemp)"
  grep -vxF "$OLD_INCLUDE_LINE" "$SSH_CONFIG" > "$tmp"
  cat "$tmp" > "$SSH_CONFIG"
  rm -f "$tmp"
fi

if ! grep -qxF "$INCLUDE_LINE" "$SSH_CONFIG"; then
  tmp="$(mktemp)"
  { echo "$INCLUDE_LINE"; echo; cat "$SSH_CONFIG"; } > "$tmp"
  cat "$tmp" > "$SSH_CONFIG"
  rm -f "$tmp"
  echo "  Added '$INCLUDE_LINE' to ~/.ssh/config"
fi

exit 0
