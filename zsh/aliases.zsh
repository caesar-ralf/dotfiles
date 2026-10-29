alias reload!='. ~/.zshrc'
alias cls='clear' # Good 'ol Clear Screen command

alias g='git'

# docker aliases
alias docker-rmi-dangling='docker rmi $(docker images -q -f dangling=true)'
alias docker-clean='docker rm -f $(docker ps -aq); docker-rmi-dangling'

# code aliases
if [ "$DOTFILES_OS" = macos ]; then
  alias intellij='open -a "IntelliJ IDEA"'
elif (( $+commands[idea] )); then
  alias intellij='idea'                    # JetBrains Toolbox / snap launcher on Linux
elif (( $+commands[intellij-idea-ultimate] )); then
  alias intellij='intellij-idea-ultimate'
fi
alias gw=./gradlew

# maven aliases live in m2.symlink/maven.zsh

# kubernetes shortcuts
alias k='kubectl'
alias kgp='kubectl get pods'
alias kga='kubectl get all'
alias kl='kubectl logs'
alias kns='kubectl config set-context --current --namespace' # kns <namespace>
command -v kubectx >/dev/null 2>&1 && alias kx='kubectx'
command -v kubens  >/dev/null 2>&1 && alias kn='kubens'

# tool replacing
# dust (https://github.com/bootandy/dust): a fast, tree view `du`.
command -v dust >/dev/null 2>&1 && alias du="dust -X .git -X node_modules"
alias help='tldr'
alias ping='prettyping --nolegend'
alias preview="fzf --preview 'bat --color \"always\" {}'"

# modern CLI replacements
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first --icons=auto'
  alias l='eza -lah --group-directories-first --git --icons=auto'
  alias ll='eza -l --group-directories-first --git --icons=auto'
  alias la='eza -a --group-directories-first --icons=auto'
  alias lt='eza --tree --level=2 --icons=auto'
fi
command -v bat      >/dev/null 2>&1 && alias catp='bat --paging=never'
# ripgrep (rg): recursive, gitignore aware, very fast. Replaces grep and ack.
command -v rg       >/dev/null 2>&1 && alias grep='rg'    # rg <pattern> [path]
command -v rg       >/dev/null 2>&1 && alias ack='rg'     # keep muscle memory, better engine
command -v lazygit  >/dev/null 2>&1 && alias lg='lazygit'

# add support for ctrl+o to open selected file in VS Code
export FZF_DEFAULT_OPTS="--bind='ctrl-o:execute(code {})+abort'"
alias top='sudo btop'

# dir aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'
alias d='dirs -v | head -10'
alias 1='cd -'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'

# remove dir
alias yeet='rm -rf'

# polite
alias please='sudo'


# goto
alias goto='cd -P'
