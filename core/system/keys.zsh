(( $+aliases[pubkey] )) && unalias pubkey
# Copy my public SSH key to the clipboard (pbcopy is shimmed on Linux, see
# platform/). Keys usually live in Proton Pass, so prefer what the agent serves.
pubkey() {
  local key
  key="$(ssh-add -L 2>/dev/null | head -n1)"
  [ -n "$key" ] || key="$(cat ~/.ssh/id_ed25519.pub ~/.ssh/id_rsa.pub 2>/dev/null | head -n1)"
  [ -n "$key" ] || { echo "No public key found (ssh-add -L / ~/.ssh/*.pub)." >&2; return 1; }
  printf '%s\n' "$key" | pbcopy && echo "=> Public key copied to clipboard: ${key%% *} …${key: -20}"
}
