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
alias du='ncdu --color dark -rr -x --exclude .git --exclude node_modules'
alias help='tldr'
alias ping='prettyping --nolegend'
alias preview="fzf --preview 'bat --color \"always\" {}'"

# add support for ctrl+o to open selected file in VS Code
export FZF_DEFAULT_OPTS="--bind='ctrl-o:execute(code {})+abort'"
alias top='sudo htop'

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

# mvn wrapper
alias mw='./mvnw'

# goto
alias goto='cd -P'

