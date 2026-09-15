#!/usr/bin/env bash

OSIRIS_PAGE_SIZE=20

fetch_repository_page() {
    local owner="$1" all_repositories="$2" page="$3"
    if [[ "$all_repositories" -eq 1 ]]; then
        gh api --method GET user/repos --field affiliation='owner,collaborator,organization_member' --field page="$page" --field per_page="$OSIRIS_PAGE_SIZE" --jq '.[] | [.full_name, (if .private then "private" else "public" end), .html_url] | @tsv'
    else
        gh api --method GET user/repos --field affiliation=owner --field page="$page" --field per_page="$OSIRIS_PAGE_SIZE" --jq '.[] | [.full_name, (if .private then "private" else "public" end), .html_url] | @tsv'
    fi
}

start_repository_fetcher() {
    local owner="$1" all_repositories="$2" session_dir="$3"
    (
        local page=1 temporary_page page_count
        while :; do
            temporary_page="$session_dir/.page-${page}.tmp"
            if ! fetch_repository_page "$owner" "$all_repositories" "$page" >"$temporary_page"; then
                printf 'Unable to load page %s.\n' "$page" >"$session_dir/error"
                rm -f "$temporary_page"
                exit 1
            fi
            mv -- "$temporary_page" "$session_dir/page-${page}.tsv"
            page_count="$(wc -l <"$session_dir/page-${page}.tsv")"
            if (( page_count == 0 )); then
                if (( page == 1 )); then printf '1\n' >"$session_dir/last-page"; else rm -f "$session_dir/page-${page}.tsv"; printf '%s\n' "$((page - 1))" >"$session_dir/last-page"; fi
                exit 0
            fi
            if (( page_count < OSIRIS_PAGE_SIZE )); then printf '%s\n' "$page" >"$session_dir/last-page"; exit 0; fi
            page=$((page + 1))
        done
    ) &
    printf '%s\n' "$!"
}

wait_for_repository_page() {
    local session_dir="$1"
    local page="$2"
    local fetcher_pid="$3"
    local page_file="$session_dir/page-${page}.tsv"
    while [[ ! -f "$page_file" ]]; do
        [[ -f "$session_dir/error" ]] && { cat "$session_dir/error" >&2; return 1; }
        if ! kill -0 "$fetcher_pid" 2>/dev/null; then [[ -f "$page_file" ]] && break; return 1; fi
        sleep 0.1
    done
}

interactive_clone() {
    local owner="$1" all_repositories="$2" session_dir fetcher_pid repository_width selected_repository fzf_status fzf_right_command fzf_left_command fzf_scope initial_data
    require_fzf
    session_dir="$(mktemp -d "${TMPDIR:-/tmp}/osiris.XXXXXX")"
    fetcher_pid="$(start_repository_fetcher "$owner" "$all_repositories" "$session_dir")"
    OSIRIS_ACTIVE_FETCHER_PID="$fetcher_pid"; OSIRIS_ACTIVE_SESSION_DIR="$session_dir"
    cleanup_repository_session() {
        [[ -n "${OSIRIS_ACTIVE_FETCHER_PID:-}" ]] && kill "$OSIRIS_ACTIVE_FETCHER_PID" 2>/dev/null || true
        [[ -n "${OSIRIS_ACTIVE_FETCHER_PID:-}" ]] && wait "$OSIRIS_ACTIVE_FETCHER_PID" 2>/dev/null || true
        [[ -n "${OSIRIS_ACTIVE_SESSION_DIR:-}" && -d "$OSIRIS_ACTIVE_SESSION_DIR" ]] && rm -rf -- "$OSIRIS_ACTIVE_SESSION_DIR"
        unset OSIRIS_ACTIVE_FETCHER_PID OSIRIS_ACTIVE_SESSION_DIR
    }
    trap cleanup_repository_session EXIT
    wait_for_repository_page "$session_dir" 1 "$fetcher_pid" || osiris_error "Unable to load repositories."
    if [[ "$all_repositories" -eq 1 ]]; then fzf_scope="all accessible repositories"; else fzf_scope="repositories owned by $owner"; fi
    repository_width=$(( $(tput cols 2>/dev/null || printf '100') - 18 )); (( repository_width < 32 )) && repository_width=32; (( repository_width > 72 )) && repository_width=72
    initial_data="$("$OSIRIS_ROOT/commands/list/list-tui-page.sh" render "$session_dir" 1 "$repository_width" "$fzf_scope")"
    printf '1\n' >"$session_dir/current-page"
    printf -v fzf_right_command '%q %q %q %q %q %q %q' "$OSIRIS_ROOT/commands/list/list-tui-page.sh" reload right "$session_dir" "$fetcher_pid" "$repository_width" "$fzf_scope"
    printf -v fzf_left_command '%q %q %q %q %q %q %q' "$OSIRIS_ROOT/commands/list/list-tui-page.sh" reload left "$session_dir" "$fetcher_pid" "$repository_width" "$fzf_scope"
    fzf_status=0
    selected_repository="$(printf '%s\n' "$initial_data" | fzf --ansi --border --height=100% --layout=reverse --no-multi --delimiter=$'\t' --header-lines=1 --nth=1,2 --with-nth=2 --header='←/→ page · ↑/↓ select · Enter clone · Esc cancel' --prompt='Repository > ' --pointer='▶ ' --marker='✓ ' --cycle --bind="right:reload($fzf_right_command)" --bind="ctrl-right:reload($fzf_right_command)" --bind="left:reload($fzf_left_command)" --bind="ctrl-left:reload($fzf_left_command)")" || fzf_status=$?
    if [[ $fzf_status -ne 0 || -z "$selected_repository" ]]; then return 0; fi
    selected_repository="${selected_repository%%$'\t'*}"
    printf 'Selected repository: %s\n' "$selected_repository"
    clone_repository "$owner" "$selected_repository"
}
