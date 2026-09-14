#!/usr/bin/env bash

set -Eeuo pipefail

INSTALL_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/osiris"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
PROFILE_FILE="$HOME/.profile"
PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'

rm -f "$BIN_DIR/osiris"
rm -rf "$INSTALL_ROOT"

if [[ -f "$PROFILE_FILE" ]]; then
    sed -i '/^# Osiris user-local commands$/,+1d' "$PROFILE_FILE"
fi

printf 'Osiris was uninstalled. GitHub CLI and its credentials were preserved.\n'
