# Docker shortcuts.
alias docker-rmi-dangling='docker rmi $(docker images -q -f dangling=true)'
alias docker-clean='docker rm -f $(docker ps -aq); docker-rmi-dangling'
