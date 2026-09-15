#!/usr/bin/env bash

set -Eeuo pipefail

OSIRIS_VERSION="0.1.0"

osiris_error() {
    printf 'Error: %s\n' "$1" >&2
    return 1
}

require_gh() {
    if ! command -v gh >/dev/null 2>&1; then
        osiris_error "GitHub CLI (gh) is not installed. Run the Osiris installer first."
    fi
}

authenticated_user() {
    gh api user --jq .login
}

require_authentication() {
    if ! gh auth status -h github.com >/dev/null 2>&1; then
        osiris_error "GitHub authentication is missing or invalid. Run: osiris --auth"
    fi
}

list_repositories() {
    local owner="$1"
    local query="${2:-}"
    local repositories

    repositories="$(gh repo list "$owner" \
        --limit 1000 \
        --json nameWithOwner,isPrivate,url \
        --jq '.[] | [
            .nameWithOwner,
            (if .isPrivate then "private" else "public" end),
            .url
        ] | @tsv')"

    if [[ -n "$query" ]]; then
        printf '%s\n' "$repositories" | grep -iF -- "$query" || true
    else
        printf '%s\n' "$repositories"
    fi
}

list_accessible_repositories() {
    local query="${1:-}"

    gh api --method GET user/repos \
        --paginate \
        --field affiliation='owner,collaborator,organization_member' \
        --field per_page=100 \
        --jq '.[] | [
            .full_name,
            (if .private then "private" else "public" end),
            .html_url
        ] | @tsv' |
    if [[ -n "$query" ]]; then
        grep -iF -- "$query" || true
    else
        cat
    fi
}

list_owners() {
    gh api --method GET user/repos \
        --paginate \
        --field affiliation='owner,collaborator,organization_member' \
        --field per_page=100 \
        --jq '.[] | [.owner.login, (if .owner.type == "Organization" then "organization" else "user" end)] | @tsv' |
    awk -F '\t' '
        {
            count[$1]++
            kind[$1] = $2
        }
        END {
            for (owner in count) {
                printf "%s\t%s\t%d\n", owner, kind[owner], count[owner]
            }
        }
    ' |
    sort -f |
    awk -F '\t' '
        BEGIN {
            printf "%-32s %-16s %s\n", "OWNER", "TYPE", "REPOSITORIES"
            printf "%-32s %-16s %s\n", "--------------------------------", "----------------", "------------"
        }
        {
            printf "%-32s %-16s %s\n", $1, $2, $3
        }
    '
}

require_fzf() {
    if ! command -v fzf >/dev/null 2>&1; then
        osiris_error "fzf is not installed. Run the Osiris installer first."
    fi
}

clone_repository() {
    local owner="$1"
    local repository="$2"
    local destination="${3:-}"
    local qualified_repository="$repository"
    local resolved_repository

    if [[ "$repository" != */* ]]; then
        qualified_repository="$owner/$repository"
    fi

    if ! resolved_repository="$(gh repo view "$qualified_repository" --json nameWithOwner --jq .nameWithOwner 2>/dev/null)"; then
        osiris_error "Repository '$qualified_repository' was not found or cannot be accessed."
    fi

    printf 'Cloning %s...\n' "$resolved_repository"
    if [[ -n "$destination" ]]; then
        gh repo clone "$resolved_repository" "$destination"
    else
        gh repo clone "$resolved_repository"
    fi
    printf 'Repository cloned successfully.\n'
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
            require_gh
            if gh auth status -h github.com >/dev/null 2>&1; then
                printf 'GitHub authentication is already valid.\n'
            else
                gh auth login -h github.com -p https --web
            fi
            ;;
        list)
            local all_repositories=0
            shift
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --all)
                        all_repositories=1
                        ;;
                    --help|-h)
                        print_help
                        return 0
                        ;;
                    *)
                        osiris_error "Unknown list option '$1'. Use 'osiris --help' for usage."
                        ;;
                esac
                shift
            done

            require_gh
            require_authentication
            owner="$(authenticated_user)"
            interactive_clone "$owner" "$all_repositories"
            ;;
        owners)
            [[ $# -eq 1 ]] || osiris_error "The owners command does not accept arguments."
            require_gh
            require_authentication
            list_owners
            ;;
        create)
            [[ $# -eq 1 ]] || osiris_error "The create command does not accept arguments."
            require_gh
            require_authentication
            owner="$(authenticated_user)"
            create_repository "$owner"
            ;;
        clone)
            shift
            [[ -n "${1:-}" ]] || osiris_error "Missing project. Usage: osiris clone PROJECT [DIRECTORY]"
            [[ "${1:-}" != --* ]] || osiris_error "Invalid project name. Usage: osiris clone PROJECT [DIRECTORY]"
            [[ $# -le 2 ]] || osiris_error "Too many arguments. Use 'osiris --help' for usage."

            require_gh
            require_authentication
            owner="$(authenticated_user)"
            clone_repository "$owner" "$1" "${2:-}"
            ;;
        '')
            print_help
            ;;
        *)
            osiris_error "Unknown command '$command'. Use 'osiris --help' for usage."
            ;;
    esac
}
