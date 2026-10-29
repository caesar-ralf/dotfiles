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

- **Organised by feature, not by layer.** A feature folder contains all its
  pieces. A user should be able to delete a feature by deleting one folder.
  Don't put feature-specific code into shared files (`core/zsh/zshrc.symlink`,
  `core/zsh/aliases.zsh`, `script/*`) if a file inside the feature folder can
  do the job.
- **Two levels, max.** A feature is either top-level (`git/`) or inside one
  category folder: `core/` (loader, system, platform, homebrew, general
  functions), `shell/` (prompt, fzf-tab, direnv, iterm), `security/`
  (secrets, ssh), `packages/` (one folder per tool: java, maven, kubernetes,
  docker, gcloud, go, python, ruby, postgres). The category list is
  `DOTFILES_CATEGORIES` in `script/lib/common.sh` (`dotfiles_features` lists
  features). Never nest deeper: the loader, `secrets_ref_files` and bootstrap's
  `find -maxdepth 3` only look at these two levels. Profiles stay flat
  (`profiles/<p>/<feature>/`).
- **File conventions** (auto-discovered, no registration needed):

  | File                                              | Picked up by                               | When                     |
  |---------------------------------------------------|--------------------------------------------|--------------------------|
  | `<feature>/_path.zsh`                             | `core/zsh/zshrc.symlink`                        | shell start, pass 1      |
  | `<feature>/*.zsh`                                 | `core/zsh/zshrc.symlink`                        | shell start, pass 2      |
  | `<feature>/completion.zsh`                        | `core/zsh/zshrc.symlink`                        | after `compinit`         |
  | `<feature>/install.sh`                            | `script/install` (via `dot`)               | install/update           |
  | `<feature>/secrets.refs`                          | `security/secrets/lib.sh`                           | `secret`, `with-secrets` |
  | `<feature>/*.symlink`                             | `script/bootstrap`                         | linked to `~/.<name>`    |
  | `<feature>/functions/<cmd>`                       | `core/zsh/zshrc.symlink`                   | autoloaded zsh function  |
  | `profiles/<p>/<feature>/functions/<cmd>`          | `core/zsh/zshrc.symlink`                   | autoloaded while active  |
  | `profiles/<p>/<feature>/{activate,deactivate}.sh` | `script/profile`                           | `profile use` / `off`    |
  | `profiles/<p>/<feature>/Brewfile`                 | `script/install`                           | while active             |
  | `profiles/<p>/git/gitconfig`                      | `git/gitconfig.symlink` `[include]` (last) | always (missing = no-op) |
  | `profiles/<p>/ssh/config`                         | `security/ssh/config` `Include`            | always (missing = no-op) |

- **Active profile** = symlink `~/.config/dotfiles/profile -> profiles/<name>`
  (`$DOTFILES_PROFILE_LINK`). Everything resolves profile files through this
  path. `active_profile` in `script/lib/common.sh` returns the name.
- **Shell loading**: `core/zsh/zshrc.symlink` globs `$DOTFILES/*/*.zsh` and
  `$DOTFILES/*/*/*.zsh` (minus `profiles/`), then
  `$DOTFILES_PROFILE_LINK/*/*.zsh(N)`. Keep globs **depth-limited**: never use
  `**` from the repo root, because `packages/maven/m2.symlink/repository/` holds over 16k
  Maven cache directories. Likewise, every `find` must prune
  `packages/maven/m2.symlink/repository`, and `profiles/` too (only the active profile counts).
