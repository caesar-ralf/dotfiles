alias reload!='. ~/.zshrc'
alias cls='clear' # Good 'ol Clear Screen command

# docker aliases
alias docker-rmi-dangling='docker rmi $(docker images -q -f dangling=true)'
alias docker-clean='docker rm -f $(docker ps -aq); docker-rmi-dangling'
alias docker-remote-images="curl -s 'https://hub.int.klarna.net/v2/_catalog?n=1000' | jq ."

# code aliases
alias intellij='open -a "IntelliJ IDEA"'
alias gw=./gradlew

# tool replacing
alias cat='bat --show-all'
alias du='ncdu --color dark -rr -x --exclude .git --exclude node_modules'
alias help='tldr'
alias ping='prettyping --nolegend'
alias preview="fzf --preview 'bat --color \"always\" {}'"
# add support for ctrl+o to open selected file in VS Code
export FZF_DEFAULT_OPTS="--bind='ctrl-o:execute(code {})+abort'"
alias top='sudo htop'
