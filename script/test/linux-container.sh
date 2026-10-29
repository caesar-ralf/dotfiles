#!/usr/bin/env bash
# Runs INSIDE the container started by script/test-linux. Prints PASS/FAIL lines
# and exits non-zero if any check failed. Never uses real secrets.
set -u
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null
apt-get install -y -qq zsh git curl jq fzf sudo dbus dbus-x11 gnome-keyring libsecret-tools >/dev/null 2>&1

FAILED=0
pass()  { echo "PASS $*"; }
failt() { echo "FAIL $*"; FAILED=1; }
check() { if eval "$2"; then pass "$1"; else failt "$1"; fi; }

# Repo copy + the links bootstrap would create.
export HOME=/root USER=root SHELL=/usr/bin/zsh
mkdir -p "$HOME/.dotfiles"
cp -a /src/. "$HOME/.dotfiles/"
D="$HOME/.dotfiles"
ln -sfn "$D/core/zsh/zshrc.symlink" "$HOME/.zshrc"
ln -sfn "$D/git/gitconfig.symlink" "$HOME/.gitconfig"
ln -sfn "$D/packages/maven/m2.symlink" "$HOME/.m2"
printf '[user]\n    name = CI\n    email = personal@example.com\n' > "$HOME/.gitconfig.local"

# Fake pass-cli: always logged in; `item view ... --field F` prints "dummy-<field>".
mkdir -p /usr/local/fakebin
cat > /usr/local/fakebin/pass-cli <<'EOF'
#!/bin/sh
echo "$*" >> /tmp/pass-cli.calls
case "$1" in
  info) exit 0 ;;
  item) shift; [ "$1" = view ] || exit 1
        while [ $# -gt 0 ]; do [ "$1" = --field ] && { echo "dummy-$2"; exit 0; }; shift; done; exit 1 ;;
  *) exit 1 ;;
esac
EOF
chmod +x /usr/local/fakebin/pass-cli
export PATH="/usr/local/fakebin:$PATH"
cd "$D" || exit 1

echo "=== shell startup (no Homebrew)"
out="$(zsh -i -c 'echo "OS=$DOTFILES_OS"; whence -w secret profile pbcopy open' 2>&1)"
printf '%s\n' "$out" | sed 's/^/    /'
check "zsh starts without errors" '! printf "%s\n" "$out" | grep -qiE "error|not found|no such|command not"'
check "DOTFILES_OS=linux" 'printf "%s\n" "$out" | grep -q "OS=linux"'
check "pbcopy/open shims on PATH" 'printf "%s\n" "$out" | grep -q "pbcopy: command" && printf "%s\n" "$out" | grep -q "open: command"'

echo "=== profiles (scratch profile from _template)"
check "profile new" 'script/profile new citest >/dev/null 2>&1'
sed -i 's/you@company.example/work@example.com/' profiles/citest/git/gitconfig
echo 'CI_TOKEN=pass://Work/CI/password' >> profiles/citest/example/secrets.refs
echo 'export CI_PROFILE_VAR=on' >> profiles/citest/example/example.zsh
check "profile use" 'script/profile use citest >/dev/null 2>&1'
out="$(zsh -i -c 'echo "var=$CI_PROFILE_VAR email=$(git config user.email) fn=$(whence -w profile-hello)"' 2>&1 | tail -1)"
echo "    $out"
check "profile env, git include and functions active" '[ "$out" = "var=on email=work@example.com fn=profile-hello: function" ]'

echo "=== secrets without cache (no D-Bus)"
check "backend none" '[ "$(bash -c "source security/secrets/lib.sh; secrets_cache_backend")" = none ]'
got="$(security/secrets/bin/secret GITHUB_TOKEN 2>&1)"
check "secret GITHUB_TOKEN (got: $got)" '[ "$got" = dummy-password ]'
check "profile ref visible" 'security/secrets/bin/secret list | grep -q "^CI_TOKEN"'
out="$(security/secrets/bin/with-secrets -- sh -c 'echo "$GITHUB_TOKEN/$CI_TOKEN"')"
check "with-secrets injects global + profile secrets" '[ "$out" = "dummy-password/dummy-password" ]'

