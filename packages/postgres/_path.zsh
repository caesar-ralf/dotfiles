# libpq (psql & friends) is keg-only in Homebrew, so add its bin explicitly.
# On Linux without Homebrew, apt's postgresql-client puts psql on PATH already.
[ -n "$BREW_PREFIX" ] && [ -d "$BREW_PREFIX/opt/libpq/bin" ] && export PATH="$BREW_PREFIX/opt/libpq/bin:$PATH"
