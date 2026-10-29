# DOTFILES

My shell setup for **macOS** (primary) and **Ubuntu/Debian Linux**: zsh, git,
CLI tools, apps. Company-specific config lives in switchable **profiles**, and
secrets are fetched from **Proton Pass**.

```sh
git clone git@github.com:caesar-ralf/dotfiles.git ~/.dotfiles
~/.dotfiles/script/bootstrap        # guided setup, safe to re-run (macOS and Linux)
```

- [Principles](#principles)
- [Platforms: macOS and Linux](#platforms-macos-and-linux)
- [Layout](#layout)
- [Everyday commands](#everyday-commands)
- [Company profiles](#company-profiles)
- [Secrets](#secrets)
- [SSH keys](#ssh-keys)
- [Git, Maven](#git-maven)
- [Aliases, functions, shell tools](#aliases-functions-shell-tools)
- [Changing jobs checklist](#changing-jobs-checklist)
- [Troubleshooting](#troubleshooting)

For AI agents and future contributors: read [`AGENTS.md`](AGENTS.md).

## Principles

1. **Organised by feature, not by layer.** Each top-level folder holds
   everything for one feature: shell config, PATH, completion, installer,
   secrets it needs. Deleting a feature means deleting one folder.
2. **Nothing company-specific is committed.** Work email, internal hosts,
   registries and company-only commands live in a profile (a separate private
   repo under `profiles/`).
3. **No secrets in any repo.** Features only declare *references* to Proton
   Pass items. Values are fetched on demand and cached in the OS keychain.
4. **Fresh machines still boot.** Every tool integration is guarded, so a
   missing tool is skipped, not an error.
5. **One codebase for macOS and Linux.** Platform differences are handled in
   one place (`core/platform/`) or behind guards, never in separate copies.

## Platforms: macOS and Linux

macOS is the primary platform. Ubuntu/Debian is supported, and
`script/test-linux` verifies that in a Docker container.

| Concern | macOS | Linux (Ubuntu/Debian) |
|---------|-------|-----------------------|
| Packages | Homebrew + `Brewfile` | Homebrew on Linux (`/home/linuxbrew`) + the same `Brewfile`; [`core/platform/install.sh`](core/platform/install.sh) apt-installs prerequisites (zsh, build tools, xclip/wl-clipboard, xdg-utils, libsecret-tools) |
| GUI apps, fonts | casks in `Brewfile` | skipped (`if OS.mac?`); use apt/snap/flatpak and install a Nerd Font manually |
| Secret cache | login Keychain (`security`) | desktop keyring via `secret-tool` (GNOME Keyring/KWallet); **no cache** without a D-Bus session (headless/SSH), so every lookup goes to Proton Pass |
| `pbcopy` / `pbpaste` / `open` | native | shims in [`core/platform/linux-bin/`](core/platform/linux-bin) (wl-copy, xclip/xsel, WSL, xdg-open) |
| `ls` colours | `gls` (coreutils) | GNU `ls` |
| `intellij` | `open -a "IntelliJ IDEA"` | `idea` / `intellij-idea-ultimate` if installed |
| gcloud | Homebrew cask | apt/snap/`~/google-cloud-sdk` |
| iTerm2 profile | installed | skipped |
| Login shell | zsh by default | bootstrap offers `chsh -s zsh` |

`$DOTFILES_OS` (`macos` / `linux`) is available to every zsh file. To check
Linux support after a change, run `script/test-linux`. It needs Docker and
uses a fake `pass-cli`, so no real secrets are involved.

## Layout

Packaged **by feature**: a feature is one folder holding everything about one
thing (its PATH, aliases, completion, installer, secrets, linked dotfiles).
Features are grouped into a few **categories**. Deleting a feature folder
removes the feature.

```
~/.dotfiles
├── core/                      what everything else builds on
│   ├── zsh/                   zshrc.symlink (the loader), options, key bindings, general aliases
│   ├── system/                env vars (env.zsh), ls aliases, grc; env.local.zsh = git-ignored machine tweaks
│   ├── platform/              OS detection ($DOTFILES_OS), Linux shims for pbcopy/pbpaste/open
│   ├── homebrew/              installs Homebrew
│   └── functions/             general commands, one file each, autoloaded (extract, mkcd, ...)
├── shell/                     the interactive experience
│   ├── prompt/                oh-my-posh theme
│   ├── fzf-tab/  direnv/      fzf tab completion, per-directory env
│   └── iterm/                 iTerm2 profile
├── git/                       gitconfig, global hooks (Jira ticket), git ticket, fzf git helpers
├── security/
│   ├── secrets/               secret, with-secrets (Proton Pass + OS keychain cache)
│   └── ssh/                   Proton Pass SSH agent, config included from ~/.ssh/config
├── packages/                  one folder per tool or ecosystem
│   ├── java/                  SDKMAN (JDKs), intellij/gw aliases, jarpeek
│   ├── maven/                 mvn/mw* wrappers; m2.symlink/ = ~/.m2
│   ├── kubernetes/            kubectl aliases, k9s completion, klog
│   ├── docker/                aliases, completion path, dsh
│   ├── gcloud/  go/  python/  ruby/  postgres/
├── profiles/                  company profiles; only README.md and _template/ are committed
├── script/                    bootstrap, dot, install, profile, test-linux (+ lib/common.sh, test/)
├── Brewfile                   global CLI tools and apps, grouped and commented
└── AGENTS.md                  context for AI agents working on this repo
```

A feature folder can contain:

```
<feature>/
├── _path.zsh              sourced first (PATH, fpath)
├── *.zsh                  sourced on shell start (aliases.zsh, init.zsh, ...)
├── completion.zsh         sourced after compinit
├── functions/             one file per command, autoloaded
├── bin/                   executables (put on PATH by the feature's _path.zsh)
├── install.sh             run by `dot` / script/install
├── secrets.refs           secrets this feature needs (references, never values)
└── *.symlink              linked into $HOME as .<name> by bootstrap
```

Where does a new thing go? Tool-specific (a CLI, language, SDK) →
`packages/<tool>/`. Shell look and feel → `shell/`. Needed by everything →
`core/`. Credentials and keys → `security/`. Big enough to be its own world →
top level (like `git/`). Features are never deeper than `category/feature/`:
the loader only looks at those two levels (see below).

### How a shell starts

`core/zsh/zshrc.symlink` (= `~/.zshrc`) collects `$DOTFILES/*/*.zsh` and
`$DOTFILES/*/*/*.zsh` (top-level features and features inside a category,
`profiles/` excluded), then the active profile's
`~/.config/dotfiles/profile/*/*.zsh`, and sources them in three passes:

1. every `_path.zsh`,
2. everything else except completions,
3. `compinit`, then every `completion.zsh`.

Every `<feature>/functions/` folder is autoloaded too. Profile files come after
global files in each pass, so a profile can override anything. The globs are
depth-limited on purpose: `packages/maven/m2.symlink/repository` holds over 16k
directories.

## Everyday commands

| Command                                          | What it does                                                                           |
|--------------------------------------------------|----------------------------------------------------------------------------------------|
| `dot`                                            | Update Homebrew, `brew bundle`, and run every `install.sh` (global and active profile) |
| `script/test-linux`                              | Check Linux (Ubuntu) support in Docker (fake `pass-cli`, no real secrets)               |
| `dot --secrets`                                  | Same as `secret status`                                                                |
| `profile` / `profile use <name>` / `profile off` | Show / switch / disable the company profile                                            |
| `secret list`                                    | Which secrets exist, where they're declared, how fresh the cache is                    |
| `secret add NAME` / `secret new NAME`            | Link a secret to an existing Proton Pass item / create one                             |
| `with-secrets -- <cmd>`                          | Run a command with secrets in its environment                                          |
| `reload!`                                        | Re-source `~/.zshrc` (`exec zsh` is cleaner)                                           |

## Company profiles

A profile is everything specific to one employer or client. It lives in
`profiles/<name>/`, which is **its own private git repo**; this repo ignores
it. Inside, it uses the same one-folder-per-feature layout, plus a few extras.

```sh
profile                     # active profile and its features
profile list                # all profiles (* = active)
profile new acme            # scaffold profiles/acme from profiles/_template (git init)
profile clone <url> [name]  # fetch an existing private profile repo
profile use acme            # activate (switches if another is active), runs */activate.sh
profile off                 # deactivate, runs */deactivate.sh
```

Then run `exec zsh`. Run `dot` if the profile ships a `Brewfile` or `install.sh`.

The active profile is a symlink: `~/.config/dotfiles/profile -> profiles/<name>`.
Everything else follows from it:

| Profile file                                     | Effect while active                                                    |
|--------------------------------------------------|------------------------------------------------------------------------|
| `<feature>/*.zsh`, `_path.zsh`, `completion.zsh` | sourced by `~/.zshrc` after the global ones                            |
| `<feature>/functions/*`                          | autoloaded as commands                                                 |
| `git/gitconfig`                                  | included **last** by `git/gitconfig.symlink` (work email, credentials) |
| `ssh/config`                                     | included by `security/ssh/config` (company hosts)                      |
| `<feature>/secrets.refs`                         | used by `secret` / `with-secrets`; overrides global names              |
| `<feature>/Brewfile`, `install.sh`               | run by `dot`                                                           |
| `<feature>/activate.sh`, `deactivate.sh`         | run by `profile use` / `profile off` (e.g. link `~/.m2/settings.xml`)  |

Details and the hook environment are in [`profiles/README.md`](profiles/README.md).

## Secrets

### The model

- **Proton Pass is the source of truth.** Nothing secret is written to git, to a
  profile, or to a dotfile.
- A feature that needs a secret declares a **reference** in its
  `secrets.refs`:

  ```sh
  # NAME[:ttl]=pass://<vault name>/<item title>/<field>
  GITHUB_TOKEN=pass://Personal/GitHub Token/password
  ARTIFACTORY_TOKEN:12h=pass://Work/Artifactory/password
  ```

- `secret NAME` and `with-secrets` resolve a NAME from the **OS keychain cache**
  when it's fresh, and otherwise from **Proton Pass** (about 1s), re-caching the
  value.
- Secrets are **never exported into your shell**. `with-secrets -- cmd` puts
  them into the environment of that one command only. `mvn` and the `mw*`
  aliases already do this, so `${env.NAME}` in `~/.m2/settings.xml` just
  works.

### Which secret do I need?

```sh
secret list      # every declared NAME, its TTL, cache age, reference, and declaring file
secret scan      # variables used by ~/.m2/settings.xml: declared / set in shell / MISSING
secret scan ~/.npmrc some/config.yml   # any other file that uses ${X} or ${env.X}
secret status    # log-in check + fetch every NAME now; tells you which references are broken
```

When a tool asks for a token, or `secret scan` reports **MISSING**, declare it:

```sh
secret add NAME   # link it to an EXISTING Proton Pass item
secret new NAME   # create a NEW login item in Proton Pass, then link it
#  --feature git | packages/maven | profile:artifactory   where to declare it (asks if omitted)
#  --ttl 12h | 7d | 0 | forever                        cache lifetime (default 7d)
```

`secret add` walks you through fzf pickers: feature → vault → item → field
(only field *names* are shown). It writes the reference, then fetches the value
once to verify it and warm the cache. Choose the feature by asking yourself
*"if I delete this feature, should this secret go too?"* Anything
company-specific goes in `profile:<feature>`.

### Caching

|              |                                                                                                                              |
|--------------|------------------------------------------------------------------------------------------------------------------------------|
| Where        | macOS: login Keychain, items `dotfiles:<NAME>` (search "dotfiles" in *Keychain Access*). Linux: desktop keyring via `secret-tool`, `service=dotfiles name=<NAME>` (*Seahorse* / "Passwords and Keys"). Neither available: no cache. Force one with `DOTFILES_SECRET_CACHE=keychain\|libsecret\|none`. `secret status` shows which is in use |
| Default TTL  | `7d`. Override per secret (`NAME:12h=`) or globally (`export DOTFILES_SECRET_TTL=1d` in `~/.zshenv`)                         |
| Never cache  | `NAME:0=...`. Use this for anything you'd hate to lose.                                                                      |
| Invalidation | changing a reference invalidates its cache automatically; `secret refresh [NAME]` re-fetches; `secret forget [NAME]` deletes |
| Not cached   | multi-line values (keys, certificates), and `secret pass://...` lookups                                                      |

Cached values are protected by the OS keychain (encrypted at rest, locked with
your login). They reach `security` / `secret-tool` only through stdin, never as
process arguments. On Linux, keyring calls time out after 5s
(`DOTFILES_SECRET_TOOL_TIMEOUT`), so a locked keyring over SSH can't hang a command.

### Commands

```sh
secret login                 # pass-cli login (browser)
secret NAME                  # print a value, e.g. `secret GITHUB_TOKEN | pbcopy`
secret pass://Vault/Item/field
with-secrets -- mvn verify               # all declared secrets
with-secrets GITHUB_TOKEN -- gh pr list  # only these
secret refresh | forget [NAME ...]
```

A variable that's already set (e.g. by direnv) is not fetched again. If Proton
Pass is unreachable and nothing is cached, `with-secrets` warns and runs the
command anyway.

### If a secret leaks

1. Revoke or rotate it at the source (GitHub, Artifactory, ...).
2. Update the item in Proton Pass, then run `secret refresh NAME`.
3. If it was ever committed, scrub history with `git filter-repo` and force-push.

## SSH keys

SSH keys live in Proton Pass, and the **Proton Pass SSH agent** serves them,
so no private key sits on disk.

- [`security/ssh/agent.zsh`](security/ssh/agent.zsh) starts `pass-cli ssh-agent daemon` in the
  background if it isn't running (requires `secret login`) and exports
  `SSH_AUTH_SOCK=~/.ssh/proton-pass-agent.sock`.
- [`security/ssh/install.sh`](security/ssh/install.sh) adds `Include ~/.dotfiles/security/ssh/config` at the
  top of `~/.ssh/config`. That config sets `IdentityAgent` to the socket and
  includes the active profile's `ssh/config`.
- `ssh-keys` lists the keys the agent serves; `ssh-agent-status` and
  `ssh-agent-restart` manage the daemon.
- To use the system agent instead, put `export DOTFILES_SSH_AGENT=system` in `~/.zshenv`.

## Git, Maven

**Git.** [`git/gitconfig.symlink`](git/gitconfig.symlink) is the shared config
(aliases, delta/difftastic, rebase defaults, ...). Includes, in order:
`~/.gitconfig.local` (name, personal email, credential helper, signing key;
created by bootstrap, git-ignored), then the active profile's `git/gitconfig`
(work email, company hosts), which wins. Commits are not signed
(`commit.gpgsign = false`). `gpg.format = ssh` is kept so `git commit -S` signs
with a key from the agent.

**Git hooks.** `core.hooksPath` points every repo at
[`git/git_global.symlink/hooks`](git/git_global.symlink/hooks). Each hook there
is a stub for `_dispatch`, which first runs the repo's own `.git/hooks/<name>`
(pre-commit framework, husky-less setups, ...) and then the dotfiles
implementation in `hooks.d/<name>`, so repo hooks keep working. Repos that set
their own `core.hooksPath` (husky, lefthook) are unaffected.

**Jira ticket.** `hooks.d/commit-msg` adds the branch's ticket as the last line
of the message (before trailers like `Co-authored-by:`):
`feature/WEAV-123-login` → `WEAV-123`. Detection is strict to avoid false
positives: the key must stand alone in the branch name (any case), common
look-alikes (`UTF-8`, `SHA-256`, `ISO-8601`, `CVE-…`, `X86-64`) are ignored,
and when the branch has two different candidates nothing is added. Nothing is
added either when the message already mentions a ticket, for merges,
`fixup!`/`squash!` commits, or on `main`/`master`/`develop`/`dev`/`trunk`. It
never prompts; it prints a hint instead.

```sh
git ticket                 # what would be added on this branch, and why
git ticket WEAV-123        # force a ticket for this branch
git ticket none            # never add one on this branch
git ticket --clear         # back to automatic
git config hooks.ticketProjects "WEAV PLAT"   # only these keys (best: in the profile's git/gitconfig)
git config hooks.ticket false                 # disable in this repo
SKIP_TICKET=1 git commit ...                  # skip once
```

`script/test/git-hooks.sh` tests all of this with real commits.

**Maven.** `~/.m2` is `packages/maven/m2.symlink/`. The real `~/.m2/settings.xml` is
git-ignored. Profiles provide it (e.g. linked by `artifactory/activate.sh`),
and it must reference credentials as `${env.NAME}`, never inline.
[`packages/maven/maven.zsh`](packages/maven/maven.zsh) wraps `mvn` and the
`mw`/`mwv`/`mwi` aliases (`./mvnw`) with `with-secrets`. IDEs that run Maven
themselves don't get these variables: set them in the IDE run configuration,
or launch the IDE through `with-secrets`.

## Aliases, functions, shell tools

### Aliases

Aliases live next to the feature they belong to:

- [`core/zsh/aliases.zsh`](core/zsh/aliases.zsh): general shortcuts (`g`=git,
  directory jumps `..`/`...`, and modern-tool replacements like `eza`/`rg`/`lazygit`
  that only activate when installed).
- `packages/<tool>/aliases.zsh`: tool shortcuts, e.g. `k`/`kgp`/`kns` (kubernetes),
  `docker-clean` (docker), `intellij`/`gw` (java).
- [`packages/maven/maven.zsh`](packages/maven/maven.zsh): `mw`, `mws`, `mwv`, `mwi`.
- [`core/system/aliases.zsh`](core/system/aliases.zsh): `ls`/`l`/`ll`/`la`.
- [`security/ssh/agent.zsh`](security/ssh/agent.zsh): `ssh-keys`, `ssh-agent-status`, `ssh-agent-restart`.
- [`git/aliases.zsh`](git/aliases.zsh): fzf git helpers. `jira`/`gcoa` fuzzy-checkout
  a branch, `gco` a local branch, `gbd` fuzzy-deletes branches, `glog` browses
  history, `gstash` manages stashes, `gfixup` picks a commit to fixup and
  autosquash. Most git shortcuts are git aliases in
  [`git/gitconfig.symlink`](git/gitconfig.symlink). Run `git aliases` to list them.

### Custom functions

Every `<feature>/functions/` folder is autoloaded, so each file name becomes a
command. General ones live in [`core/functions/`](core/functions); tool-specific
ones next to their tool (`packages/kubernetes/functions/klog`, ...). Profiles
can add their own the same way.

| Command             | What it does                                                             |
|---------------------|--------------------------------------------------------------------------|
| `extract <file>`    | Extract any archive (tar/zip/rar/…) or mount a `.dmg`.                   |
| `mkcd <dir>`        | `mkdir -p` a directory and `cd` into it.                                 |
| `certinfo <cert>`   | Summarise an X.509 cert (subject/issuer/dates/SANs); `-t` for full text. |
| `jarpeek <jar> …`   | List/grep jar entries, `-x` print an entry, `-c` `javap` a class.        |
| `klog [-n ns] [-f]` | Fuzzy-pick a Kubernetes pod with `fzf` and tail its logs.                |
| `killport <port>`   | Kill whatever is listening on a TCP port (`-9` for SIGKILL).             |
| `serve [port]`      | Serve the current directory over HTTP (default `8000`).                  |
| `dsh [shell]`       | Fuzzy-pick a running Docker container and open a shell in it.            |
| `backup <file> …`   | Copy each file to `<file>.YYYYmmdd-HHMMSS.bak` next to it.               |

Run any of them with `-h`/`--help` for usage.

### Shell plugins & tools

Wired up (in the right order) by [`core/zsh/zshrc.symlink`](core/zsh/zshrc.symlink), all guarded:

- **fzf**: `Ctrl-T` file picker, `Alt-C` cd, fuzzy completion; powers the git
  helpers and the `secret add` pickers.
- **atuin**: SQLite-backed history search. Owns `Ctrl-R` (loaded after fzf) and
  is started with `--disable-up-arrow`. Import old history with `atuin import auto`.
- **fzf-tab**: fzf-powered tab completion, cloned to `~/.zsh/fzf-tab` by
  [`shell/fzf-tab/install.sh`](shell/fzf-tab/install.sh).
- **zoxide**: `z <partial>` jumps to frecent directories.
- **direnv**: per-directory env via `.envrc` (`direnv allow`). A handy place
  for per-project, non-secret variables.
- **oh-my-posh**: prompt theme vendored at [`shell/prompt/theme.omp.json`](shell/prompt/theme.omp.json).
  It needs the Nerd Font from the Brewfile. [`shell/iterm/install.sh`](shell/iterm/install.sh)
  installs and defaults a matching iTerm2 profile, "Dotfiles (FiraCode Nerd
  Font)" (opt out with `DOTFILES_ITERM_DEFAULT=0`).
- **eza** icons, **bat** man pages, **zsh-autosuggestions**, **zsh-syntax-highlighting** (sourced last).

## Tutorial: writing interactive commands

[`tutorial/`](tutorial/README.md) explains how to write commands like `klog`,
`dsh` or `gco`: bash commands that let you pick things with fzf and still
work in scripts and pipes.

1. [Anatomy of a good command](tutorial/01-anatomy.md): help text, options,
   exit codes, stdout vs stderr, dry run, macOS/Linux portability.
2. [Selection with fzf](tutorial/02-selection-with-fzf.md): pickers, hidden ID
   columns, previews, multi-select, per-key actions, `--filter`.
3. [Without fzf, without a human](tutorial/03-fallbacks-and-scripting.md):
   arguments instead of pickers, terminal detection, `select` menus,
   confirmations.
4. [Shipping it in these dotfiles](tutorial/04-shipping-it.md): script or
   function, which folder, zsh completion, testing, checklist.

The runnable examples are in [`tutorial/examples/`](tutorial/examples), and
`tutorial/examples/test.sh` checks them. The folder is documentation only:
nothing in it is sourced, autoloaded or installed.

## Changing jobs checklist

Leaving:

1. `profile off`
2. Make sure the profile repo is pushed to its private remote, then `rm -rf profiles/<old>`.
3. `secret forget` clears cached values; the Proton Pass vault itself is yours to clean up.

Joining:

1. `profile new <company>`, then `git -C profiles/<company> remote add origin <private-url>`.
2. Fill in `git/gitconfig` (work email). Add a feature folder per need
   (registry, VPN, cloud CLI, ...). Use `secret add NAME --feature profile:<feature>`
   for its tokens.
3. `profile use <company>`, `exec zsh`, and `dot` if you added a Brewfile or installer.

## Troubleshooting

| Symptom                                  | Fix                                                                                                       |
|------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| `secret …` prints nothing at all | That terminal predates the change and still has an old `secret` zsh function (check: `whence -va secret`). Fix: `exec zsh` |
| `with-secrets: could not get X`          | `secret status` shows whether you're logged in and which reference is broken. Re-link with `secret add X` |
| Maven 401                                | `secret scan` (MISSING variables?), `secret refresh ARTIFACTORY_TOKEN` (rotated token?)                   |
| `ssh: no identities` / permission denied | `secret login`, then `ssh-agent-restart` and `ssh-keys`                                                   |
| Profile changes not visible              | `exec zsh`; for `~/.m2/settings.xml` run `profile off && profile use <name>`                              |
| Wrong git email                          | `git config --show-origin user.email` shows which file set it                                             |
| Slow shell start                         | `zsh -i -c exit` with `zmodload zsh/zprof` at the top of `~/.zshrc`                                       |
