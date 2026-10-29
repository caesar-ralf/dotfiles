# 2. Selection with fzf

[fzf](https://github.com/junegunn/fzf) turns any list into a fuzzy picker.
The model is simple: **lines in on stdin, chosen lines out on stdout.** The
UI is drawn on the terminal (`/dev/tty`), not on stdout, so a picker works
inside `$(...)` and in the middle of a pipe.

Examples: [`pick-basic.sh`](examples/pick-basic.sh),
[`pick-commits.sh`](examples/pick-commits.sh). Real ones in this repo:
`dsh` ([packages/docker/functions](../packages/docker/functions/dsh)),
`klog` ([packages/kubernetes/functions](../packages/kubernetes/functions/klog)),
the git helpers in [git/aliases.zsh](../git/aliases.zsh) (`gco`, `gbd`,
`glog`, `gfixup`, ...) and the pickers in `secret add`.

## The smallest correct picker

```bash
rc=0
choice="$(set +o pipefail
          list_files | fzf --height 40% --layout reverse --prompt 'file> ')" || rc=$?

case "$rc" in
    0)   printf '%s\n' "$choice" ;;
    1)   die "no match" ;;
    130) exit 130 ;;            # Esc / Ctrl-C: the user changed their mind
    *)   die "fzf failed (exit $rc)" ;;
esac
```

fzf's exit codes:

| Code | Meaning |
|------|---------|
| `0` | something was selected |
| `1` | no match (the list was empty, or nothing matched the query) |
| `2` | error (e.g. bad option) |
| `130` | cancelled with Esc or Ctrl-C |

Always handle cancel separately. `[ -z "$choice" ] && return 1` (common, and
what the older functions here do) works, but it can't tell "cancelled" from
"nothing to pick", and the caller can't either.

### The SIGPIPE trap

With `set -o pipefail`, `list | fzf` can fail even when the user picked
something: fzf exits as soon as you press Enter, `list` is still writing,
gets `SIGPIPE`, and exits 141. pipefail reports that 141 instead of fzf's 0.
It only happens with long or slow lists, so it's easy to miss in testing.

Fix: turn pipefail off **inside** the command substitution. The substitution
is a subshell, so the rest of the script keeps it:

```bash
choice="$(set +o pipefail; list | fzf ...)" || rc=$?
```

Another fix is to collect the list first (`items="$(list)"`, then
`printf '%s\n' "$items" | fzf`). That's also what you need when the list must
be a snapshot (see `fkill.sh`).

## Good defaults

```bash
fzf --height 40% --layout reverse --prompt 'thing> '
```

- `--height 40%` opens below the prompt instead of clearing the screen, so
  the user keeps their context. Use `80%` when there's a preview.
- `--layout reverse` puts the search box at the top, next to where you were
  typing.
- `--prompt 'pod> '` says what is being picked.
- `--border` helps when a preview or header is shown.
- Don't set colours or key bindings that the user may have configured in
  `FZF_DEFAULT_OPTS`. fzf applies those automatically.

## Start with a query

```bash
fzf --query "${1:-}" --select-1 --exit-0
```

- `--query` pre-fills the search box: `pick-basic readme`.
- `--select-1` (`-1`) picks immediately, without UI, when exactly one line
  matches.
- `--exit-0` (`-0`) exits with 1 immediately when nothing matches.

Together they make `cmd partial-name` behave like a normal command when the
answer is obvious, and like a picker when it isn't.

## Show one thing, return another

Lists often need an ID that the user doesn't care about (a hash, a PID, a
pod's namespace). Put the ID in its own field and hide it:

```bash
git log --format='%h%x09%cr%x09%s' \
  | fzf --delimiter "$(printf '\t')" --with-nth 2,3 \
        --preview 'git show --stat --color=always {1}'
```

- `--delimiter` sets the field separator. Tab is the safest, since it
  rarely appears in data. The default is whitespace.
- `--with-nth 2,3` displays (and searches) only fields 2 and 3.
- `{1}` in `--preview`/`--bind` commands is field 1 of the current line,
  shell-quoted by fzf.
- fzf **returns the whole original line**, hidden fields included. Cut the
  ID out yourself: `cut -f1` (tab) or `awk '{print $1}'` (whitespace). fzf
  0.60+ has `--accept-nth 1` for this, but `cut` also works with older fzf
  (Ubuntu's apt package).

For command output with a header row (`ps`, `kubectl get`, `docker ps`), use
`--header-lines 1`: the first line stays visible as a header and can't be
selected.

## Preview

```bash
--preview 'git show --stat --color=always {1}' \
--preview-window 'right,60%,wrap' \
--bind '?:toggle-preview'
```

- Placeholders: `{}` = the whole line, `{1}`, `{2..}` = fields, `{q}` = the
  query, `{+}` = all marked lines.
- The preview runs on every cursor move. Keep it fast; for files use `bat
  --color=always` when available and `head -100` otherwise.
- Force colour (`--color=always`). The preview isn't a terminal, so tools
  turn colour off by default.
- `--preview-window 'down,5'` suits short details, `right,60%` long text.
  Bind a key to toggle it on small screens.

## Several at once

```bash
--multi    # Tab / Shift-Tab mark or unmark and move; Enter returns all marked lines
```

Read the result line by line, never as words, since lines can contain spaces:

```bash
printf '%s\n' "$selected" | while IFS= read -r line; do ...; done
```

For file names that may contain newlines, go fully NUL-separated:
`find . -print0 | fzf --read0 --print0 --multi | xargs -0 ...`.

## One picker, several actions

`--expect` lets different keys finish the picker; the first output line is
the key (empty for Enter):

```bash
out="$(... | fzf --multi --expect 'ctrl-y,ctrl-s')"
key="$(printf '%s\n' "$out" | sed -n 1p)"
items="$(printf '%s\n' "$out" | sed 1d)"
case "$key" in
    ctrl-y) printf '%s\n' "$items" | pbcopy ;;
    ctrl-s) ...show... ;;
    *)      printf '%s\n' "$items" ;;       # Enter
esac
```

Put the keys in `--header` so people find them. Other bindings worth knowing:

| Binding | Use |
|---------|-----|
| `--bind 'ctrl-r:reload(cmd)'` | refresh the list (pods, processes) without restarting |
| `--bind 'ctrl-o:execute(vim {})'` | run something and come back to the picker |
| `--bind 'enter:become(vim {})'` | replace fzf with a command (fzf 0.38+) |
| `--bind 'change:reload(cmd {q})'` | search on the server side as you type (e.g. `rg {q}`) |

Prefer `--expect` in scripts: your script stays in control, and the action
code is normal bash rather than a string inside an option.

## fzf without a UI: `--filter`

```bash
printf '%s\n' "$items" | fzf --filter "$query"
```

`--filter` prints every line that matches the query, ranked, and exits. There
is no UI and no terminal is needed. Use it for:

- a **non-interactive mode** with the same matching rules (`fkill -q QUERY`
  in a script),
- **tests** ([`examples/test.sh`](examples/test.sh)).

Query syntax works there and in the UI: `'exact`, `^prefix`, `suffix$`,
`!exclude`, `a | b` (or), spaces = AND.

---

Next: [3. Without fzf, without a human](03-fallbacks-and-scripting.md)
