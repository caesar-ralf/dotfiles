#!/bin/sh
#
# iTerm2 — install the Dotfiles profile and make it the active default.
#
# Installing the font (via the Brewfile cask) is NOT enough: iTerm2 has to be
# told to *use* it, which is a per-profile setting. This installer ships a
# dynamic profile (Nerd Font + Night Owl colours matching the oh-my-posh theme)
# and sets it as the default profile so a fresh machine works out of the box.
#
# Dynamic profiles are non-destructive: they ADD a profile and never overwrite
# your existing ones. Your previous default profile GUID is saved once, so the
# change is reversible. To keep your own default, export DOTFILES_ITERM_DEFAULT=0.

# macOS only.
[ "$(uname -s)" = "Darwin" ] || exit 0

__dir="$(cd "$(dirname "$0")" && pwd -P)"
PROFILE_SRC="${__dir}/DotfilesProfile.json"
DEST_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
GUID="org.dotfiles.iterm.firacode"

# 1. Install (symlink) the dynamic profile. iTerm2 picks it up automatically.
mkdir -p "$DEST_DIR"
ln -sf "$PROFILE_SRC" "$DEST_DIR/DotfilesProfile.json"
echo "  Installed iTerm2 dynamic profile 'Dotfiles (FiraCode Nerd Font)'."

# 1b. Sanity-check the font. iTerm needs the exact PostScript name (e.g.
#     'FiraCodeNFM-Reg'), NOT the filename. If it can't resolve it, iTerm
#     silently falls back to Menlo — so verify and warn loudly if it drifts.
EXPECTED_PS="FiraCodeNFM-Reg"
FONT_TTF="$HOME/Library/Fonts/FiraCodeNerdFontMono-Regular.ttf"
if [ -f "$FONT_TTF" ]; then
    actual_ps="$(mdls -name com_apple_ats_name_postscript "$FONT_TTF" 2>/dev/null | sed -n 's/.*"\(.*\)".*/\1/p' | head -1)"
    if [ -n "$actual_ps" ] && [ "$actual_ps" != "$EXPECTED_PS" ]; then
        echo "  WARNING: font PostScript name is '$actual_ps', but the profile expects"
        echo "           '$EXPECTED_PS'. Update iterm/DotfilesProfile.json's 'Normal Font'"
        echo "           to '$actual_ps <size>' or iTerm will fall back to Menlo."
    fi
else
    echo "  WARNING: FiraCode Nerd Font not found. Run 'brew bundle' (font-fira-code-nerd-font)"
    echo "           or iTerm will fall back to Menlo."
fi

# 2. Make it the default profile (unless the user opted out).
if [ "${DOTFILES_ITERM_DEFAULT:-1}" != "0" ]; then
    STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
    BACKUP="$STATE_DIR/iterm-previous-default-guid"
    mkdir -p "$STATE_DIR"

    current="$(defaults read com.googlecode.iterm2 'Default Bookmark Guid' 2>/dev/null || true)"

    # Back up the very first non-ours default we ever see, so it's recoverable.
    if [ ! -f "$BACKUP" ] && [ -n "$current" ] && [ "$current" != "$GUID" ]; then
        printf '%s\n' "$current" > "$BACKUP"
    fi

    if [ "$current" != "$GUID" ]; then
        defaults write com.googlecode.iterm2 'Default Bookmark Guid' -string "$GUID"
        echo "  Set 'Dotfiles (FiraCode Nerd Font)' as the default iTerm2 profile."
    else
        echo "  'Dotfiles (FiraCode Nerd Font)' is already the default profile."
    fi

    # iTerm2 rewrites its prefs on quit, which can revert a live `defaults write`.
    if pgrep -x iTerm2 >/dev/null 2>&1; then
        echo "  NOTE: iTerm2 is running — fully quit it (Cmd-Q) and reopen so the"
        echo "        new default profile and colours take effect."
    fi
else
    echo "  DOTFILES_ITERM_DEFAULT=0 — leaving your default profile untouched."
    echo "  Select 'Dotfiles (FiraCode Nerd Font)' manually in iTerm2 > Settings > Profiles."
fi

exit 0
