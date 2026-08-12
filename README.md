# DOTFILES

Simplified version of my dotfiles preferences. To start, just run `script/bootstrap` and it should guide you through everything.

## Installing / updating

- `script/bootstrap` — symlinks every `*.symlink` file into `$HOME`, sets up
  `gitconfig`, and (on macOS) installs dependencies.
- `script/install` — runs `brew bundle` against the [`Brewfile`](Brewfile) and
  then executes **every** `*/install.sh` in the repo (Homebrew, SDKMAN, fzf-tab, …).

Each topic folder is self-contained: drop an `install.sh` in a folder, and it is
picked up automatically. The [`Brewfile`](Brewfile) lists every CLI tool and GUI
app, grouped by feature with a one-line comment explaining each entry.

## Aliases

Aliases live next to the topic they belong to:

- [`zsh/aliases.zsh`](zsh/aliases.zsh) — general shortcuts (`g`=git, `k`=kubectl,
  Maven wrappers `mw`/`mws`/`mwv`, directory jumps `..`/`...`, and modern-tool
  replacements like `eza`/`rg`/`lazygit` that only activate when installed).
- [`system/aliases.zsh`](system/aliases.zsh) — `ls`/`l`/`ll`/`la` (via `gls`,
  overridden by `eza` when present).
- [`git/aliases.zsh`](git/aliases.zsh) — `jira` fuzzy branch checkout. Most git
  shortcuts are git aliases in [`git/gitconfig.symlink`](git/gitconfig.symlink)
  (`co`, `st`, `lg`, `please`, `cleanup`, …).

## Custom functions

Files in [`functions/`](functions) are autoloaded (see [`zsh/config.zsh`](zsh/config.zsh)),
so each file name becomes a command:

| Command             | What it does                                                             |
|---------------------|--------------------------------------------------------------------------|
| `extract <file>`    | Extract any archive (tar/zip/rar/…) or mount a `.dmg`.                   |
| `mkcd <dir>`        | `mkdir -p` a directory and `cd` into it.                                 |
| `certinfo <cert>`   | Summarise an X.509 cert (subject/issuer/dates/SANs); `-t` for full text. |
| `jarpeek <jar> …`   | List/grep jar entries, `-x` print an entry, `-c` `javap` a class.        |
| `klog [-n ns] [-f]` | Fuzzy-pick a Kubernetes pod with `fzf` and tail its logs.                |
| `volvo-jwt-token`   | Print the `sub` claim of a fresh Volvo ID token (`-e qa\|prod`).         |

Run any of them with `-h`/`--help` for usage.

## Shell plugins & tools

Wired up (and sourced in the right order) by [`zsh/zshrc.symlink`](zsh/zshrc.symlink),
all guarded so a fresh machine still boots if something is missing:

- **fzf** — `Ctrl-R` history search, `Ctrl-T` file picker, fuzzy completion.
- **fzf-tab** — replaces the tab-completion menu with an `fzf` picker. It is not
  in Homebrew core, so [`fzf-tab/install.sh`](fzf-tab/install.sh) clones it into
  `~/.zsh/fzf-tab` (run automatically by `script/install`).
- **zoxide** — frecency-based `cd`; jump with `z <partial>`.
- **zsh-autosuggestions** — fish-style inline suggestions from history (accept with →).
- **zsh-syntax-highlighting** — colours commands as you type (sourced last).

## Secrets

**No secrets are ever committed to this repo.** Everything sensitive is loaded at
runtime from either the macOS Keychain (preferred) or a git-ignored local file.

### Storing a secret in the Keychain (recommended)

```sh
secret-set GITHUB_TOKEN
secret-set ARTIFACTORY_USER
secret-set ARTIFACTORY_TOKEN
```

`system/env.zsh` reads these on shell start via `secret NAME` and exports them
only if present. The first Keychain read per app may prompt once - choose "Always Allow".

### Or use a git-ignored local file

```sh
cp system/env.local.zsh.example system/env.local.zsh
# edit system/env.local.zsh and add your exports
```

`*.local.zsh` and `system/env.local.zsh` are git-ignored and auto-sourced after
`env.zsh`.

### Maven / Artifactory

The real `~/.m2/settings.xml` is git-ignored because Artifactory bakes a personal
JWT into it. Use `m2.symlink/settings.xml.example` as a template that references
`${env.ARTIFACTORY_USER}` / `${env.ARTIFACTORY_TOKEN}` instead of hard-coding them.

### If a secret ever leaks

1. Rotate/revoke it immediately at the source (GitHub, Artifactory, etc.).
2. If it was ever committed, scrub history with `git filter-repo` and force-push.
3. Store the new value in the Keychain (`secret-set NAME`).
