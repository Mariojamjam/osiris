#!/usr/bin/env bash

set -Eeuo pipefail

OSIRIS_PAGE_SIZE=20

format_page() {
    local session_dir="$1"
    local page="$2"
    local repository_width="$3"
    local scope="$4"
    local last_page
    local page_indicator

    if [[ -f "$session_dir/last-page" ]]; then
        last_page="$(<"$session_dir/last-page")"
        page_indicator="Page $page of $last_page · 20 repositories per page"
    else
        page_indicator="Page $page · loading more pages · 20 repositories per page"
    fi

    printf '%s\n' "$page_indicator · $scope"
    awk -F '\t' -v width="$repository_width" '
        function fit(value, max) {
            if (length(value) <= max) return value
            return substr(value, 1, max - 3) "..."
        }
        {
            repository = fit($1, width)
            printf "%s\t%-*s  %-10s\t%s\n", $1, width, repository, $2, $3
        }
    ' "$session_dir/page-${page}.tsv"
}

wait_for_page() {
    local session_dir="$1"
    local page="$2"
    local fetcher_pid="$3"
    local page_file="$session_dir/page-${page}.tsv"

    while [[ ! -f "$page_file" ]]; do
        [[ -f "$session_dir/error" ]] && return 1
        if ! kill -0 "$fetcher_pid" 2>/dev/null; then
            [[ -f "$page_file" ]] && break
            return 1
        fi
        sleep 0.1
    done
}

reload_page() {
    local action="$1"
    local session_dir="$2"
    local fetcher_pid="$3"
    local repository_width="$4"
    local scope="$5"
    local current_page
    local target_page
    local last_page

    current_page="$(<"$session_dir/current-page")"
    target_page="$current_page"

    case "$action" in
        right)
            target_page=$((current_page + 1))
            if [[ -f "$session_dir/last-page" ]]; then
                last_page="$(<"$session_dir/last-page")"
                (( target_page > last_page )) && target_page="$current_page"
            fi
            ;;
        left) (( current_page > 1 )) && target_page=$((current_page - 1)) ;;
        *) exit 2 ;;
    esac

    if (( target_page != current_page )); then
        wait_for_page "$session_dir" "$target_page" "$fetcher_pid" || target_page="$current_page"
    fi

    printf '%s\n' "$target_page" >"$session_dir/current-page"
    format_page "$session_dir" "$target_page" "$repository_width" "$scope"
}

case "${1:-}" in
    render) format_page "$2" "$3" "$4" "$5" ;;
    reload) reload_page "$2" "$3" "$4" "$5" "$6" ;;
    *) printf 'Usage: list-tui-page.sh {render|reload} ...\n' >&2; exit 2 ;;
esac
