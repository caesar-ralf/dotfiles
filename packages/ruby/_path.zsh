export PATH="$HOME/.rbenv/bin:$PATH"
# Put rbenv shims on PATH directly so the default ruby resolves immediately,
# without paying for `rbenv init -` on every shell start (see packages/ruby/init.zsh).
[ -d "$HOME/.rbenv/shims" ] && export PATH="$HOME/.rbenv/shims:$PATH"
