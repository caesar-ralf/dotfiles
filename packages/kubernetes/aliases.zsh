# Kubernetes shortcuts (k9s completion: completion.zsh, log tailing: klog).
alias k='kubectl'
alias kgp='kubectl get pods'
alias kga='kubectl get all'
alias kl='kubectl logs'
alias kns='kubectl config set-context --current --namespace' # kns <namespace>
command -v kubectx >/dev/null 2>&1 && alias kx='kubectx'
command -v kubens  >/dev/null 2>&1 && alias kn='kubens'
