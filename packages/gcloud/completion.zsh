# gcloud completions (its internal compinit call is skipped, see core/zsh/zshrc.symlink).
[ -n "${GCLOUD_SDK_DIR:-}" ] && [ -f "$GCLOUD_SDK_DIR/completion.zsh.inc" ] && source "$GCLOUD_SDK_DIR/completion.zsh.inc"
