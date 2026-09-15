#!/usr/bin/env bash

OSIRIS_CREATE_NAME=""
OSIRIS_CREATE_VISIBILITY="private"

valid_repository_name() {
    local repository_name="$1"

    [[ -n "$repository_name" ]] || return 1
    [[ ${#repository_name} -le 100 ]] || return 1
    [[ "$repository_name" =~ ^[A-Za-z0-9._-]+$ ]]
}

prompt_create_form() {
    local query_output
    local visibility_state
    local initial_header
    local public_header_command
    local private_header_command

    require_fzf
    visibility_state="$(mktemp "${TMPDIR:-/tmp}/osiris-create.XXXXXX")"
    printf 'private\n' >"$visibility_state"

    initial_header="$("$OSIRIS_ROOT/lib/create-header.sh" private)"
    printf -v public_header_command '%q %q' "$OSIRIS_ROOT/lib/create-header.sh" public
    printf -v private_header_command '%q %q' "$OSIRIS_ROOT/lib/create-header.sh" private

    query_output="$(printf '\n' | fzf \
        --ansi \
        --border \
        --height=10 \
        --layout=reverse \
        --no-multi \
        --phony \
        --print-query \
        --pointer='' \
        --marker='' \
        --header="$initial_header" \
        --prompt='Repository name > ' \
        --bind='enter:accept' \
        --bind="right:execute-silent(printf public > '$visibility_state')+transform-header($public_header_command)" \
        --bind="ctrl-right:execute-silent(printf public > '$visibility_state')+transform-header($public_header_command)" \
        --bind="left:execute-silent(printf private > '$visibility_state')+transform-header($private_header_command)" \
        --bind="ctrl-left:execute-silent(printf private > '$visibility_state')+transform-header($private_header_command)")" || {
        rm -f "$visibility_state"
        return 1
    }

    OSIRIS_CREATE_NAME="${query_output%%$'\n'*}"
    OSIRIS_CREATE_VISIBILITY="$(<"$visibility_state")"
    rm -f "$visibility_state"

    if ! valid_repository_name "$OSIRIS_CREATE_NAME"; then
        osiris_error "Repository name must contain 1-100 letters, numbers, dots, hyphens, or underscores."
    fi
}

confirm_create_repository() {
    local answer

    printf '\nCreate this repository remotely? [Y/n] '
    IFS= read -r answer || return 1
    case "${answer,,}" in
        ''|y|yes) return 0 ;;
        n|no) return 1 ;;
        *) printf 'Please answer yes or no.\n'; confirm_create_repository ;;
    esac
}

confirm_local_clone() {
    local owner="$1"
    local repository_name="$2"
    local answer
    local destination="$PWD/$repository_name"

    printf '\nWould you like to clone this repository into the current directory? [y/N] '
    IFS= read -r answer || return 1
    case "${answer,,}" in
        ''|n|no)
            printf 'Repository created successfully. No local clone was requested.\n'
            return 0
            ;;
        y|yes)
            if [[ -e "$destination" ]]; then
                osiris_error "Cannot clone because the target directory already exists: $destination"
            fi
            printf 'Cloning %s into the current directory...\n' "$owner/$repository_name"
            gh repo clone "$owner/$repository_name"
            printf 'Repository cloned successfully.\n'
            ;;
        *)
            printf 'Please answer yes or no.\n'
            confirm_local_clone "$owner" "$repository_name"
            ;;
    esac
}

create_repository() {
    local owner="$1"
    local repository_url

    OSIRIS_CREATE_NAME=""
    OSIRIS_CREATE_VISIBILITY="private"

    if ! prompt_create_form; then
        printf 'Repository creation cancelled.\n'
        return 0
    fi

    printf '\nRepository to create:\n'
    printf '  Owner:      %s\n' "$owner"
    printf '  Name:       %s\n' "$OSIRIS_CREATE_NAME"
    printf '  Visibility: %s\n' "$OSIRIS_CREATE_VISIBILITY"

    if ! confirm_create_repository; then
        printf 'Repository creation cancelled.\n'
        return 0
    fi

    if gh repo view "$owner/$OSIRIS_CREATE_NAME" >/dev/null 2>&1; then
        osiris_error "Repository '$owner/$OSIRIS_CREATE_NAME' already exists."
    fi

    printf '\nCreating %s repository...\n' "$OSIRIS_CREATE_VISIBILITY"
    repository_url="$(gh repo create "$owner/$OSIRIS_CREATE_NAME" "--$OSIRIS_CREATE_VISIBILITY")"
    printf 'Repository created successfully:\n%s\n' "$repository_url"
    confirm_local_clone "$owner" "$OSIRIS_CREATE_NAME"
}
