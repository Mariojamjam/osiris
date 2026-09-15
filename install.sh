#!/usr/bin/env bash

set -Eeuo pipefail

OSIRIS_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/osiris"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
PROFILE_FILE="$HOME/.profile"
printf -v PATH_LINE 'export PATH="%s:$PATH"' "$BIN_DIR"

log() {
    printf '[osiris] %s\n' "$1"
}

fail() {
    printf '[osiris] Error: %s\n' "$1" >&2
    exit 1
}

install_gh() {
    if command -v gh >/dev/null 2>&1; then
        log "GitHub CLI is already installed: $(gh --version | head -n 1)"
        return
    fi

    log "GitHub CLI is not installed. Attempting installation."
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y gh
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y gh
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Sy --needed --noconfirm github-cli
    elif command -v brew >/dev/null 2>&1; then
        brew install gh
    else
        fail "No supported package manager was found. Install GitHub CLI manually: https://cli.github.com/"
    fi

    command -v gh >/dev/null 2>&1 || fail "GitHub CLI installation did not complete."
}

install_fzf() {
    if command -v fzf >/dev/null 2>&1; then
        log "fzf is already installed: $(fzf --version | head -n 1)"
        return
    fi

    log "fzf is not installed. Attempting installation."
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y fzf
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y fzf
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Sy --needed --noconfirm fzf
    elif command -v brew >/dev/null 2>&1; then
        brew install fzf
    else
        fail "No supported package manager was found. Install fzf manually: https://github.com/junegunn/fzf"
    fi

    command -v fzf >/dev/null 2>&1 || fail "fzf installation did not complete."
}

install_osiris() {
    mkdir -p "$INSTALL_ROOT/bin" "$INSTALL_ROOT/lib" "$BIN_DIR"
    cp "$OSIRIS_ROOT/lib/osiris.sh" "$INSTALL_ROOT/lib/osiris.sh"
    cp "$OSIRIS_ROOT/lib/tui.sh" "$INSTALL_ROOT/lib/tui.sh"
    cp "$OSIRIS_ROOT/lib/tui-page.sh" "$INSTALL_ROOT/lib/tui-page.sh"
    cp "$OSIRIS_ROOT/lib/create.sh" "$INSTALL_ROOT/lib/create.sh"
    cp "$OSIRIS_ROOT/lib/create-header.sh" "$INSTALL_ROOT/lib/create-header.sh"
    cp "$OSIRIS_ROOT/bin/osiris" "$INSTALL_ROOT/bin/osiris"
    chmod 755 "$INSTALL_ROOT/bin/osiris" "$INSTALL_ROOT/lib/osiris.sh" "$INSTALL_ROOT/lib/tui.sh" "$INSTALL_ROOT/lib/tui-page.sh" "$INSTALL_ROOT/lib/create.sh" "$INSTALL_ROOT/lib/create-header.sh"
    ln -sfn "$INSTALL_ROOT/bin/osiris" "$BIN_DIR/osiris"

    touch "$PROFILE_FILE"
    if ! grep -Fqx "$PATH_LINE" "$PROFILE_FILE"; then
        printf '\n# Osiris user-local commands\n%s\n' "$PATH_LINE" >> "$PROFILE_FILE"
    fi
}

authenticate() {
    if gh auth status -h github.com >/dev/null 2>&1; then
        log "GitHub authentication is already valid."
    else
        log "GitHub authentication is required. Opening the browser login flow."
        gh auth login -h github.com -p https --web
    fi
}

install_gh
install_fzf
install_osiris
authenticate

log "Installation completed."
log "Open a new shell or run: source ~/.profile"
log "Then use: osiris"
