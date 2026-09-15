#!/usr/bin/env bash

require_gh() {
    if ! command -v gh >/dev/null 2>&1; then
        osiris_error "GitHub CLI (gh) is not installed. Run the Osiris installer first."
    fi
}

require_fzf() {
    if ! command -v fzf >/dev/null 2>&1; then
        osiris_error "fzf is not installed. Run the Osiris installer first."
    fi
}