echo "=== secrets with libsecret cache (throwaway GNOME Keyring)"
# GNOME Keyring in a container is flaky (it sometimes wants a GUI prompt to
# create its default keyring). Each attempt runs in a fresh D-Bus session and
# exits 0 = pass, 2 = keyring not usable (skip), 1 = keyring OK but our cache failed.
keyring_attempt() {
    dbus-run-session -- bash -c '
      echo -n testpw | gnome-keyring-daemon --unlock --components=secrets >/dev/null 2>&1
      ready=0
      for i in 1 2 3; do
          printf x | secret-tool store --label=warmup service dotfiles-warmup >/dev/null 2>&1
          [ "$(secret-tool lookup service dotfiles-warmup 2>/dev/null)" = x ] && { ready=1; break; }; sleep 1
      done
      secret-tool clear service dotfiles-warmup >/dev/null 2>&1
      [ "$ready" = 1 ] || exit 2
      [ "$(bash -c "source security/secrets/lib.sh; secrets_cache_backend")" = libsecret ] || { echo "    backend is not libsecret"; exit 1; }
      security/secrets/bin/secret forget >/dev/null; : > /tmp/pass-cli.calls
      a="$(security/secrets/bin/secret GITHUB_TOKEN)"; b="$(security/secrets/bin/secret GITHUB_TOKEN)"
      n=$(grep -c "item view" /tmp/pass-cli.calls)
      if [ "$a" != dummy-password ] || [ "$b" != "$a" ] || [ "$n" != 1 ]; then
          # A write right after start-up can still be lost; only count it if the
          # keyring is demonstrably working right now.
          printf y | secret-tool store --label=probe service dotfiles-probe >/dev/null 2>&1
          [ "$(secret-tool lookup service dotfiles-probe 2>/dev/null)" = y ] || exit 2
          echo "    cache miss on 2nd lookup (pass-cli calls=$n)"; exit 1
      fi
      security/secrets/bin/secret forget GITHUB_TOKEN >/dev/null
      [ -z "$(secret-tool lookup service dotfiles name GITHUB_TOKEN 2>/dev/null)" ] || { echo "    forget left the entry"; exit 1; }
      exit 0
    ' 2>/dev/null
}
kr_result=2
for attempt in 1 2 3; do
    keyring_attempt; rc=$?
    [ "$rc" = 0 ] && { kr_result=0; break; }
    [ "$rc" = 1 ] && kr_result=1
done
case "$kr_result" in
    0) pass "keyring cache: 2nd lookup served from keyring, forget removes it" ;;
    2) echo "SKIP keyring not usable in this container (needs a prompter); logic covered on desktops" ;;
    *) failt "keyring cache" ;;
esac
echo "=== profile off"
check "profile off" 'script/profile off >/dev/null 2>&1'
out="$(zsh -i -c 'echo "var=[${CI_PROFILE_VAR:-}] email=$(git config user.email)"' 2>&1 | tail -1)"
echo "    $out"
check "profile fully unloaded" '[ "$out" = "var=[] email=personal@example.com" ]'

echo "=== git hooks + Jira ticket detection (mawk, GNU tools)"
out="$(bash script/test/git-hooks.sh 2>&1)"
echo "$out" | grep -E "^FAIL" | sed "s/^/    /"
check "git hooks" 'echo "$out" | grep -q "ALL HOOK CHECKS PASSED"'

echo "=== bash syntax under GNU tools"
for f in script/bootstrap script/dot script/install script/profile script/lib/common.sh \
         security/secrets/lib.sh security/secrets/bin/secret security/secrets/bin/with-secrets core/platform/install.sh core/platform/linux-bin/* \
         git/bin/git-ticket git/git_global.symlink/hooks/_dispatch git/git_global.symlink/hooks.d/commit-msg; do
    bash -n "$f" || failt "syntax $f"
done
pass "syntax"

echo
[ "$FAILED" = 0 ] && echo "ALL LINUX CHECKS PASSED" || echo "SOME LINUX CHECKS FAILED"
exit "$FAILED"
