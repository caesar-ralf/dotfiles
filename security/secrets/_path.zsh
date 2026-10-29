# `secret` and `with-secrets` (Proton Pass + Keychain cache). See security/secrets/lib.sh.
export PATH="$DOTFILES/security/secrets/bin:$PATH"

# Older versions of these dotfiles defined `secret`/`secret-set` as zsh
# functions (silent Keychain lookups). A function shadows the command in
# security/secrets/bin, so drop any leftover from a shell that predates the change.
(( $+functions[secret] )) && unfunction secret
(( $+functions[secret-set] )) && unfunction secret-set
rehash
