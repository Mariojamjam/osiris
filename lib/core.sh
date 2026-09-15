#!/usr/bin/env bash

OSIRIS_VERSION="0.1.0"

osiris_error() {
    printf 'Error: %s\n' "$1" >&2
    return 1
}

print_help() {
    cat <<'EOF'
Osiris - GitHub repository helper

Usage:
  osiris list                    Select and clone an owned repository interactively
  osiris list --all              Select and clone any accessible repository
  osiris owners                  List accessible users and organizations
  osiris create                  Create a GitHub repository interactively
  osiris clone PROJECT           Clone one of the user's repositories
  osiris clone PROJECT DIRECTORY Clone a repository into DIRECTORY
  osiris clone OWNER/PROJECT     Clone a repository from any accessible owner
  osiris --auth                  Authenticate or refresh GitHub CLI credentials
  osiris --version               Show the Osiris version
  osiris --help                  Show this help

Examples:
  osiris list
  osiris list --all
  osiris create
  osiris clone example-project
  osiris clone example-org/example-project ~/Projects/example-project
EOF
}