- **Secrets** (`security/secrets/`):
  - `secrets.refs` lines look like `NAME[:ttl]=pass://<vault>/<item title>/<field>`.
  - `security/secrets/lib.sh` parses refs, resolves them via `pass-cli item view
    --vault-name --item-title --field`, and caches values in the macOS login
    Keychain as `dotfiles:<NAME>`. The item comment holds `<epoch> <hash(ref)>`.
    Default TTL is `$DOTFILES_SECRET_TTL` (7d).
  - `security/secrets/bin/secret` is the user CLI (`list/status/scan/add/new/refresh/forget`).
  - `security/secrets/bin/with-secrets` injects values into one child process. Secrets
    are **never** exported into the interactive shell at startup; keep it
    that way (it's slow and leaks them into every child process).
  - Values must never appear in process arguments. Write to the Keychain
    through `security -i` on stdin, and to `pass-cli` through
    `--from-template -` on stdin.
  - Never print secret values in logs, tests, or tool output. When verifying,
    print only lengths (`${#value}`).
- **SSH**: the Proton Pass SSH agent (`security/ssh/agent.zsh`) at
  `~/.ssh/proton-pass-agent.sock`. `security/ssh/install.sh` adds one `Include` line
  to `~/.ssh/config`; the rest of that file belongs to the user.
- **Platforms** (`core/platform/`):
  - `core/platform/_path.zsh` sets `DOTFILES_OS=macos|linux` and, on Linux, puts
    `core/platform/linux-bin/` (`pbcopy`, `pbpaste`, `open` shims) on PATH. Code
    can therefore use the macOS command names everywhere.
  - `core/platform/install.sh` apt-installs Linux prerequisites.
  - Homebrew is the package manager on both systems (Linuxbrew on Linux).
    `load_brew` in `script/lib/common.sh` and the top of `core/zsh/zshrc.symlink`
    find it in `/opt/homebrew`, `/usr/local`, or `/home/linuxbrew`.
    `$BREW_PREFIX` is **empty** when Homebrew is absent, so guard every use.
  - Casks are macOS-only (`if OS.mac?` in the Brewfile).
  - Secret cache backends: `keychain` (macOS `security`), `libsecret`
    (Linux `secret-tool`, needs a D-Bus session), or `none`. Selection is in
    `secrets_cache_backend`.
- **Git**: `git/gitconfig.symlink` includes `~/.gitconfig.local` first
  (machine/personal, git-ignored) and the profile's `git/gitconfig` last.
- **Git hooks**: `core.hooksPath = ~/.git_global/hooks` (global, all repos).
  Every file in `git/git_global.symlink/hooks/` is a stub that execs
  `_dispatch <name>`: it runs the repo's own `.git/hooks/<name>` first (with
  git's stdin), then ours from `hooks.d/<name>` (stdin = /dev/null). Copies of
  the pre-2026 ticket hook in `.git/hooks` are skipped. Add a global hook by
  dropping an executable into `hooks.d/` (and a stub, if the name is new).
  `hooks.d/commit-msg` = Jira ticket footer: strict detection (standalone
  `KEY-123`, deny-list of look-alikes, or only `hooks.ticketProjects` keys),
  per-branch override `branch.<name>.ticket` (set via `git ticket`), never
  prompts. Test: `script/test/git-hooks.sh`.

## Repo map

```
script/              bootstrap (fresh machine), dot (update), install (brew + installers), profile, test-linux; lib/common.sh = output helpers, confirm, active_profile, is_macos/is_linux, load_brew, DOTFILES_CATEGORIES, dotfiles_features; test/{linux-container.sh,git-hooks.sh}
core/zsh/            zshrc.symlink (loader), config.zsh, aliases.zsh (general only), completion.zsh, window.zsh
core/system/         env.zsh, aliases.zsh, grc.zsh, keys.zsh, env.local.zsh(.example, git-ignored)
core/platform/       _path.zsh (DOTFILES_OS, Linux shims on PATH), linux-bin/{pbcopy,pbpaste,open}, install.sh (apt prerequisites)
core/homebrew/       install.sh
core/functions/      general autoloaded commands (backup, certinfo, extract, killport, mkcd, serve)
shell/               prompt/theme.omp.json, fzf-tab/install.sh, direnv/init.zsh, iterm/
git/                 gitconfig.symlink, gitconfig.local.symlink(.example), aliases.zsh, secrets.refs, bin/git-ticket,
                     git_global.symlink/{hooks/(_dispatch + stubs), hooks.d/commit-msg}
security/secrets/    lib.sh, bin/secret, bin/with-secrets, install.sh (checks pass-cli)
security/ssh/        agent.zsh, config, install.sh
packages/java/       _path.zsh + install.sh (SDKMAN), aliases.zsh (intellij, gw), functions/jarpeek
packages/maven/      _path.zsh, maven.zsh (with-secrets wrappers); m2.symlink/ = ~/.m2 (repository/, wrapper/, settings.xml* git-ignored)
packages/kubernetes/ aliases.zsh, completion.zsh (k9s), functions/klog
packages/docker/     _path.zsh (completion fpath), aliases.zsh, functions/dsh
packages/{gcloud,go,python,ruby,postgres}/  PATH / lazy init / completion
profiles/            README.md, _template/ (tracked); <name>/ (private repos, ignored)
Brewfile             global packages, grouped with one-line comments
```

## Coding conventions

- **Bash scripts** (`script/*`, `security/secrets/*`, hooks): `#!/usr/bin/env bash`.
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
  Put a macOS command's Linux equivalent in `core/platform/linux-bin/` instead of
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
  profile), plus a `packages/<tool>/` folder for its shell config if needed
  (aliases, functions, completion go there, not in `core/zsh/`).
- **Add a feature that needs a secret:** create `<feature>/secrets.refs` with
  `NAME=pass://...` (or have the user run `secret add NAME --feature <feature>`).
  Consume it via `with-secrets -- cmd`, or a wrapper function like
  `packages/maven/maven.zsh`.
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
         security/secrets/lib.sh security/secrets/bin/secret security/secrets/bin/with-secrets; do bash -n "$f"; done
zsh -n core/zsh/zshrc.symlink
command -v shellcheck >/dev/null && shellcheck -S warning -x script/* security/secrets/lib.sh security/secrets/bin/*

# global git hooks + Jira ticket detection (real commits in a temp repo)
script/test/git-hooks.sh

# shell still starts, profile still loads
zsh -i -c 'echo ok; profile'

# Linux (Ubuntu 24.04 in Docker, fake pass-cli; ~1 min). Must print ALL LINUX CHECKS PASSED.
script/test-linux

# leak check over everything that would be committed (expect no output).
# Extend the pattern with the current employer's name, domain and username.
git ls-files -co --exclude-standard | grep -v '^packages/maven/m2.symlink/repository' \
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
- Git runs `commit-msg` with no TTY from IDEs, so hooks must never prompt or
  block; print a hint on stderr instead.
- Ubuntu's default awk is `mawk`: in hooks stick to POSIX awk (`match`,
  `RSTART`, `substr`, `toupper`), no gawk extensions.
- `git/gitconfig.local.symlink` and `core/system/env.local.zsh` are machine-local
  and git-ignored. Don't create them in commits; bootstrap generates them.
