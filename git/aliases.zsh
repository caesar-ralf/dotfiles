# Git plus fzf helpers. Everything guards on its tools so a fresh machine still boots.

if command -v git >/dev/null 2>&1 && command -v fzf >/dev/null 2>&1; then

  # gco: fuzzy switch a LOCAL branch. Preview its latest commit, Enter to switch.
  gco() {
    git branch --sort=-committerdate --format='%(refname:short)' \
      | fzf --height 40% --layout reverse \
            --preview 'git show --color=always {}' \
            --bind 'enter:become(git switch {})'
  }

  # gcoa: like gco, but also lists REMOTE branches. Auto tracks new ones.
  gcoa() {
    git branch -a --sort=-committerdate --format='%(refname:short)' \
      | sed 's#^origin/##' | grep -vx 'HEAD' | sort -u \
      | fzf --height 40% --layout reverse \
            --preview 'git show --color=always {}' \
            --bind 'enter:become(git switch {})'
  }

  # jira: fetch, then fuzzy checkout a REMOTE branch. The Jira ticket workflow.
  jira() {
    git fetch --quiet
    git branch -r --format='%(refname:short)' | grep -v '^origin/HEAD' \
      | fzf --height 40% --layout reverse \
            --preview 'git show --color=always {}' \
            --bind 'enter:become(git switch $(echo {} | sed "s#^origin/##"))'
  }

  # gbd: fuzzy delete local branches. TAB to multi select, with a diff preview.
  gbd() {
    local branches
    branches=$(git branch --sort=-committerdate --format='%(refname:short)' \
      | fzf --multi --height 40% --layout reverse \
            --preview 'git show --color=always {}') || return
    [ -n "$branches" ] && echo "$branches" | xargs git branch -D
  }

  # glog: browse history. Preview each commit, Enter to open it, C-y to copy sha.
  glog() {
    git log --color=always --format='%C(auto)%h %s %C(dim white)· %an, %ar%C(reset)' \
      | fzf --ansi --no-sort --height 80% --layout reverse \
            --preview 'git show --color=always {1}' \
            --bind 'enter:become(git show --color=always {1} | less -R)' \
            --bind 'ctrl-y:execute-silent(printf %s {1} | pbcopy)'
  }

  # gstash: manage stashes. Preview, then apply, pop or drop with a keystroke.
  gstash() {
    git stash list \
      | fzf --height 40% --layout reverse --delimiter=: \
            --header 'enter: view   C-a: apply   C-p: pop   C-d: drop' \
            --preview 'git stash show -p --color=always {1}' \
            --bind 'enter:become(git stash show -p --color=always {1} | less -R)' \
            --bind 'ctrl-a:become(git stash apply {1})' \
            --bind 'ctrl-p:become(git stash pop {1})' \
            --bind 'ctrl-d:reload(git stash drop {1} >/dev/null 2>&1; git stash list)'
  }

  # gfixup: pick a commit to fixup, then autosquash rebase onto it.
  gfixup() {
    local sha
    sha=$(git log --color=always --format='%C(auto)%h %s' \
      | fzf --ansi --no-sort --height 40% --layout reverse \
            --preview 'git show --color=always {1}') || return
    [ -z "$sha" ] && return
    sha=${sha%% *}
    git commit --fixup "$sha" && git rebase -i --autosquash "$sha~1"
  }
fi
