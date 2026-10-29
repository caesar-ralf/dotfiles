# Tutorial: interactive shell commands that are good to use

How to write small bash commands that **let you pick things** (files, commits,
processes, pods, environments) with a fuzzy finder, and still behave well
in scripts, pipes and CI.

The examples are real, runnable scripts in [`examples/`](examples). Every
chapter builds on the previous one. The last example, `fkill`, combines all
of them.

| Chapter | You learn |
|---------|-----------|
| [1. Anatomy of a good command](01-anatomy.md) | Help text, options, exit codes, stdout vs stderr, dry run, cleanup, macOS/Linux portability |
| [2. Selection with fzf](02-selection-with-fzf.md) | Pickers, exit codes, hidden key columns, previews, multi-select, key bindings, `--filter` |
| [3. Without fzf, without a human](03-fallbacks-and-scripting.md) | Arguments instead of pickers, detecting a terminal, `select` menus, confirmations, colours |
| [4. Shipping it in these dotfiles](04-shipping-it.md) | Function or script, where the file goes, zsh completion, testing, checklist |

## The examples

| Script | Shows |
|--------|-------|
| [`skeleton.sh`](examples/skeleton.sh) | Template: help from the header comment, option parsing, `--dry-run`, exit codes |
| [`pick-basic.sh`](examples/pick-basic.sh) | The smallest correct fzf picker (file chooser) |
| [`pick-commits.sh`](examples/pick-commits.sh) | Hidden columns, preview, multi-select, one action per key (`--expect`) |
| [`pick-env.sh`](examples/pick-env.sh) | Argument or picker, `select` fallback without fzf, confirmation before `prod` |
| [`fkill.sh`](examples/fkill.sh) | Everything together: pick processes and signal them, also usable from scripts |
| [`test.sh`](examples/test.sh) | How to test all of the above without a terminal |

Try them from the repo root:

```sh
tutorial/examples/pick-basic.sh            # pick a file
tutorial/examples/pick-commits.sh          # browse this repo's history
NO_FZF=1 tutorial/examples/pick-env.sh     # the menu you get without fzf
tutorial/examples/fkill.sh -n              # pick processes; -n = only show, never signal
tutorial/examples/test.sh                  # the non-interactive checks
```

Requirements: bash (macOS's `/bin/bash` 3.2 is enough), `fzf`, and `git` for
`pick-commits`. All of them are in the [Brewfile](../Brewfile). Optional: `fd`
(faster file listing) and `shellcheck` (lint, used by `test.sh` when present).

## The rules on one page

1. **Result on stdout, everything else on stderr.** Then `$(cmd)`, pipes and
   `| pbcopy` just work, even with a picker in the middle.
2. **The picker is a shortcut, not the only way in.** Whatever you can pick,
   you can also pass as an argument.
3. **Never hang without a terminal.** No TTY and nothing to go on: fail with
   a clear message and exit code 2.
4. **Cancel is not an error message.** Esc/Ctrl-C in fzf → quiet exit 130.
5. **Dangerous means confirm, default No,** with `--yes` for scripts and
   `--dry-run` to look first.
6. **`-h` always works,** and the help comes from one place.
7. **Runs on macOS bash 3.2 and Linux bash 5.** Test with `/bin/bash`.

> This folder is documentation only. It is not a feature: nothing in it is
> sourced, autoloaded, linked or installed. To turn an example into a real
> command, see [chapter 4](04-shipping-it.md).
