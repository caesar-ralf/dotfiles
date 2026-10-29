# Proton Pass SSH agent: SSH keys live in Proton Pass, never on disk.
#
# The agent socket is wired into ssh via security/ssh/config (included from ~/.ssh/config
# by security/ssh/install.sh). Exporting SSH_AUTH_SOCK as well makes `ssh-add -l` and git
# SSH commit signing (ssh-keygen -Y sign) use the same agent.
#
# The daemon is started in the background on shell start if it is not running.
# It needs a Proton Pass session (`secret login`); without one it quietly does
# nothing. Opt out with `export DOTFILES_SSH_AGENT=system` in ~/.zshenv (it must
# be set before the dotfiles load).

export PROTON_PASS_SSH_SOCK="$HOME/.ssh/proton-pass-agent.sock"
PROTON_PASS_SSH_PID="$HOME/.ssh/proton-pass-agent.pid"

if [ "${DOTFILES_SSH_AGENT:-proton}" = "proton" ] && command -v pass-cli >/dev/null 2>&1; then
  export SSH_AUTH_SOCK="$PROTON_PASS_SSH_SOCK"

  if ! { [ -S "$PROTON_PASS_SSH_SOCK" ] && [ -f "$PROTON_PASS_SSH_PID" ] && kill -0 "$(<"$PROTON_PASS_SSH_PID")" 2>/dev/null; }; then
    ( pass-cli ssh-agent daemon start --socket-path "$PROTON_PASS_SSH_SOCK" >/dev/null 2>&1 & ) 2>/dev/null
  fi
fi

unset PROTON_PASS_SSH_PID

alias ssh-keys='ssh-add -l'                              # keys the agent is serving
alias ssh-agent-status='pass-cli ssh-agent daemon status'
alias ssh-agent-restart='pass-cli ssh-agent daemon stop; pass-cli ssh-agent daemon start --socket-path "$PROTON_PASS_SSH_SOCK"'
