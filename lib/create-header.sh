#!/usr/bin/env bash

set -Eeuo pipefail

visibility="${1:-private}"

printf '\033[1;36mOsiris - Create GitHub Repository\033[0m\n'
printf 'Type the repository name in the prompt below.\n'
if [[ "$visibility" == "public" ]]; then
    printf 'Visibility: \033[2mprivate\033[0m    \033[1;33m◀ [ public ] ▶\033[0m\n'
else
    printf 'Visibility: \033[1;33m◀ [ private ] ▶\033[0m    \033[2mpublic\033[0m\n'
fi
printf 'Use Left/Right to change visibility · Enter to continue · Esc to cancel.\n'
