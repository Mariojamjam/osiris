#!/usr/bin/env bash

source "$OSIRIS_ROOT/commands/clone/clone.sh"
source "$OSIRIS_ROOT/commands/list/list-tui.sh"

list_command() {
    local all_repositories=0

    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all) all_repositories=1 ;;
            --help|-h) print_help; return 0 ;;
            *) osiris_error "Unknown list option '$1'. Use 'osiris --help' for usage." ;;
        esac
        shift
    done

    require_gh
    require_authentication
    interactive_clone "$(authenticated_user)" "$all_repositories"
}
