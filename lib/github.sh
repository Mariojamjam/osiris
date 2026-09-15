#!/usr/bin/env bash

authenticated_user() {
    gh api user --jq .login
}

require_authentication() {
    if ! gh auth status -h github.com >/dev/null 2>&1; then
        osiris_error "GitHub authentication is missing or invalid. Run: osiris --auth"
    fi
}
