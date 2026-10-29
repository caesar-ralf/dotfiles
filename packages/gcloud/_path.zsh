# Google Cloud SDK: find the install (Homebrew cask on macOS; apt, snap or
# tarball locations on Linux) and put its bin/ on PATH. Completions are loaded
# after compinit by completion.zsh.
for _gcloud in "$BREW_PREFIX/Caskroom/google-cloud-sdk/latest/google-cloud-sdk" \
               /usr/lib/google-cloud-sdk /usr/share/google-cloud-sdk /snap/google-cloud-cli/current \
               "$HOME/google-cloud-sdk"; do
  if [ -f "$_gcloud/path.zsh.inc" ]; then
    export GCLOUD_SDK_DIR="$_gcloud"
    source "$_gcloud/path.zsh.inc"
    break
  fi
done
unset _gcloud
