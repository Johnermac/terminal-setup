# terminal-setup

Reproducible devsecops terminal: fish + tmux + starship, dev toolchains, cloud CLIs, security scanners.
Runs on apt, pacman, dnf, zypper, apk and brew.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/johnermac/terminal-setup/main/bootstrap.sh | sh
```

Then the font:

```sh
~/projects/terminal-setup/scripts/install-font.sh
```

and select **JetBrainsMono Nerd Font** in your terminal emulator.

## Groups

| Group | Contents |
|---|---|
| `base` | git curl wget unzip jq tree htop vim ripgrep fd bat compiler toolchain |
| `shell` | fish tmux fzf starship zoxide |
| `cli` | gh lazygit lazydocker delta yq direnv claude |
| `langs` | go node python uv rust |
| `cloud` | docker kubectl helm k9s terraform aws |
| `sec` | nmap tcpdump dig whois socat openssl trivy grype syft gitleaks hadolint cosign semgrep checkov detect-secrets |
| `config` | dotfile symlinks, fisher, tpm, default shell |

Opt-in with `--with`:

| Group | Contents |
|---|---|
| `pentest` | ffuf gobuster httpx subfinder nuclei katana dnsx assetfinder waybackurls sqlmap |
| `wordlists` | SecLists (~1 GB) |
| `ruby` | rbenv, ruby-build, latest stable ruby (compiles from source) |
| `java` | jdk, maven |
| `gcloud` | google cloud sdk |

```sh
./install.sh --dry-run
./install.sh --with pentest,wordlists
./install.sh --groups base,shell,config
./install.sh --without cloud,sec
./install.sh --list
```

Re-running changes nothing already correct. Anything it would overwrite becomes `<file>.bak.<timestamp>`.

## Layout

```
install.sh      orchestrator
bootstrap.sh    curl | sh entrypoint
lib/            logging, package manager abstraction, package name map
modules/        one file per group
config/         dotfiles, symlinked into $HOME
scripts/        font installer
```

| Repo | Home |
|---|---|
| `config/fish/*` | `~/.config/fish/` |
| `config/starship.toml` | `~/.config/starship.toml` |
| `config/tmux/tmux.conf` | `~/.tmux.conf` |
| `config/git/config.inc` | `~/.config/git/terminal-setup.inc`, added to `include.path` |
| `config/bin/tmux-git-title` | `~/.local/bin/tmux-git-title` |

Symlinks, so `git pull` updates the live setup. Edit in the repo, commit, push.

Host-specific lines go in `~/.config/fish/local.fish`. Real file, untracked, sourced last.

## Adding a tool

Packaged everywhere: add it to an `ensure_packages` call, and to `lib/packages.sh` if the name differs per distro.
Binary release: add an `install_<tool>` function in the module, guarded by `have <tool> && { skip; return; }`.
Fish plugin: one line in `config/fish/fish_plugins`.

## Dev

Hooks run via [lefthook](https://github.com/evilmartians/lefthook): shellcheck, shfmt, trailing whitespace on commit; conventional commit format on commit-msg.

```sh
go install github.com/evilmartians/lefthook@latest   # or: brew install lefthook
lefthook install
```

Needs `shellcheck` and `shfmt` on PATH.

## Keys

fish

| Key | Action |
|---|---|
| `ctrl+r` | history search (exact; `'term` for fuzzy) |
| `ctrl+t` | file picker |
| `alt+c` | dir jump |
| `dev <name>` | attach-or-create project session (edit/run/git/claude) |
| `dev` | pick session via fzf |
| `ports` / `serve [port]` | listening sockets / http server in cwd |

tmux, prefix `C-a`

| Key | Action |
|---|---|
| `alt+arrows` | move pane |
| `prefix shift+arrows` | resize pane |
| `prefix \|` / `prefix -` | split h / v |
| `prefix S` / `prefix s` | sync panes on / off |
| `prefix g` | scratch popup |
| `prefix C-j` | session switcher (`ctrl-x` kills) |
| `prefix G` / `prefix D` | lazygit / lazydocker popup |
| `prefix /` | scrollback search |
| `prefix r` | reload config |

## Uninstall

```sh
find ~/.config/fish ~/.config/starship.toml ~/.tmux.conf ~/.local/bin/tmux-git-title \
  -maxdepth 2 -lname "$PWD/*" -delete
git config --global --unset-all include.path "$HOME/.config/git/terminal-setup.inc"
chsh -s "$(command -v bash)"
```

Originals are in the `.bak.<timestamp>` files.
