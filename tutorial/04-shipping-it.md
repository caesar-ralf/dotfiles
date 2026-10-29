# 4. Shipping it in these dotfiles

You have a working script. This chapter covers how to turn it into a command
you can type in every shell, on macOS and Linux, and how to keep it working.

## Script or function?

| | **Script** (`<feature>/bin/<name>`) | **zsh function** (`<feature>/functions/<name>`) |
|---|---|---|
| Runs in | its own bash process | your interactive zsh |
| Language | bash (portable, as in chapters 1–3) | zsh |
| Can change your shell (`cd`, `export`, history) | no | **yes** |
| Usable from other scripts, `xargs`, IDEs, `with-secrets` | yes | no |
| Testable on its own | yes | harder |
| Start-up cost | none until run | none until run (autoloaded) |

**Default to a script.** Use a function only when the command must change the
current shell. Even then, keep the logic in a script and make the function a
thin wrapper:

```zsh
# core/functions/cdp: pick a project directory and cd into it
cdp() {
    local dir
    dir="$(pick-project "$@")" && cd -- "$dir"
}
```

`pick-project` (a script) does the listing, picking and validation, prints the
path, and can be tested. The function only does the `cd`.

## Where the file goes

Same rule as everything else in this repo (see the [README](../README.md#layout)):
put the command next to the thing it's about.

| Command is about | Script | Function |
|------------------|--------|----------|
| a tool (docker, kubernetes, java, ...) | `packages/<tool>/bin/<name>` | `packages/<tool>/functions/<name>` |
| git | `git/bin/<name>` (like `git-ticket`) | `git/aliases.zsh` |
| nothing specific | a feature with a `bin/` (e.g. `core/<feature>/bin/`) | `core/functions/<name>` |
| one employer | `profiles/<p>/<feature>/bin/<name>` | `profiles/<p>/<feature>/functions/<name>` |

- **Functions** are found automatically: every `<feature>/functions/` folder
  is autoloaded, and the file name becomes the command.
- **Scripts** need their `bin/` on `PATH`, via the feature's `_path.zsh`:

  ```zsh
  # packages/<tool>/_path.zsh
  export PATH="$DOTFILES/packages/<tool>/bin:$PATH"
  ```

- Name commands without `.sh`: people type `fkill`, not `fkill.sh`. (The
  tutorial examples have the extension only because they are examples.)
- Make scripts executable (`chmod +x`). Git stores that bit, so check
  `git ls-files -s <file>` shows mode `100755`.
- Stay within two levels (`category/feature/`): the loader doesn't look
  deeper.
- Then `exec zsh`, and add the command to the README table under
  [Custom functions](../README.md#custom-functions).

## Writing zsh functions

Autoloaded functions here run **in zsh, inside your shell**, which changes
a few things compared to the bash scripts above:

- `exit` closes your terminal. Use `return`.
- Never `set -e`/`set -u` or other options globally: they would stay set in
  your shell. Use `emulate -L zsh` at the top of the function, which resets
  options for the function only.
- Variables are global unless declared `local`.
- Unquoted `$var` is **not** split into words in zsh (it is in bash). Build
  argument lists as arrays: `local -a ns; [[ -n $n ]] && ns=(-n "$n");
  kubectl get pods "${ns[@]}"`.
- Arrays start at index 1.
- Inside a function `$0` is the function's name, not a file, so the
  "help from the header comment" trick from chapter 1 doesn't work. Print the
  usage from a here-doc instead.

These are good reasons to keep functions small.

## Tab completion

A completion makes options and values discoverable. With fzf-tab installed
(see the [README](../README.md#shell-plugins--tools)), the candidates even
show up in fzf. Put it in the feature's `completion.zsh`, which is loaded
after `compinit`:

```zsh
# packages/<tool>/completion.zsh
_fkill() {
    _arguments \
        '(-n --dry-run)'{-n,--dry-run}'[only show what would be signalled]' \
        '(-y --yes)'{-y,--yes}'[do not ask for confirmation]' \
        '(-s --signal)'{-s+,--signal=}'[signal to send]:signal:(TERM INT HUP KILL)' \
        '(-q --query)'{-q+,--query=}'[pre-fill the search]:query:' \
        '(- *)'{-h,--help}'[show help]'
}
compdef _fkill fkill

_pick_env() {
    _arguments '(-y --yes)'{-y,--yes}'[do not ask]' '1:environment:(dev staging prod)'
}
compdef _pick_env pick-env
```

- `'(-y --yes)'` lists options that exclude each other (no completing `--yes`
  after `-y`).
- `-s+` / `--signal=` means the option takes a value; `:signal:(A B C)`
  completes it from a fixed list. Use `:file:_files` for paths.
- `'1:environment:(...)'` completes the first positional argument.
- Guard tool-specific completions: `command -v fkill >/dev/null || return 0`.

## Testing

A picker can't be tested by pressing keys in CI, but almost everything around
it can. [`examples/test.sh`](examples/test.sh) shows how:

```sh
/bin/bash -n script                    # syntax with macOS's bash 3.2
shellcheck -S warning script           # common bugs (brew install shellcheck)
script --help                          # exit 0, prints Usage
script --bogus </dev/null              # exit 2
script arg </dev/null                  # argument path, no terminal
script </dev/null                      # must fail with 2, not hang
fkill -n -q "'sleep '31337" </dev/null # fzf --filter path, dry run
```

- `</dev/null` takes away the terminal, which is how CI, cron and IDEs run
  your command. If the test hangs, the command would hang there too.
- Use the `--filter` / dry-run paths to check matching logic without the UI
  and without side effects.
- Run `script/test-linux` (Docker) to check the Linux side, and `zsh -i -c
  'whence -w <name>'` to check that a new function or script is found.
- Finally, try it once by hand: cancel with Esc, pick nothing, pick several,
  resize the terminal.

## Checklist

Before calling a command done:

- [ ] `-h` / `--help` prints usage (what, options, output, exit codes)
- [ ] Result on stdout only; messages, prompts and menus on stderr
- [ ] Exit codes: 0 ok, 1 failure, 2 usage, 130 cancelled
- [ ] Options validated, tools checked **before** any picker opens
- [ ] Everything you can pick can also be passed as an argument or query
- [ ] No terminal + missing input → clear error, never a hang
- [ ] Esc in the picker → quiet exit 130
- [ ] `set +o pipefail` (or a snapshot) around `list | fzf`
- [ ] Hidden ID column for things users don't need to read; `{1}` in preview
- [ ] Destructive actions: show what happens, `[y/N]` confirm, `--yes`, `--dry-run`
- [ ] Colour only on a terminal, honours `NO_COLOR`
- [ ] Passes `/bin/bash -n` and shellcheck; tested with `</dev/null`
- [ ] Lives in the right feature folder, executable, documented in the README

---

Back to the [tutorial index](README.md).
