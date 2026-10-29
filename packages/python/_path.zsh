export PYENV_ROOT="$HOME/.pyenv"
# Put pyenv (and its shims) on PATH directly so the default python resolves
# immediately, without paying for `pyenv init -` on every shell start.
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
[ -d "$PYENV_ROOT/shims" ] && export PATH="$PYENV_ROOT/shims:$PATH"
