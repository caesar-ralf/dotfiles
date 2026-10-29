# AGENTS.md

Context for AI agents (and humans) changing this repo. Read this first; the
[README](README.md) has user-facing documentation.

## What this is

Personal dotfiles (zsh, git, Homebrew, CLI tools) for one user, kept in
`~/.dotfiles`. **macOS is the primary platform; Ubuntu/Debian Linux must keep
working too** (verified by `script/test-linux`). **The repo is public.** Two
hard rules follow from that:

1. **Never commit secrets.** No tokens, passwords, private keys, or JWTs.
   Not in examples, not in comments, not in tests.
2. **Never commit company-specific details** (work email, internal hostnames,
   registry URLs, client IDs, ticket prefixes). They belong in a profile under
   `profiles/<name>/`, which is a separate private repo and git-ignored here.
   Only `profiles/README.md` and `profiles/_template/` are tracked.

Before finishing any change, run the [leak check](#checks).

## Architecture in one screen

- **Organised by feature, not by layer.** Each top-level folder is one feature
  and contains all its pieces. A user should be able to delete a feature by
  deleting one folder. Don't put feature-specific code into shared files
  (`zsh/zshrc.symlink`, `script/*`) if a file inside the feature folder can do
  the job.
- **File conventions** (auto-discovered, no registration needed):

  | File                                              | Picked up by                               | When                     |
  |---------------------------------------------------|--------------------------------------------|--------------------------|
  | `<feature>/_path.zsh`                             | `zsh/zshrc.symlink`                        | shell start, pass 1      |
  | `<feature>/*.zsh`                                 | `zsh/zshrc.symlink`                        | shell start, pass 2      |
  | `<feature>/completion.zsh`                        | `zsh/zshrc.symlink`                        | after `compinit`         |
  | `<feature>/install.sh`                            | `script/install` (via `dot`)               | install/update           |
  | `<feature>/secrets.refs`                          | `secrets/lib.sh`                           | `secret`, `with-secrets` |
  | `<feature>/*.symlink`                             | `script/bootstrap`                         | linked to `~/.<name>`    |
  | `functions/<cmd>`                                 | `zsh/config.zsh`                           | autoloaded zsh function  |
  | `profiles/<p>/<feature>/functions/<cmd>`          | `zsh/zshrc.symlink`                        | autoloaded while active  |
  | `profiles/<p>/<feature>/{activate,deactivate}.sh` | `script/profile`                           | `profile use` / `off`    |
  | `profiles/<p>/<feature>/Brewfile`                 | `script/install`                           | while active             |
  | `profiles/<p>/git/gitconfig`                      | `git/gitconfig.symlink` `[include]` (last) | always (missing = no-op) |
  | `profiles/<p>/ssh/config`                         | `ssh/config` `Include`                     | always (missing = no-op) |

- **Active profile** = symlink `~/.config/dotfiles/profile -> profiles/<name>`
  (`$DOTFILES_PROFILE_LINK`). Everything resolves profile files through this
  path. `active_profile` in `script/lib/common.sh` returns the name.
- **Shell loading**: `zsh/zshrc.symlink` globs `$DOTFILES/*/*.zsh` and then
  `$DOTFILES_PROFILE_LINK/*/*.zsh(N)`. Keep globs **depth-limited**: never use
  `**` from the repo root, because `m2.symlink/repository/` holds over 16k
  Maven cache directories. Likewise, every `find` must prune
  `m2.symlink/repository`, and `profiles/` too (only the active profile counts).
- **Secrets** (`secrets/`):
  - `secrets.refs` lines look like `NAME[:ttl]=pass://<vault>/<item title>/<field>`.
  - `secrets/lib.sh` parses refs, resolves them via `pass-cli item view
    --vault-name --item-title --field`, and caches values in the macOS login
    Keychain as `dotfiles:<NAME>`. The item comment holds `<epoch> <hash(ref)>`.
    Default TTL is `$DOTFILES_SECRET_TTL` (7d).
  - `secrets/bin/secret` is the user CLI (`list/status/scan/add/new/refresh/forget`).
  - `secrets/bin/with-secrets` injects values into one child process. Secrets
    are **never** exported into the interactive shell at startup; keep it
    that way (it's slow and leaks them into every child process).
  - Values must never appear in process arguments. Write to the Keychain
    through `security -i` on stdin, and to `pass-cli` through
    `--from-template -` on stdin.
  - Never print secret values in logs, tests, or tool output. When verifying,
    print only lengths (`${#value}`).
- **SSH**: the Proton Pass SSH agent (`ssh/agent.zsh`) at
  `~/.ssh/proton-pass-agent.sock`. `ssh/install.sh` adds one `Include` line
  to `~/.ssh/config`; the rest of that file belongs to the user.
- **Platforms** (`platform/`):
  - `platform/_path.zsh` sets `DOTFILES_OS=macos|linux` and, on Linux, puts
    `platform/linux-bin/` (`pbcopy`, `pbpaste`, `open` shims) on PATH. Code
    can therefore use the macOS command names everywhere.
  - `platform/install.sh` apt-installs Linux prerequisites.
  - Homebrew is the package manager on both systems (Linuxbrew on Linux).
    `load_brew` in `script/lib/common.sh` and the top of `zsh/zshrc.symlink`
    find it in `/opt/homebrew`, `/usr/local`, or `/home/linuxbrew`.
    `$BREW_PREFIX` is **empty** when Homebrew is absent, so guard every use.
  - Casks are macOS-only (`if OS.mac?` in the Brewfile).
  - Secret cache backends: `keychain` (macOS `security`), `libsecret`
    (Linux `secret-tool`, needs a D-Bus session), or `none`. Selection is in
    `secrets_cache_backend`.
- **Git**: `git/gitconfig.symlink` includes `~/.gitconfig.local` first
  (machine/personal, git-ignored) and the profile's `git/gitconfig` last.

## Repo map

```
script/      bootstrap (fresh machine), dot (update), install (brew + installers), profile, test-linux; lib/common.sh = output helpers, confirm, active_profile, is_macos/is_linux, load_brew; test/linux-container.sh
platform/    _path.zsh (DOTFILES_OS, Linux shims on PATH), linux-bin/{pbcopy,pbpaste,open}, install.sh (apt prerequisites)
secrets/     lib.sh, bin/secret, bin/with-secrets, install.sh (checks pass-cli)
ssh/         agent.zsh, config, install.sh
git/         gitconfig.symlink, gitconfig.local.symlink(.example), git_global.symlink/hooks/commit-msg, aliases.zsh, secrets.refs
zsh/         zshrc.symlink (loader), config.zsh, aliases.zsh, completion.zsh, fpath.zsh, window.zsh
system/      env.zsh, aliases.zsh, grc.zsh, keys.zsh, env.local.zsh(.example, git-ignored)
m2.symlink/  ~/.m2: maven.zsh (with-secrets wrappers), settings.xml.example; repository/ + settings.xml* git-ignored
profiles/    README.md, _template/ (tracked); <name>/ (private repos, ignored)
functions/   generic autoloaded commands
Brewfile     global packages, grouped with one-line comments
```

## Coding conventions

- **Bash scripts** (`script/*`, `secrets/*`, hooks): `#!/usr/bin/env bash`.
  They must run on **macOS bash 3.2 with BSD tools AND Linux bash 5 with GNU
  tools**:
  - No `mapfile`, no associative arrays, no `${var,,}`.
  - `sed -i.bak … && rm *.bak` (never `sed -i ''` or bare `sed -i`).
  - No `readlink -f`, `stat -f/-c`, `date -v/-d`, `grep -P`, or bsdtar-only
    globs.
  - `shasum` may be missing on Linux (fall back to `sha1sum`).
  - Use `set -o errexit -o pipefail` where failure should stop the script.
  - Source `script/lib/common.sh` for `header/info/success/warn/note/fail/confirm`,
    `is_macos/is_linux`, and `load_brew`.
- **OS-specific code**: prefer one portable implementation. Otherwise branch
  on `$DOTFILES_OS` (zsh) or `is_macos`/`is_linux` (bash) inside the feature.
  Put a macOS command's Linux equivalent in `platform/linux-bin/` instead of
  sprinkling `if`s.
- **zsh files** run in the user's interactive shell on every start. Keep them
  fast (no network calls, no `brew --prefix` in loops) and guarded (`command -v
  tool >/dev/null 2>&1 && ...`). Use `(N)` glob qualifiers for globs that may
  match nothing.
- **Installers** (`install.sh`) must be idempotent and must not fail the
  whole run when a tool is missing (`exit 0`).
- **Comments** explain *why*, for a future reader. Every Brewfile line has a
  one-line comment.
- Prefer bash. A small Go tool is acceptable if bash gets genuinely complex
  (the owner is fine with that), but then it needs a build/install step in its
  feature's `install.sh`.
- Update the README (and this file, if architecture changes) in the same
  change.

## Common tasks

- **Add a tool:** add a line to `Brewfile` (or a feature `Brewfile` in a
  profile), plus a `<tool>/` folder for its shell config if needed.
- **Add a feature that needs a secret:** create `<feature>/secrets.refs` with
  `NAME=pass://...` (or have the user run `secret add NAME --feature <feature>`).
  Consume it via `with-secrets -- cmd`, or a wrapper function like
  `m2.symlink/maven.zsh`.
- **Add company-specific config:** put it in the active profile
  (`~/.config/dotfiles/profile/<feature>/`), which is a separate repo. Commit
  there, not here.
- **Add a profile hook:** `profiles/<p>/<feature>/activate.sh` and
  `deactivate.sh` get `DOTFILES`, `PROFILE_NAME`, `PROFILE_DIR`. Make
  deactivate undo activate, and only touch what activate created.

## Checks

Run these before declaring a change done:

```sh
cd ~/.dotfiles
# syntax
for f in script/bootstrap script/dot script/install script/profile script/lib/common.sh \
         secrets/lib.sh secrets/bin/secret secrets/bin/with-secrets; do bash -n "$f"; done
zsh -n zsh/zshrc.symlink
command -v shellcheck >/dev/null && shellcheck -S warning -x script/* secrets/lib.sh secrets/bin/*

# shell still starts, profile still loads
zsh -i -c 'echo ok; profile'

# Linux (Ubuntu 24.04 in Docker, fake pass-cli; ~1 min). Must print ALL LINUX CHECKS PASSED.
script/test-linux

# leak check over everything that would be committed (expect no output).
# Extend the pattern with the current employer's name, domain and username.
git ls-files -co --exclude-standard | grep -v '^m2.symlink/repository' \
  | xargs grep -nIiE 'BEGIN [A-Z ]*PRIVATE KEY|eyJ[a-zA-Z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|<password>[^$<]' 2>/dev/null
git add -A --dry-run | grep 'profiles/' | grep -vE "profiles/(README.md|_template/)"   # expect nothing
```

## Gotchas

- `grep` is aliased to `rg` and `cat` may be aliased in interactive shells. In
  scripts and tool commands use `command grep` / `command cat`.
- `pass-cli` v2 has no `test` subcommand. Use `pass-cli info` to check the
  session. `item list` on a big vault takes several seconds; `item view` about 1s.
- The secret cache lives in the OS secret store: `security` (macOS) or
  `secret-tool` (Linux, needs D-Bus). Without either, `secrets_cache_*` are
  no-ops and every lookup goes to Proton Pass.
- `secret-tool search` prints the secret on stdout but the `attribute.*`
  lines on **stderr**. Capture with `2>&1`, or cache reads silently miss.
- GNOME Keyring in a container sometimes can't create its default keyring
  (it wants a GUI prompter). `script/test/linux-container.sh` retries and
  SKIPs in that case; a FAIL there is a real bug.
- `git/completion.zsh` was removed on purpose. Homebrew's `_git` is an
  `fpath` completion function, and sourcing it at startup prints `_tags`
  errors.
- `git/gitconfig.local.symlink` and `system/env.local.zsh` are machine-local
  and git-ignored. Don't create them in commits; bootstrap generates them.
