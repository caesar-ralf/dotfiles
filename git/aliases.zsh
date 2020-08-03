# Checkout branch based on jira ticket number
alias jira='git fetch && git checkout --track $(git branch -r | fzf)'
