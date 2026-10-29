export SDKMAN_DIR="$HOME/.sdkman"

# Add the currently-selected SDK binaries to PATH cheaply (a few symlink
# lookups) instead of running the ~1s sdkman-init.sh scan on every shell start.
if [ -d "$SDKMAN_DIR/candidates" ]; then
  for _sdk_bin in "$SDKMAN_DIR"/candidates/*/current/bin(/N); do
    export PATH="$_sdk_bin:$PATH"
  done
  unset _sdk_bin
fi

# Lazy-load the full SDKMAN machinery (the `sdk` command, auto-env, etc.) on
# first use. Everyday tools (java, gradle, ...) already work via PATH above.
if [ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]; then
  sdk() {
    unset -f sdk
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
    sdk "$@"
  }
fi
