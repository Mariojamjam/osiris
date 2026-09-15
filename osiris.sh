#!/usr/bin/env bash

set -Eeuo pipefail

OSIRIS_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$OSIRIS_ROOT/lib/core.sh"
source "$OSIRIS_ROOT/lib/dependencies.sh"
source "$OSIRIS_ROOT/lib/github.sh"

osiris_main() {
    local command="${1:-}"
    local owner

    case "$command" in
        --help|-h)
            print_help
            ;;
        --version|-v)
            printf 'osiris %s\n' "$OSIRIS_VERSION"
            ;;
        --auth)
            [[ $# -eq 1 ]] || osiris_error "The --auth option does not accept arguments."
            require_gh
            if gh auth status -h github.com >/dev/null 2>&1; then
                printf 'GitHub authentication is already valid.\n'
            else
                gh auth login -h github.com -p https --web
            fi
            ;;
        list)
            source "$OSIRIS_ROOT/commands/list/list.sh"
            list_command "$@"
            ;;
        owners)
            source "$OSIRIS_ROOT/commands/owners/owners.sh"
            owners_command "$@"
            ;;
        create)
            source "$OSIRIS_ROOT/commands/create/create.sh"
            [[ $# -eq 1 ]] || osiris_error "The create command does not accept arguments."
            require_gh
            require_authentication
            owner="$(authenticated_user)"
            create_repository "$owner"
            ;;
        clone)
            source "$OSIRIS_ROOT/commands/clone/clone.sh"
            clone_command "$@"
            ;;
        '')
            print_help
            ;;
        *)
            osiris_error "Unknown command '$command'. Use 'osiris --help' for usage."
            ;;
    esac
}

osiris_main "$@"
