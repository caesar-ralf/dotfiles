# Docker CLI completions (written by Docker Desktop). Must be on fpath before
# compinit, which is why this lives in _path.zsh. Docker Desktop may offer to
# append its own snippet (with a second `compinit`) to ~/.zshrc: decline it.
[ -d "$HOME/.docker/completions" ] && fpath=("$HOME/.docker/completions" $fpath)
