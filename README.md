# DOTFILES

Simplified version of my dotfiles preferences. To start, just run `script/bootstrap` and it should guide you through everything.

## Installing / updating

- `script/bootstrap`: the one command to set up a fresh machine. It creates
  `gitconfig`, symlinks every `*.symlink` file into `$HOME`, (on macOS) installs
  all dependencies, checks your Proton Pass login, and points you at company
  profiles. Safe to re-run; set `DOTFILES_YES=1` to auto-confirm prompts.
- `script/dot`: periodic maintenance. Updates Homebrew and re-runs every
  installer. Flags: `--edit` (open the repo in `$EDITOR`), `--secrets`
  (check Proton Pass + secret references), `--no-update` (skip `brew update`), `--help`.
- `script/install`: runs `brew bundle` against the [`Brewfile`](Brewfile) and
  then executes **every** `*/install.sh` in the repo (Homebrew, SDKMAN, fzf-tab, …),
  plus the active profile's `*/Brewfile` and `*/install.sh`.
- `script/profile`: switch company profiles on/off (see [Profiles](#company-profiles)).

All scripts share [`script/lib/common.sh`](script/lib/common.sh) for consistent,
colourful output (colours auto-disable when piped or when `NO_COLOR` is set).
Once the dotfiles are installed, `script/` is on your `PATH`, so you can just run
`dot`, `bootstrap` or `profile` from anywhere.

The repo is organised **by feature**: each top-level folder is self-contained
(its `*.zsh`, `_path.zsh`, `completion.zsh`, `install.sh`, `secrets.refs`, …),
so removing a feature means deleting one folder. The [`Brewfile`](Brewfile)
lists every CLI tool and GUI app, grouped by feature with a one-line comment
explaining each entry.

## Company profiles

Nothing company-specific is committed here. Work email, internal hosts, package
registries and company-only commands live in a **profile**: `profiles/<name>/`,
a separate **private** git repo that this repo ignores. It uses the same
one-folder-per-feature layout.

```sh
profile list                # available profiles (* = active)
profile use acme            # activate / switch
profile off                 # deactivate
profile new acme            # start one from profiles/_template
profile clone <url>         # fetch an existing private profile repo
```

See [`profiles/README.md`](profiles/README.md) for the layout and hooks.

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

**No secrets are stored anywhere by these dotfiles**: not in git, not in a
profile, not in the Keychain. They stay in **Proton Pass** and are fetched with
the Proton Pass CLI (`pass-cli`) only when a command needs them.

A feature that needs a secret declares a *reference* in a `secrets.refs` file
next to it (global, or inside a profile feature):

```sh
# git/secrets.refs
GITHUB_TOKEN=pass://Personal/GitHub Token/password   # pass://<vault>/<item title>/<field>
```

```sh
secret login                 # log in to Proton Pass once (pass-cli login)
secret status                # check login + that every reference resolves (values never shown)
secret list                  # NAME -> reference, and which file declared it
secret GITHUB_TOKEN          # print one secret (e.g. | pbcopy)
with-secrets -- mvn verify   # run ONE command with all referenced secrets in its env
with-secrets GITHUB_TOKEN -- gh pr list   # ...or only the ones you name
```

`mvn` and the `mw*` aliases already go through `with-secrets` (see
[`m2.symlink/maven.zsh`](m2.symlink/maven.zsh)), so `${env.NAME}` references in
`~/.m2/settings.xml` just work. A variable already set in your environment
(e.g. via direnv) is not fetched again.

Machine-local, non-secret overrides go in `system/env.local.zsh` (git-ignored,
copy it from `system/env.local.zsh.example`).

### SSH keys

SSH keys live in Proton Pass, and the **Proton Pass SSH agent** serves them.
[`ssh/agent.zsh`](ssh/agent.zsh) starts the daemon in the background when it
isn't running and exports `SSH_AUTH_SOCK`. [`ssh/install.sh`](ssh/install.sh)
adds `Include ~/.dotfiles/ssh/config` to the top of `~/.ssh/config`, which
points `IdentityAgent` at the agent and includes the active profile's
`ssh/config`. Use `ssh-keys` to list the served keys and `ssh-agent-status` to
check the daemon.

### If a secret ever leaks

1. Rotate/revoke it immediately at the source (GitHub, Artifactory, etc.).
2. If it was ever committed, scrub history with `git filter-repo` and force-push.
3. Update the item in Proton Pass. Nothing else needs to change.
