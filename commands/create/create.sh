#!/usr/bin/env bash

source "$OSIRIS_ROOT/commands/create/create-tui.sh"

confirm_create_repository() {
    local answer
    printf '\nCreate this repository remotely? [Y/n] '
    IFS= read -r answer || return 1
    case "${answer,,}" in ''|y|yes) return 0 ;; n|no) return 1 ;; *) printf 'Please answer yes or no.\n'; confirm_create_repository ;; esac
}

confirm_local_clone() {
    local owner="$1" repository_name="$2" answer destination="$PWD/$2"
    printf '\nWould you like to clone this repository into the current directory? [y/N] '
    IFS= read -r answer || return 1
    case "${answer,,}" in
        ''|n|no) printf 'Repository created successfully. No local clone was requested.\n' ;;
        y|yes) [[ ! -e "$destination" ]] || osiris_error "Cannot clone because the target directory already exists: $destination"; printf 'Cloning %s into the current directory...\n' "$owner/$repository_name"; gh repo clone "$owner/$repository_name"; printf 'Repository cloned successfully.\n' ;;
        *) printf 'Please answer yes or no.\n'; confirm_local_clone "$owner" "$repository_name" ;;
    esac
}

create_repository() {
    local owner="$1" repository_url
    OSIRIS_CREATE_NAME=""; OSIRIS_CREATE_VISIBILITY="private"
    if ! prompt_create_form; then printf 'Repository creation cancelled.\n'; return 0; fi
    printf '\nRepository to create:\n  Owner:      %s\n  Name:       %s\n  Visibility: %s\n' "$owner" "$OSIRIS_CREATE_NAME" "$OSIRIS_CREATE_VISIBILITY"
    confirm_create_repository || { printf 'Repository creation cancelled.\n'; return 0; }
    gh repo view "$owner/$OSIRIS_CREATE_NAME" >/dev/null 2>&1 && osiris_error "Repository '$owner/$OSIRIS_CREATE_NAME' already exists."
    printf '\nCreating %s repository...\n' "$OSIRIS_CREATE_VISIBILITY"
    repository_url="$(gh repo create "$owner/$OSIRIS_CREATE_NAME" "--$OSIRIS_CREATE_VISIBILITY")"
    printf 'Repository created successfully:\n%s\n' "$repository_url"
    confirm_local_clone "$owner" "$OSIRIS_CREATE_NAME"
}
