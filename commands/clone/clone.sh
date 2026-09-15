#!/usr/bin/env bash

clone_repository() {
    local owner="$1" repository="$2" destination="${3:-}" qualified_repository="$2" resolved_repository
    if [[ "$repository" != */* ]]; then qualified_repository="$owner/$repository"; fi
    if ! resolved_repository="$(gh repo view "$qualified_repository" --json nameWithOwner --jq .nameWithOwner 2>/dev/null)"; then
        osiris_error "Repository '$qualified_repository' was not found or cannot be accessed."
    fi
    printf 'Cloning %s...\n' "$resolved_repository"
    if [[ -n "$destination" ]]; then gh repo clone "$resolved_repository" "$destination"; else gh repo clone "$resolved_repository"; fi
    printf 'Repository cloned successfully.\n'
}

clone_command() {
    local owner
    shift
    [[ -n "${1:-}" ]] || osiris_error "Missing project. Usage: osiris clone PROJECT [DIRECTORY]"
    [[ "${1:-}" != --* ]] || osiris_error "Invalid project name. Usage: osiris clone PROJECT [DIRECTORY]"
    [[ $# -le 2 ]] || osiris_error "Too many arguments. Use 'osiris --help' for usage."
    require_gh
    require_authentication
    owner="$(authenticated_user)"
    clone_repository "$owner" "$1" "${2:-}"
}
