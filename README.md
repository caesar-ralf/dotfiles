# DOTFILES

Simplified version of my dotfiles preferences. To start, just run `script/bootstrap` and it should guide you through everything.

## Installing / updating

- `script/bootstrap` — the one command to set up a fresh machine. It creates
  `gitconfig`, symlinks every `*.symlink` file into `$HOME`, (on macOS) installs
  all dependencies, and offers to set up your secrets. Safe to re-run; set
  `DOTFILES_YES=1` to auto-confirm prompts.
- `script/dot` — periodic maintenance. Updates Homebrew and re-runs every
  installer. Flags: `--edit` (open the repo in `$EDITOR`), `--secrets`
  (reconfigure secrets), `--no-update` (skip `brew update`), `--help`.
- `script/install` — runs `brew bundle` against the [`Brewfile`](Brewfile) and
  then executes **every** `*/install.sh` in the repo (Homebrew, SDKMAN, fzf-tab, …).
- `script/secrets` — interactive secrets setup (see [Secrets](#secrets)).

All scripts share [`script/lib/common.sh`](script/lib/common.sh) for consistent,
colourful output (colours auto-disable when piped or when `NO_COLOR` is set).
Once the dotfiles are installed, `script/` is on your `PATH`, so you can just run
`dot`, `bootstrap` or `secrets` from anywhere.

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
- [`git/aliases.zsh`](git/aliases.zsh) — fzf-powered git helpers: `jira`/`gcoa`
  (fuzzy checkout a branch), `gco` (local branch), `gbd` (fuzzy-delete branches),
  `gshow` (browse commits with preview), `gfixup` (pick a commit to `--fixup` +
  autosquash). Most git shortcuts are git aliases in
  [`git/gitconfig.symlink`](git/gitconfig.symlink): everyday ones (`co`, `st`,
  `lg`, `please`, `cleanup`, `sync`, `main`, `recent`), history helpers
  (`today`, `standup`, `search`, `filelog`), and "oops" fixes (`amend`,
  `undo-commit`, `nevermind`). Run `git aliases` to list them all.

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
| `killport <port>`   | Kill whatever is listening on a TCP port (`-9` for SIGKILL).             |
| `serve [port]`      | Serve the current directory over HTTP (default `8000`).                  |
| `dsh [shell]`       | Fuzzy-pick a running Docker container and open a shell in it.            |
| `backup <file> …`   | Copy each file to `<file>.YYYYmmdd-HHMMSS.bak` next to it.               |

Run any of them with `-h`/`--help` for usage.

## Shell plugins & tools

Wired up (and sourced in the right order) by [`zsh/zshrc.symlink`](zsh/zshrc.symlink),
all guarded so a fresh machine still boots if something is missing:

- **fzf** — `Ctrl-T` file picker, `Alt-C` cd, fuzzy completion (and it powers the
  `git/*` helpers). `Ctrl-R` history is handled by **atuin** (below).
- **atuin** — SQLite-backed shell history with context-aware search (filter by
  directory, exit code, session; optional end-to-end-encrypted sync). It owns
  `Ctrl-R` (loaded after fzf so it wins the binding) and is started with
  `--disable-up-arrow`, so the arrow-key history search still works. Import
  existing history any time with `atuin import auto`.
- **fzf-tab** — replaces the tab-completion menu with an `fzf` picker. It is not
  in Homebrew core, so [`fzf-tab/install.sh`](fzf-tab/install.sh) clones it into
  `~/.zsh/fzf-tab` (run automatically by `script/install`).
- **zoxide** — frecency-based `cd`; jump with `z <partial>`.
- **direnv** — per-directory environment variables. Drop an `.envrc` in a project,
  run `direnv allow`, and its env loads on `cd` in and unloads on the way out.
  Hooked in [`direnv/init.zsh`](direnv/init.zsh).
- **eza icons** — the `ls`/`l`/`ll`/`la`/`lt` aliases pass `--icons=auto`, so
  file-type glyphs show up (thanks to the Nerd Font).
- **bat man pages** — `MANPAGER` uses `bat` for syntax-highlighted `man` output
  (see [`system/env.zsh`](system/env.zsh)).
- **oh-my-posh** — the prompt theme engine. The theme is vendored in this repo at
  [`oh-my-posh/theme.omp.json`](oh-my-posh/theme.omp.json) and applied
  automatically on shell start by [`zsh/zshrc.symlink`](zsh/zshrc.symlink) — no
  manual theme selection needed. The required Nerd Font (`font-fira-code-nerd-font`)
  is installed by the [`Brewfile`](Brewfile), and [`iterm/install.sh`](iterm/install.sh)
  installs a matching iTerm2 profile — **"Dotfiles (FiraCode Nerd Font)"** — with the
  Nerd Font, Night Owl colours (matching the prompt), Option-as-Meta (for the
  `Alt+f`/`Alt+b` word-nav bindings), UTF-8 and sane bell/scrollback defaults. It is
  set as the **default** iTerm2 profile automatically, so the prompt glyphs render
  correctly out of the box. If iTerm2 is already running, fully quit (`Cmd-Q`) and
  reopen for it to take effect. Opt out with `DOTFILES_ITERM_DEFAULT=0`; your prior
  default is saved to `~/.local/state/dotfiles/iterm-previous-default-guid` and can be
  restored with `defaults write com.googlecode.iterm2 'Default Bookmark Guid' -string "<guid>"`.
  Other terminals: set your font to *FiraCode Nerd Font* manually.
- **zsh-autosuggestions** — fish-style inline suggestions from history (accept with →).
- **zsh-syntax-highlighting** — colours commands as you type (sourced last).

## Secrets

**No secrets are ever committed to this repo.** Everything sensitive is loaded at
runtime from either the macOS Keychain (preferred) or a git-ignored local file.

### Guided setup (recommended)

```sh
script/secrets            # interactive: prompts for each secret, stores in Keychain
script/secrets --status   # show which expected secrets are already set
script/secrets --local    # create system/env.local.zsh from the example
```

`script/secrets` knows which secrets this setup expects (`GITHUB_TOKEN`,
`ARTIFACTORY_USER`, `ARTIFACTORY_TOKEN`), skips ones already stored (unless you
choose to update them), and hides secret values while you type. It is also run
automatically as the last step of `script/bootstrap`.

### Storing a secret in the Keychain (manual)

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
