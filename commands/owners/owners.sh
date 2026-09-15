#!/usr/bin/env bash

list_owners() {
    gh api --method GET user/repos --paginate --field affiliation='owner,collaborator,organization_member' --field per_page=100 --jq '.[] | [.owner.login, (if .owner.type == "Organization" then "organization" else "user" end)] | @tsv' |
    awk -F '\t' '{ count[$1]++; kind[$1] = $2 } END { for (owner in count) printf "%s\t%s\t%d\n", owner, kind[owner], count[owner] }' |
    sort -f |
    awk -F '\t' 'BEGIN { printf "%-32s %-16s %s\n", "OWNER", "TYPE", "REPOSITORIES"; printf "%-32s %-16s %s\n", "--------------------------------", "----------------", "------------" } { printf "%-32s %-16s %s\n", $1, $2, $3 }'
}

owners_command() {
    [[ $# -eq 1 ]] || osiris_error "The owners command does not accept arguments."
    require_gh
    require_authentication
    list_owners
}
