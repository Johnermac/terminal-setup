# terminal-setup

One-command terminal environment: **fish + tmux + starship + fzf/fd/bat/zoxide + lazygit/lazydocker**, Catppuccin Mocha.
Targets fresh Ubuntu/Debian (WSL2 or native).

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/johnermac/terminal-setup/main/bootstrap.sh | sh
```

Or clone first:

```sh
git clone https://github.com/johnermac/terminal-setup.git ~/projects/terminal-setup
~/projects/terminal-setup/install.sh
```

Then the one thing a script can't finish for you — the font (see below):

```sh
~/projects/terminal-setup/scripts/install-font.sh
```

## What install.sh does

| Step | Action |
|---|---|
| packages | apt: `fish tmux git curl unzip fzf fd-find bat` (only what's missing) |
| fd shim | `~/.local/bin/fd -> fdfind` (Ubuntu renames the binary) |
| fzf | rebuilds from source if apt's version is `< 0.48` (`fzf --fish` needs it) |
| zoxide / starship | official install scripts, skipped when already present |
| lazygit / lazydocker | latest GitHub release, arch-aware (`x86_64` / `arm64`) |
| configs | symlinks this repo into `~` (see table below) |
| fish plugins | fisher, reconciled against `config/fish/fish_plugins` |
| tmux plugins | TPM clone + non-interactive `install_plugins` |
| shell | `chsh -s fish`, adding fish to `/etc/shells` first |
| verify | reports any tool still missing |

Idempotent — re-running changes nothing that's already correct. Anything it would
overwrite gets moved to `<file>.bak.<timestamp>` first.

### Flags

```
--dry-run         print every command instead of running it
--skip-packages   configs only, no apt / installer scripts
--skip-chsh       leave the login shell alone
--skip-plugins    no fisher / TPM
```

Start with `./install.sh --dry-run` on a machine you care about.

## Symlink map

| Repo | Home |
|---|---|
| `config/fish/config.fish` | `~/.config/fish/config.fish` |
| `config/fish/fish_plugins` | `~/.config/fish/fish_plugins` |
| `config/fish/conf.d/*.fish` | `~/.config/fish/conf.d/` |
| `config/fish/functions/*.fish` | `~/.config/fish/functions/` |
| `config/starship.toml` | `~/.config/starship.toml` |
| `config/tmux/tmux.conf` | `~/.tmux.conf` |
| `config/bin/tmux-git-title` | `~/.local/bin/tmux-git-title` |

Because they're symlinks, `git pull` updates the live setup — no reinstall.
Edit configs **in the repo**, commit, push.

### Machine-specific config

`~/.config/fish/local.fish` is a real file, created empty on install and never
tracked. `config.fish` sources it last. Put version managers, per-host `PATH`
entries, and anything with a secret in it there — that's what keeps the repo
portable across machines.

## Font (only manual step)

Glyphs are rendered by the terminal emulator on the *host*, not by WSL, so the
font must be installed on Windows. `scripts/install-font.sh` handles both sides:
it installs JetBrainsMono Nerd Font into `~/.local/share/fonts` and, on WSL, does
a per-user Windows install (no admin) via `powershell.exe`.

You still pick it in the emulator:
**Windows Terminal → Settings → profile → Appearance → Font face →
`JetBrainsMono Nerd Font`, size 14.**

## Adding a tool

1. Add an `install_<tool>` function in `install.sh` — guard with `have <tool> && { skip; return; }`.
2. Call it from `main()`.
3. Config file? Drop it under `config/`, add a `link` line in `link_configs`.
4. Fish plugin? One line in `config/fish/fish_plugins` — `fisher update` picks it up.

## Cheat sheet

### fish

| Key | Action |
|---|---|
| `ctrl+r` | history search (exact; `'term` for fuzzy) |
| `ctrl+t` | file picker (fd + bat preview) |
| `alt+c` | dir jump (fd) |
| `ctrl+/` | toggle preview in `ctrl+r` |
| `dev <name>` | attach-or-create project session (edit/run/git/claude windows) |
| `dev` | pick session via fzf |

### tmux (prefix `C-a`)

| Key | Action |
|---|---|
| `alt+arrows` | move pane (no prefix) |
| `prefix shift+arrows` | resize pane |
| `prefix \|` / `prefix -` | split h / v (keeps cwd) |
| `prefix S` / `prefix s` | sync panes on / off |
| `prefix g` | scratch popup shell |
| `prefix C-j` | session switcher (fzf; `ctrl-x` kills) |
| `prefix G` | lazygit popup |
| `prefix D` | lazydocker popup |
| `prefix /` | incremental scrollback search |
| `prefix r` | reload config |
| `prefix I` | install TPM plugins |

## Uninstall

```sh
find ~/.config/fish ~/.config/starship.toml ~/.tmux.conf ~/.local/bin/tmux-git-title \
  -maxdepth 2 -lname "$PWD/*" -delete
chsh -s "$(command -v bash)"
```

Restore your originals from the `.bak.<timestamp>` files.

---

`SETUP.md` is the original hand-run guide, kept as reference for what each block does.
