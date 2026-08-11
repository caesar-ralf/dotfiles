# DOTFILES

Simplified version of my dotfiles preferences. To start, just run `script/bootstrap` and it should guide you through everything.

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
