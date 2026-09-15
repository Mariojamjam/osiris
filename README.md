# Osiris

Osiris is a Bash command-line utility for discovering and cloning GitHub
repositories through a short, consistent interface.

It uses:

- [GitHub CLI](https://cli.github.com/) for GitHub access, authentication, and cloning;
- [fzf](https://github.com/junegunn/fzf) for the interactive repository selector.

Osiris does not store GitHub tokens. Authentication is delegated to GitHub CLI.

## Installation

Clone this repository and run the installer:

```bash
git clone <repository-url> osiris
cd osiris
./install.sh
```

The installer is intended to be safe to run more than once. It:

1. Checks whether GitHub CLI (`gh`) is installed.
2. Installs GitHub CLI when it is missing.
3. Checks whether `fzf` is installed.
4. Installs `fzf` when it is missing.
5. Starts the GitHub web authentication flow when credentials are missing or invalid.
6. Installs the `osiris` command for the current user.
7. Adds the user-local binary directory to `~/.profile` when necessary.

The installer currently supports these package managers:

- `apt-get`;
- `dnf`;
- `pacman`;
- `brew`.

The installation uses HTTPS for Git operations.

After installation, start a new shell or reload the profile:

```bash
source ~/.profile
```

The command is installed as:

```text
~/.local/bin/osiris
```

## Commands

### List owned repositories

```bash
osiris list
```

Opens the interactive selector with repositories owned by the authenticated
GitHub user.

### List all accessible repositories

```bash
osiris list --all
```

Opens the interactive selector with repositories accessible through:

- the authenticated user's own account;
- organizations the user belongs to;
- direct collaboration access.

The command uses GitHub's authenticated-user repository API and follows
pagination, so it is not limited to the first page of results.

### List repository owners

```bash
osiris owners
```

Displays each unique user or organization that owns an accessible repository,
along with its type and the number of repositories found.

Example:

```text
OWNER                            TYPE             REPOSITORIES
-------------------------------- ---------------- ------------
example-org                      organization     4
example-user                     user             15
another-example-org              organization     42
```

### Clone a repository by project name

```bash
osiris clone example-project
```

Resolves `example-project` against the authenticated user's account and clones it
into the current directory.

This is the shortest form for repositories owned by the authenticated user.

### Create a remote repository

```bash
osiris create
```

Opens a small interactive form. Enter the repository name, use the Left and
Right arrow keys to choose `private` or `public`, and confirm the operation.
After creation, Osiris asks whether the new repository should also be cloned
into the current directory.

### Clone into a specific directory

```bash
osiris clone example-project ~/Projects/example-project
```

The second argument is passed as the local clone directory.

### Clone a repository owned by another user or organization

```bash
osiris clone OWNER/PROJECT
```

Example:

```bash
osiris clone example-org/example-project
```

The authenticated account must have access to the repository.

### Authenticate GitHub CLI

```bash
osiris --auth
```

If the current credentials are valid, Osiris reports that no action is needed.
Otherwise, it starts the browser-based GitHub authentication flow.

For a credential refresh without using Osiris directly:

```bash
gh auth refresh -h github.com
```

### Show help and version

```bash
osiris --help
osiris --version
```

## Interactive selector

The `list` commands use `fzf` as the interactive interface.

Inside the selector:

- type text to filter repositories;
- 20 repositories are displayed per page;
- press `Left` or `Right` to move between pages;
- press `Enter` to clone the selected repository;
- press `Esc` to cancel;
- the visible columns are the repository name and visibility;
- long repository names are truncated only for display;
- the complete repository name remains available for cloning.

The selector uses a fixed-width layout so the visibility column remains aligned
even when repository names have different lengths. Its layout adapts to the
terminal width within defined minimum and maximum limits.

The first page is loaded before the selector opens. Remaining pages are fetched
sequentially in the background and stored in a temporary session cache. This
means that page navigation normally does not wait for a new network request.
If the next page is still being fetched, Osiris waits for that background
request to finish instead of issuing a duplicate request.

## Authentication and permissions

Osiris relies on the active GitHub CLI account:

```bash
gh auth status -h github.com
```

The account must be able to access the repositories being listed or cloned.
Private repositories and organization repositories may require the appropriate
GitHub permissions and token scopes.

Osiris does not ask for or handle tokens directly. Credentials remain managed by
GitHub CLI in its normal credential storage.

## Command behavior and boundaries

The supported command structure is intentionally explicit:

```text
osiris list
osiris list --all
osiris owners
osiris create
osiris clone PROJECT
osiris clone OWNER/PROJECT
osiris --auth
osiris --help
osiris --version
```

The following older shortcuts are not part of the current interface:

```text
osiris
osiris --all
osiris --interactive
osiris project-name
```

Use `osiris list` when you want repository discovery and `osiris clone` when
you already know what to clone.

## Uninstallation

From the Osiris source directory, run:

```bash
./uninstall.sh
```

Uninstallation removes:

- the installed `osiris` command;
- Osiris' user-local installation files;
- the Osiris-managed profile entry.

It preserves:

- GitHub CLI;
- `fzf`;
- GitHub credentials;
- repositories already cloned to disk;
- unrelated shell configuration.

## Project layout

```text
osiris.sh                 Main entrypoint and command dispatcher
bin/osiris                Installed command launcher
commands/list/            Repository listing command and list TUI
commands/owners/          Accessible owners command
commands/create/          Remote repository creation and create TUI
commands/clone/           Repository clone command
lib/core.sh               Shared errors, version, and help
lib/github.sh             GitHub authentication helpers
lib/dependencies.sh       gh and fzf dependency checks
install.sh                Dependency and user-local installation
uninstall.sh              Osiris-only uninstallation
```
