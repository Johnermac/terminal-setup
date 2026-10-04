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
| `cli` | gh lazygit lazydocker delta yq direnv claude eza xh fx dust btop atuin |
| `langs` | go node python uv rust |
| `cloud` | docker kubectl helm k9s terraform aws granted |
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
| `tmux-boxes` | tmux 3.7b patched with rounded per-pane border boxes, installed to `~/.local/bin/tmux` |

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
patches/        source patches applied by opt-in groups
```

| Repo | Home |
|---|---|
| `config/fish/*` | `~/.config/fish/` |
| `config/starship.toml` | `~/.config/starship.toml` |
| `config/tmux/tmux.conf` | `~/.tmux.conf` |
| `config/git/config.inc` | `~/.config/git/terminal-setup.inc`, added to `include.path` |
| `config/bin/tmux-git-title` | `~/.local/bin/tmux-git-title` |
| `config/bin/claude-tmux` | `~/.local/bin/claude-tmux` |
| `config/bin/claude-guard` | `~/.local/bin/claude-guard` |
| `config/claude/hooks.json` | merged into `~/.claude/settings.json` hooks |
| `config/claude/settings.base.json` | `permissions.deny` merged into `~/.claude/settings.json` |
| `config/atuin/config.toml` | `~/.config/atuin/config.toml` |

Symlinks, so `git pull` updates the live setup. Edit in the repo, commit, push.

Host-specific lines go in `~/.config/fish/local.fish`. Real file, untracked, sourced last.

## Adding a tool

Packaged everywhere: add it to an `ensure_packages` call, and to `lib/packages.sh` if the name differs per distro.
GitHub release: one `release_bin` line in the group function:

```bash
release_bin eza eza-community/eza x86_64/aarch64 'v{v}/eza_{arch}-unknown-linux-gnu.tar.gz' eza
```

Arguments: binary, repo, the release's names for x86_64/arm64, the asset path, then the binary's path inside the archive (omit for a bare binary). Placeholders: `{v}` version, `{arch}`, `{os}` (`linux`), `{Os}` (`Linux`). On brew it installs the formula of the same name; map a different formula name in `lib/packages.sh`. `--check-runs` first reinstalls a binary that is present but fails to start.
Then add the tool to the module's `group_info` line, which feeds `--list`, and to the table above.
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
| `ctrl+r` | atuin history search (fuzzy; `ctrl+r` again cycles global/host/session/directory) |
| `ctrl+t` | file picker |
| `alt+c` | dir jump |
| `dev <name>` | attach-or-create project session (edit/run/git/claude) |
| `dev` | pick session via fzf |
| `ports` / `serve [port]` | listening sockets / http server in cwd |
| `ll` / `lt` | eza long list with git status / tree |
| `assume [profile]` | export AWS credentials for a profile into this shell (granted); `assume -c` opens the console, `assume --un` drops back |
| `aic` | Claude writes the commit subject for the staged diff, you confirm (`y`), edit (`e`) or abort |
| `why` | re-runs the last command and asks Claude for cause and fix; or pipe: `cmd 2>&1 \| why` |
| `tfr [planfile]` | Claude risk review of a terraform plan; runs `terraform plan` when no file is given |

tmux, prefix `C-a`

| Key | Action |
|---|---|
| `alt+arrows` | move pane |
| `prefix shift+arrows` | resize pane |
| `prefix \|` / `prefix -` | split h / v |
| `prefix S` / `prefix s` | sync panes on / off |
| `prefix g` | scratch popup |
| `prefix C-j` | session tree with Claude state and live preview (`ctrl-x` kills, `→` expands) |
| `prefix j` | jump to latest Claude pane that finished |
| `prefix J` | pick from pending Claude panes (`ctrl-x` clears) |
| `prefix G` / `prefix D` | lazygit / lazydocker popup |
| `prefix /` | scrollback search |
| `prefix B` / `prefix N` | toggle border boxes / rounded vs heavy lines (`tmux-boxes` only) |
| `prefix r` | reload config |

## Claude notifications

When Claude finishes or waits for a permission answer in a pane you are not looking at, tmux flashes `✻ session:window` and the status bar shows a pending count. Visiting the pane or sending a prompt there clears it.

Each pane's border title shows Claude's state: `●` working, `?` waiting for permission, `✓` finished and not yet visited. Window tabs show the same icon for any pane in that window. Exiting Claude clears it.

## AWS prompt

The right prompt shows the active AWS profile, the region when it is not us-east-1 and, after `assume`, time left on the credentials. Profiles aliased to `""` in `[aws.profile_aliases]` (the read-only default) show nothing. Profiles listed in `AWS_PROD_PROFILES` get a red `PROD` badge. Set it in `local.fish`:

```fish
set -gx AWS_PROD_PROFILES mgmt audit-mgmt
```

`aic`, `why` and `tfr` call `claude -p` with no tools and hooks disabled, so they never touch files or the tmux Claude state.

## Claude prod guard

`claude-guard` runs before every Bash command Claude issues. A command is in prod context when the environment profile is listed in `AWS_PROD_PROFILES`, when any word of the command is a listed profile, when a profile value is not a plain name (variable, substitution), or when credentials come from `AWS_ACCESS_KEY_ID`, `AWS_SESSION_TOKEN`, `AWS_CONFIG_FILE` and similar. In prod context it forces a confirmation prompt, even in auto mode, unless every `aws` and `terraform` call is a known read:

- `aws`: `describe-*`, `list-*`, `get-*`, `s3 ls`, `logs tail`, `sts get-caller-identity`, `configure list|get` and similar; calls that hand out credentials or access (`export-credentials`, `get-login-password`, `assume-role`, `get-secret-value`, `presign`) ask
- `terraform` or `tofu`: `plan`, `show`, `output`, `validate`, `fmt`, `init` without `-migrate-state`, `state list|show`, `workspace list|show`

A command that is itself a variable (`$x ...`) also asks in prod context. Force pushes, including `+refspec`, always ask. Any mention of `aws-vault` is denied: it stays a human-only breakglass path.

It reads the command text, so scripts and SDK code that call AWS internally get through. IAM is the real boundary: pin Claude to a read-only profile in `~/.claude/settings.json`, and blank the key variables so credentials exported by `assume` in the launching shell do not leak in:

```json
"env": {
  "AWS_PROFILE": "audit-readonly",
  "AWS_DEFAULT_PROFILE": "",
  "AWS_ACCESS_KEY_ID": "",
  "AWS_SECRET_ACCESS_KEY": "",
  "AWS_SESSION_TOKEN": ""
}
```

Writes then need an explicit `--profile`, which the guard sees.

Claude Code may start outside fish, so set the list in `~/.claude/settings.json` too:

```json
"env": { "AWS_PROD_PROFILES": "mgmt audit-mgmt" }
```

`settings.base.json` adds deny rules so Claude cannot read AWS credential caches, SSH private keys or `~/.gnupg`.

## Border boxes

`--with tmux-boxes` builds tmux 3.7b with `patches/tmux-3.7b.patch`. Every pane gets its own rounded box, at the cost of 2 rows and 2 columns per pane. Boxes turn off in windows with a single pane and while a pane is zoomed. Clicking a box focuses its pane, dragging a box edge or the gap resizes.

The patch also adds `ctrl-x` to kill in the session tree, and fixes a 3.7b crash when `detach-on-destroy` is `next` or `previous`. Killing the current session moves the client to the next session by name.

The same block turns on 3.7 features stock 3.2a lacks: extended keys (Shift+Enter reaches Claude Code), OSC 8 hyperlinks, synchronized output, rounded popups.

The config enables it only when the running tmux has the `pane-border-boxes` option, so stock tmux ignores it. Kill the running server after installing, since a new client should not talk to an old server.

## Uninstall

```sh
find ~/.config/fish ~/.config/starship.toml ~/.tmux.conf ~/.local/bin/tmux-git-title \
  ~/.local/bin/claude-tmux ~/.local/bin/claude-guard \
  -maxdepth 2 -lname "$PWD/*" -delete
git config --global --unset-all include.path "$HOME/.config/git/terminal-setup.inc"
chsh -s "$(command -v bash)"
rm -f ~/.local/bin/tmux ~/.local/share/man/man1/tmux.1 ~/.local/share/terminal-setup/tmux-boxes.stamp
```

Originals are in the `.bak.<timestamp>` files.
