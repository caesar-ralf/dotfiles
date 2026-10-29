# Java tooling shortcuts (JDKs via SDKMAN: _path.zsh; Maven: packages/maven).
if [ "$DOTFILES_OS" = macos ]; then
  alias intellij='open -a "IntelliJ IDEA"'
elif (( $+commands[idea] )); then
  alias intellij='idea'                    # JetBrains Toolbox / snap launcher on Linux
elif (( $+commands[intellij-idea-ultimate] )); then
  alias intellij='intellij-idea-ultimate'
fi
alias gw=./gradlew
