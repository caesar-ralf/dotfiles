# 1. Anatomy of a good command

A command is good when you can use it without reading its source: it explains
itself, fails clearly, and fits into pipes. Everything in this chapter is in
[`examples/skeleton.sh`](examples/skeleton.sh). Copy that file to start a new
command.

## Shebang and strict mode

```bash
#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
```

- `#!/usr/bin/env bash` finds the first bash on `PATH` (Homebrew's bash 5 or
  macOS's `/bin/bash` 3.2). Write code that works on both.
- `errexit` stops at the first failing command, `nounset` turns typos in
  variable names into errors, and `pipefail` makes a pipeline fail when any
  part of it fails.

Know their limits:

- `errexit` is ignored inside `if`, `while`, `&&` and `||` conditions, and in
  functions called from them. Check important results yourself.
- `pipefail` causes false failures with pickers: when `fzf` or `head` exits
  early, the command that feeds it gets `SIGPIPE` (exit 141). See
  [chapter 2](02-selection-with-fzf.md#the-sigpipe-trap).
- `nounset` in bash < 4.4 treats an **empty array** as unset:
  `"${files[@]}"` fails. Use `${files[@]+"${files[@]}"}`.
- Optional variables need a default: `${1:-}`, `${EDITOR:-vi}`.

## The header comment is the help text

Write the usage once, as the comment at the top of the file, and print it for
`-h`/`--help`:

```bash
#!/usr/bin/env bash
#
# skeleton -- copy each FILE to FILE.bak.
#
# Usage: skeleton [-n] [-v] [-d DIR] FILE...
#
#   -n, --dry-run   show what would happen, change nothing
#   ...
# Exit codes: 0 ok, 1 runtime error, 2 usage error.

usage() { awk 'NR > 2 { if (!/^#/) exit; sub(/^# ?/, ""); print }' "$0"; }
```

The `awk` prints every comment line after the shebang, up to the first
non-comment line. Readers of the source and users of `--help` see the same
text, so they can't drift apart.

A good help text has: one line saying what the command does, a `Usage:` line
(`[optional]`, `REQUIRED`, `...` = repeatable), every option, what goes to
stdout, and the exit codes.

## stdout is for data, stderr is for humans

This rule matters more than any other, and pickers depend on it.

| Goes to **stdout** | Goes to **stderr** |
|--------------------|--------------------|
| The result: a path, an ID, a list | Progress, `--verbose` logs |
| Nothing else | Prompts, menus, confirmations |
| | Warnings and errors |

With that split, all of these work:

```sh
vim "$(pick-basic)"                       # result becomes an argument
pick-commits | xargs git show             # result becomes input
copies="$(skeleton -v *.conf)"            # logs still visible, not captured
```

Small helpers keep it consistent:

```bash
PROG="${0##*/}"
die()         { printf '%s: %s\n' "$PROG" "$*" >&2; exit 1; }
usage_error() { printf '%s: %s\nTry "%s --help".\n' "$PROG" "$*" "$PROG" >&2; exit 2; }
```

Prefix messages with the program name: inside a pipeline of five commands,
`skeleton: no such file: x` tells you who complained.

## Exit codes

| Code | Meaning | Example |
|------|---------|---------|
| `0` | success | |
| `1` | runtime failure | file missing, nothing matched, user said "no" |
| `2` | usage error | unknown option, missing argument |
| `130` | cancelled by the user | Esc / Ctrl-C in fzf (128 + SIGINT) |

Callers branch on these (`if pick-env; then`), so be consistent. When you
process several items, keep going after one failure and return non-zero at
the end, like `cp` and `rm` do (see `main()` in `skeleton.sh`).

## Parsing options

Use a `while`/`case` loop. It handles short and long options, works in bash
3.2, and is easy to read:

```bash
DRY_RUN=0 DEST_DIR=""
while [ $# -gt 0 ]; do
    case "$1" in
        -n|--dry-run) DRY_RUN=1 ;;
        -d|--dir)
            [ $# -ge 2 ] || usage_error "$1 needs an argument"
            DEST_DIR="$2"; shift ;;
        --dir=*)      DEST_DIR="${1#*=}" ;;
        -h|--help)    usage; exit 0 ;;
        --)           shift; break ;;
        -?*)          usage_error "unknown option: $1" ;;
        *)            break ;;
    esac
    shift
done
# "$@" now holds only the positional arguments
```

- `getopts` has no long options. `getopt` behaves differently on macOS (BSD)
  and Linux (GNU). Avoid both.
- Options must come before arguments, and `--` ends the options, so a file
  named `-x` can still be passed. Combined short flags (`-nv`) aren't
  supported; that's an acceptable trade for simple code.
- **Validate everything before doing any work**, especially before opening a
  picker: a typo shouldn't cost the user a selection round.
- Check required tools up front, with a hint on how to install them:
  `command -v fzf >/dev/null 2>&1 || die "fzf is required (brew install fzf)"`.

## Quoting and safe defaults

- Quote every expansion: `"$file"`, `"$@"`. Unquoted variables split on
  spaces and expand globs.
- `printf '%s\n' "$x"` instead of `echo "$x"`: `echo` treats `-n` or `-e` in
  the data as options, and handles backslashes differently between shells.
- Pass `--` to commands that take file names: `cp -p -- "$file" "$dest"`,
  `rm -- "$f"`.
- `read -r` (no backslash mangling); `while IFS= read -r line` for whole lines.

## Dry run, verbose, cleanup

Anything that changes state should support `--dry-run`. A `run` helper keeps
that in one place:

```bash
run() {
    if [ "$DRY_RUN" = 1 ]; then
        printf 'would run:' >&2; printf ' %q' "$@" >&2; printf '\n' >&2
    else
        "$@"
    fi
}
run cp -p -- "$file" "$dest"
```

`%q` prints arguments shell-quoted, so you see exactly what would run.

Temporary files go into one directory that a trap always removes:

```bash
TMP="$(mktemp -d "${TMPDIR:-/tmp}/$PROG.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
```

## macOS and Linux

These dotfiles must work with **macOS bash 3.2 + BSD tools** and **Linux bash
5 + GNU tools** ([AGENTS.md](../AGENTS.md#coding-conventions) has the full
list). The ones you'll hit in commands like these:

| Avoid | Use instead |
|-------|-------------|
| `mapfile`, `readarray` | `while IFS= read -r line; do ...; done` |
| `declare -A` (associative arrays) | a `case` statement, or `key=value` lines + `awk` |
| `${var,,}`, `${var^^}` | `tr '[:upper:]' '[:lower:]'` |
| `sed -i` | `sed -i.bak ... && rm file.bak` |
| `readlink -f` | `cd "$(dirname "$f")" && pwd -P` |
| `grep -P` | `grep -E` |
| `date -d` / `date -v` | arithmetic on `date +%s` |

`/bin/bash -n script` checks syntax with macOS's old bash. Run it.

---

Next: [2. Selection with fzf](02-selection-with-fzf.md)
