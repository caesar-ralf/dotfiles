# Profiles

A **profile** holds everything specific to one company (or client): git
identity, internal hosts, package registries, company-only commands, extra
apps. Profiles can be switched on, off, or swapped, and none of them are
committed to this repo.

- Each profile is a folder `profiles/<name>/` that is **its own private git
  repo**. This repo ignores everything in `profiles/` except this README and
  [`_template/`](_template).
- **Never put secrets in a profile.** Declare a reference to a Proton Pass
  item in a `secrets.refs` file instead (see [Secrets](../README.md#secrets)).
- Deleting a profile, or one feature inside it, means deleting one folder.

## Commands

```sh
profile                     # show the active profile and its features
profile list                # list profiles (* = active)
profile new acme            # create profiles/acme from _template (git init)
profile clone <url> [name]  # clone an existing private profile repo
profile use acme            # activate (switches if another one is active)
profile off                 # deactivate
```

After `use`/`off`, open a new shell (`exec zsh`). Run `dot` to install the
profile's Brewfiles and installers.

## Layout

A profile mirrors the top-level layout of this repo: one folder per feature.
Every file is optional.

```
profiles/<name>/
  git/gitconfig              # included last by git/gitconfig.symlink (email, credentials, url rewrites)
  ssh/config                 # included by ssh/config (Host blocks for company servers)
  <feature>/_path.zsh        # sourced first at shell start (PATH)
  <feature>/*.zsh            # sourced at shell start, after the global files (can override)
  <feature>/completion.zsh   # sourced after compinit
  <feature>/functions/       # each file is autoloaded as a command
  <feature>/secrets.refs     # NAME=pass://<vault>/<item>/<field>, used by `secret`/`with-secrets`
  <feature>/Brewfile         # installed by `dot` / script/install while active
  <feature>/install.sh       # run by `dot` / script/install while active
  <feature>/activate.sh      # run by `profile use` (e.g. link a settings file)
  <feature>/deactivate.sh    # run by `profile off` (undo activate.sh)
```

Hooks get `DOTFILES`, `PROFILE_NAME` and `PROFILE_DIR` in their environment.

## How it is wired

The active profile is a symlink: `~/.config/dotfiles/profile -> profiles/<name>`.

- `zsh/zshrc.symlink` loads `~/.config/dotfiles/profile/*/*.zsh` and autoloads its `*/functions/`.
- `git/gitconfig.symlink` includes `~/.config/dotfiles/profile/git/gitconfig`.
- `ssh/config` includes `~/.config/dotfiles/profile/ssh/config`.
- `script/install` runs the profile's `*/Brewfile` and `*/install.sh`.
- `secret` / `with-secrets` read the profile's `*/secrets.refs`.
