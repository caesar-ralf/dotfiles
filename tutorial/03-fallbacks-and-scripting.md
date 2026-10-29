# 3. Without fzf, without a human

A picker is a convenience for a person at a keyboard. The same command will
also run from scripts, CI, cron, an IDE, over SSH, and on a machine without
fzf. In all of those it must still do something sensible, and it must never
sit waiting for input that won't come.

Example: [`pick-env.sh`](examples/pick-env.sh).

## Arguments first, picker second

Anything the user can pick, they can also pass:

```bash
env="${1:-}"
if [ -z "$env" ]; then
    is_interactive || usage_error "no ENVIRONMENT given and no terminal to ask"
    env="$(choose environment dev staging prod)" || exit $?
fi
is_valid "$env" || usage_error "unknown environment '$env'"
```

- `pick-env prod` is scriptable and quick to repeat from history.
- `pick-env` alone helps you when you don't remember the options.
- Validate the argument **and** the picked value the same way, after the
  `if`, so there's only one path to check.

For lists that are too long to type (processes, commits), offer a query
instead of an exact value and match it with `fzf --filter` (see `fkill -q`).

## Is anyone there?

```bash
is_interactive() { [ -t 0 ] && [ -t 2 ]; }
```

- `[ -t 0 ]`: stdin is a terminal, so someone can type.
- `[ -t 2 ]`: stderr is a terminal, so someone can see the prompt.
- **Don't test stdout** (`[ -t 1 ]`): inside `x="$(cmd)"` stdout is never a
  terminal, yet a human is right there. Testing it would break the main way
  pickers are used.

When nobody is there and input is missing, fail fast with exit 2 and say what
to pass. Don't block on a prompt, and don't silently pick a default for
anything that matters.

## Fallback when fzf is missing: `select`

bash has a numbered-menu builtin:

```bash
choose() {                                  # choose PROMPT OPTION...
    local prompt="$1"; shift
    if command -v fzf >/dev/null 2>&1; then
        printf '%s\n' "$@" | fzf --height 40% --layout reverse --prompt "$prompt> "
        return
    fi
    local PS3="$prompt (number, Ctrl-D to cancel): " opt
    select opt in "$@"; do
        if [ -n "$opt" ]; then printf '%s\n' "$opt"; return 0; fi
        printf 'not a valid number: %s\n' "$REPLY" >&2
    done
    return 130                              # Ctrl-D
}
```

```text
1) dev
2) staging
3) prod
environment (number, Ctrl-D to cancel): 3
```

- `select` prints the menu and `PS3` to **stderr** and reads from stdin, so
  `$(choose ...)` works the same as with fzf.
- An invalid entry leaves `opt` empty and the raw input in `$REPLY`; loop
  again rather than failing.
- Return the same exit codes as fzf (0 / 130) so callers don't care which
  one ran.
- `NO_FZF=1 tutorial/examples/pick-env.sh` shows it.

Worth a fallback for short fixed lists. For long dynamic lists (files,
processes), requiring fzf with a clear install hint is fine.

## Asking yes/no

```bash
confirm() {                                 # confirm QUESTION -> 0 = yes
    [ "$ASSUME_YES" = 1 ] && return 0
    if ! is_interactive; then
        printf '%s: %s -- no terminal to ask; pass --yes\n' "$PROG" "$1" >&2
        return 1
    fi
    local reply
    printf '%s [y/N] ' "$1" >&2
    read -r reply || return 1               # Ctrl-D = no
    case "$reply" in [yY]|[yY][eE][sS]) return 0 ;; *) return 1 ;; esac
}

confirm "Really use PROD?" || { echo "$PROG: cancelled" >&2; exit 1; }
```

- **Default No.** `[y/N]` shows it: the capital letter is the default. Enter
  means no.
- Without a terminal, **never assume yes.** Require `--yes`.
- Confirm only what is risky (prod, deleting, killing). A prompt on every run
  teaches people to type `y` without reading.
- Show *exactly* what will happen before asking: `fkill` lists the processes
  and the signal.
- Pair it with `--dry-run` so people can check first, and `--yes` so scripts
  can skip the prompt.

Other prompts:

```bash
read -r -p 'Name: ' name                    # prompt on stderr, only shown on a terminal
read -r -p "Port [8080]: " port; port="${port:-8080}"   # default in brackets
read -r -s -p 'Token: ' token; echo >&2     # -s: no echo, for secrets
```

In these dotfiles, `confirm` from `script/lib/common.sh` does the same for
the `script/*` tools.

## Colour

```bash
if [ -t 2 ] && [ -z "${NO_COLOR:-}" ]; then
    C_WARN="$(printf '\033[0;33m')"; C_RST="$(printf '\033[0m')"
else
    C_WARN=""; C_RST=""
fi
printf '%swarning:%s %s\n' "$C_WARN" "$C_RST" "$msg" >&2
```

- Only colour the stream you are checking (stderr here). Never put escape
  codes in stdout data.
- Respect [`NO_COLOR`](https://no-color.org).
- Colour adds meaning (warning, success); it isn't decoration. The text must
  still make sense without it.

---

Next: [4. Shipping it in these dotfiles](04-shipping-it.md)
