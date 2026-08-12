cask_args appdir: '/Applications'

# =============================================================================
# Taps
# =============================================================================
tap 'homebrew/bundle'                          # lets `brew bundle` read this Brewfile

# =============================================================================
# Shell, prompt & completion
# =============================================================================
brew 'oh-my-posh'                              # cross-shell prompt theme engine (uses oh-my-posh/theme.omp.json)
brew 'zsh-autosuggestions'                     # fish-style inline suggestions from history
brew 'zsh-syntax-highlighting'                 # colours commands as you type (sourced last)
brew 'fzf'                                     # fuzzy finder (Ctrl-R history, Ctrl-T files)
brew 'grc'                                     # generic colouriser for command output
brew 'direnv'                                  # auto-load per-directory environment variables

# =============================================================================
# Modern CLI replacements & terminal utilities
# =============================================================================
brew 'coreutils'                               # GNU core utils (gls, gdate, …) used by aliases
brew 'bat'                                     # `cat` with syntax highlighting & git integration
brew 'eza'                                     # modern `ls` (git-aware, tree, colours)
brew 'fd'                                      # modern `find` (simpler syntax, fast)
brew 'ripgrep'                                 # modern `grep`/`ack` (rg) — very fast code search
brew 'ack'                                     # older grep-like source search (kept for habit)
brew 'zoxide'                                  # smarter `cd` with frecency (`z <partial>`)
brew 'ncdu'                                    # interactive disk-usage analyser (TUI)
brew 'htop'                                    # interactive process viewer
brew 'prettyping'                              # prettier `ping` output
brew 'tldr'                                    # simplified, example-driven man pages
brew 'wget'                                    # download files over HTTP/FTP
brew 'vim'                                     # terminal text editor ($EDITOR)

# =============================================================================
# Data wrangling
# =============================================================================
brew 'jq'                                      # command-line JSON processor
brew 'yq'                                      # command-line YAML/JSON/XML processor (jq for YAML)

# =============================================================================
# Git & version control
# =============================================================================
brew 'gh'                                      # GitHub CLI (PRs, issues, auth)
brew 'git-delta'                               # syntax-highlighting pager for git diffs (delta)
brew 'difftastic'                              # structural diff (gitconfig difftool = difft)
brew 'diff-so-fancy'                           # alternative human-friendly git diff formatting
brew 'spaceman-diff'                           # diff images from the terminal
brew 'lazygit'                                 # terminal UI for git
brew 'git-lfs'                                 # git Large File Storage
brew 'git-crypt'                               # transparent file encryption inside a git repo
brew 'git-filter-repo'                         # fast, safe git history rewriting

# =============================================================================
# Containers, Kubernetes & gRPC
# =============================================================================
brew 'docker'                                  # Docker CLI
brew 'kubectl'                                 # Kubernetes CLI
brew 'helm'                                    # Kubernetes package manager (charts)
brew 'k9s'                                     # terminal UI to manage Kubernetes clusters
brew 'kubectx'                                 # fast context (kubectx) + namespace (kubens) switching
brew 'stern'                                   # multi-pod Kubernetes log tailing (used by `klog -f`)
brew 'grpcurl'                                 # `curl` for gRPC services

# =============================================================================
# Cloud & HTTP
# =============================================================================
brew 'azure-cli'                               # Microsoft Azure command-line interface
brew 'httpie'                                  # user-friendly HTTP client (`http`)

# =============================================================================
# Languages, runtimes & version managers
# =============================================================================
brew 'go'                                      # Go toolchain
brew 'maven'                                   # Java build tool (project uses ./mvnw too)
brew 'pyenv'                                   # install & switch Python versions
brew 'rbenv'                                   # install & switch Ruby versions
brew 'ruby-build'                              # rbenv plugin that builds Ruby versions
brew 'nvm'                                     # Node.js version manager
brew 'yarn'                                    # JavaScript package manager
brew 'watchman'                                # file-watching service (used by JS tooling/tests)

# =============================================================================
# Native build dependencies (needed to compile other tools/gems)
# =============================================================================
brew 'pkg-config'                              # resolves compile/link flags for libraries
brew 'openssl'                                 # TLS/crypto toolkit & library
brew 'readline'                                # line-editing library
brew 'libgit2'                                 # C git library (bindings depend on it)
brew 'libpq'                                   # PostgreSQL client library (`psql`)
brew 'librsvg'                                 # SVG rendering library

# =============================================================================
# Security
# =============================================================================
brew 'gpg'                                     # GnuPG — encryption & signing

# =============================================================================
# Images & media
# =============================================================================
brew 'imagemagick'                             # image manipulation toolkit (convert, mogrify)
brew 'graphicsmagick'                          # faster ImageMagick fork
brew 'jp2a'                                    # convert JPEG images to ASCII art
brew 'spark'                                   # tiny sparkline bar graphs in the terminal

# =============================================================================
# History
# =============================================================================
brew 'atuin'                                   # SQLite-backed shell history with fuzzy search (opt-in)

# NOTE: fzf-tab (fzf-driven tab completion) is NOT in Homebrew core.
#       It is installed via fzf-tab/install.sh into ~/.zsh/fzf-tab.

# =============================================================================
# Fonts
# =============================================================================
cask 'font-fira-code-nerd-font'                # Nerd Font with glyphs/icons for the oh-my-posh prompt

# =============================================================================
# GUI applications (casks)
# =============================================================================
cask 'iterm2'                                  # terminal emulator
cask 'intellij-idea'                           # JetBrains Java/Kotlin IDE
cask 'rectangle'                               # keyboard-driven window snapping/management
cask 'alfred'                                  # Spotlight replacement: launcher & workflows
cask 'jumpcut'                                 # clipboard history menubar app
cask 'slack'                                   # team chat
cask 'discord'                                 # voice/text chat
cask 'telegram'                                # messaging
