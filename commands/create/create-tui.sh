#!/usr/bin/env bash

render_create_header() {
    local visibility="${1:-private}"
    printf '\033[1;36mOsiris - Create GitHub Repository\033[0m\n'
    printf 'Type the repository name in the prompt below.\n'
    if [[ "$visibility" == public ]]; then
        printf 'Visibility: \033[2mprivate\033[0m    \033[1;33m◀ [ public ] ▶\033[0m\n'
    else
        printf 'Visibility: \033[1;33m◀ [ private ] ▶\033[0m    \033[2mpublic\033[0m\n'
    fi
    printf 'Use Left/Right to change visibility · Enter to continue · Esc to cancel.\n'
}

valid_repository_name() {
    [[ -n "$1" && ${#1} -le 100 && "$1" =~ ^[A-Za-z0-9._-]+$ ]]
}

prompt_create_form() {
    local query_output visibility_state initial_header public_header_command private_header_command
    require_fzf
    visibility_state="$(mktemp "${TMPDIR:-/tmp}/osiris-create.XXXXXX")"
    printf 'private\n' >"$visibility_state"
    initial_header="$(render_create_header private)"
    printf -v public_header_command '%q %q %q' "$OSIRIS_ROOT/commands/create/create-tui.sh" header public
    printf -v private_header_command '%q %q %q' "$OSIRIS_ROOT/commands/create/create-tui.sh" header private
    query_output="$(printf '\n' | fzf --ansi --border --height=10 --layout=reverse --no-multi --phony --print-query --pointer='' --marker='' --header="$initial_header" --prompt='Repository name > ' --bind='enter:accept' --bind="right:execute-silent(printf public > '$visibility_state')+transform-header($public_header_command)" --bind="ctrl-right:execute-silent(printf public > '$visibility_state')+transform-header($public_header_command)" --bind="left:execute-silent(printf private > '$visibility_state')+transform-header($private_header_command)" --bind="ctrl-left:execute-silent(printf private > '$visibility_state')+transform-header($private_header_command)")" || { rm -f "$visibility_state"; return 1; }
    OSIRIS_CREATE_NAME="${query_output%%$'\n'*}"
    OSIRIS_CREATE_VISIBILITY="$(<"$visibility_state")"
    rm -f "$visibility_state"
    valid_repository_name "$OSIRIS_CREATE_NAME" || osiris_error "Repository name must contain 1-100 letters, numbers, dots, hyphens, or underscores."
}

if [[ "${BASH_SOURCE[0]}" == "$0" && "${1:-}" == header ]]; then
    render_create_header "${2:-private}"
fi
