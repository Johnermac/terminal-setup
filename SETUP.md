# Terminal Setup — Replication Guide

fish + tmux + starship + fzf/fd/bat/zoxide + lazygit/lazydocker. Catppuccin Mocha.
Each step is a copy-paste block. Run in order on a fresh Ubuntu/Debian (WSL2 or native).

## 0. Font (terminal emulator side)

Install **JetBrainsMono Nerd Font** on the host and set it in your terminal emulator
(Windows Terminal: profile → font `JetBrainsMono Nerd Font`, size 14).
Required for tmux theme glyphs and git branch icon.

## 1. Packages

```sh
sudo apt update
sudo apt install -y fish tmux git curl unzip fzf fd-find bat

# zoxide
curl -sSf https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# starship
curl -sS https://starship.rs/install.sh | sh -s -- -y

# lazygit (latest release)
LAZYGIT_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po '"tag_name": *"v\K[^"]*')
curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
sudo install /tmp/lazygit -D -t /usr/local/bin/

# lazydocker
curl -s https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
```

Note: on Ubuntu the binaries are `fdfind` and `batcat`. Config below uses `fd` and `batcat`; add an `fd` shim:

```sh
mkdir -p ~/.local/bin
ln -sf "$(command -v fdfind)" ~/.local/bin/fd
```

Newer fzf needed for `fzf --fish` (>= 0.48). If apt version too old:

```sh
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --bin && sudo cp ~/.fzf/bin/fzf /usr/local/bin/
```

## 2. Default shell

```sh
chsh -s "$(command -v fish)"
```

## 3. fish config

```sh
mkdir -p ~/.config/fish/conf.d ~/.config/fish/functions

cat > ~/.config/fish/config.fish <<'EOF'
if status is-interactive
    set -g fish_greeting ''

    # fzf look (shared by native binds + fzf.fish widgets)
    set -gx FZF_DEFAULT_OPTS '
        --height=50%
        --layout=reverse
        --border=rounded
        --info=inline
        --cycle
        --pointer=▶
        --marker=✓
        --color=hl:yellow,hl+:bright-yellow,pointer:cyan,marker:green,info:gray,border:gray,prompt:cyan'

    # ctrl+r: exact match (prefix term with ' for fuzzy), ctrl+/ toggles preview
    set -gx FZF_CTRL_R_OPTS "
        --exact
        --preview 'echo -- {} | fish_indent --ansi'
        --preview-window=bottom:3:hidden:wrap
        --bind ctrl-/:toggle-preview"

    # ctrl+t files / alt+c dirs via fd
    set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --exclude .git'
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_CTRL_T_OPTS "--preview 'batcat --style=numbers --color=always --line-range=:200 {}'"
    set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --exclude .git'

    # native fzf binds (ctrl+r/ctrl+t/alt+c) — after conf.d so ctrl+r wins over fzf.fish
    fzf --fish | source

    zoxide init fish | source
    starship init fish | source

    # abbreviations
    abbr -a g git
    abbr -a gs git status
    abbr -a ga git add
    abbr -a gc git commit
    abbr -a gco git checkout
    abbr -a gd git diff
    abbr -a gl 'git log --oneline --graph -20'
    abbr -a gp git push
    abbr -a k kubectl
    abbr -a cat batcat
    abbr -a bcp 'batcat -p'
    abbr -a ll 'ls -lah'
end
EOF

cat > ~/.config/fish/conf.d/gpg.fish <<'EOF'
set -gx GPG_TTY (tty)
EOF
```

## 4. fish plugins (fisher)

```sh
fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher patrickf1/fzf.fish evanlucas/fish-kubectl-completions"
```

## 5. fish functions

```sh
cat > ~/.config/fish/functions/dev.fish <<'EOF'
function dev --description 'Attach-or-create tmux session for a project (dev <name> [path])'
    if test (count $argv) -eq 0
        # no args: pick existing session via fzf
        set -l session (tmux list-sessions -F '#S' 2>/dev/null | fzf --height=40% --reverse --prompt='session> ')
        test -n "$session"; or return
        _dev_attach $session
        return
    end

    set -l name $argv[1]
    set -l dir $argv[2]

    if not tmux has-session -t $name 2>/dev/null
        # resolve project dir: explicit arg > zoxide > ~/projects match > cwd
        if test -z "$dir"
            set dir (zoxide query $name 2>/dev/null)
        end
        if test -z "$dir"
            set dir (fd --type d --max-depth 3 --glob $name ~/projects 2>/dev/null | head -1)
        end
        test -n "$dir"; or set dir $PWD

        tmux new-session -d -s $name -c $dir -n edit
        tmux new-window -t "$name:" -c $dir -n run
        tmux new-window -t "$name:" -c $dir -n git
        tmux new-window -t "$name:" -c $dir -n claude claude
        tmux select-window -t "$name:edit"
    end

    _dev_attach $name
end

function _dev_attach
    if test -n "$TMUX"
        tmux switch-client -t $argv[1]
    else
        tmux attach-session -t $argv[1]
    end
end
EOF

cat > ~/.config/fish/functions/commit.fish <<'EOF'
function commit
    if test (count $argv) -eq 0
        echo "Usage: commit \"your commit message\""
        return 1
    end

    set message (string join " " $argv)

    git add .
    git commit -m "$message"
    git push origin main
end
EOF

cat > ~/.config/fish/functions/gitac.fish <<'EOF'
function gitac
    if test (count $argv) -eq 0
        echo 'Usage: gitac "commit message"'
        return 1
    end

    set letters A B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC AD AE AF

    set last_subject (git log --pretty=%s | string match -r '^[A-Z]+:' | head -n 1)

    if test -z "$last_subject"
        set next_letter A
    else
        set last_letter (string replace -r ':' '' $last_subject)

        set index (contains -i $last_letter $letters)
        if test -z "$index"
            echo "Could not determine next letter."
            return 1
        end

        set next_index (math $index + 1)
        if test $next_index -gt (count $letters)
            echo "Reached end of sequence; no further letters available."
            return 1
        end

        set next_letter $letters[$next_index]
    end

    git add .
    git commit -m "$next_letter: $argv"
end
EOF
```

## 6. starship

```sh
cat > ~/.config/starship.toml <<'EOF'
# minimal prompt: just ❯ — dir + git branch live in tmux pane title
format = "$character"
EOF
```

## 7. tmux helper script

```sh
mkdir -p ~/.local/bin
cat > ~/.local/bin/tmux-git-title <<'EOF'
#!/bin/sh
# pane title suffix: " on <branch>" with nerd-font branch glyph (U+E0A0)
b=$(git -C "$1" branch --show-current 2>/dev/null)
[ -n "$b" ] && printf ' on \356\202\240 %s' "$b"
exit 0
EOF
chmod +x ~/.local/bin/tmux-git-title
```

## 8. tmux config

```sh
cat > ~/.tmux.conf <<'EOF'
# --- general ---
set -g escape-time 10
set -g history-limit 50000
set -g focus-events on
set -g default-terminal "tmux-256color"
set -as terminal-features ",*:RGB"
set -g mouse on
set -g set-clipboard on
setw -g mode-keys vi
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

# --- prefix: ctrl+a ---
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# --- panes: alt+arrows move, prefix+shift+arrows resize ---
bind -n M-Left  select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up    select-pane -U
bind -n M-Down  select-pane -D
bind -r S-Left  resize-pane -L 5
bind -r S-Right resize-pane -R 5
bind -r S-Up    resize-pane -U 5
bind -r S-Down  resize-pane -D 5

# --- sync panes (S on / s off) ---
bind S setw synchronize-panes on
bind s setw synchronize-panes off

# --- splits/windows keep cwd ---
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind c new-window -c "#{pane_current_path}"

# --- copy-mode vi keys ---
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi y send -X copy-selection-and-cancel
bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-selection-and-cancel

# --- reload ---
bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"

# --- popups: g scratch, C-j sessions (ctrl-x kills), G lazygit, D lazydocker ---
bind g display-popup -E -w 80% -h 80% -d "#{pane_current_path}"
bind C-j display-popup -E "tmux list-sessions -F '#S' | fzf --height=100% --reverse --header='enter: switch / ctrl-x: kill' --bind \"ctrl-x:execute-silent(tmux kill-session -t {})+reload(tmux list-sessions -F '#S')\" | xargs tmux switch-client -t"
bind G display-popup -E -w 90% -h 90% -d "#{pane_current_path}" lazygit
bind D display-popup -E -w 90% -h 90% lazydocker

# --- scrollback search ---
bind / copy-mode \; command-prompt -i -p "search:" "send -X search-backward-incremental '%%'"

# --- theme: catppuccin (needs nerd font) ---
set -g @catppuccin_flavor "mocha"
set -g @catppuccin_window_status_style "rounded"
set -g @catppuccin_window_text " #W"
set -g @catppuccin_window_current_text " #W"
set -g @catppuccin_date_time_text " %H:%M"
set -g status-left-length 100
set -g status-right-length 100
set -g status-left ""
# red SYNC ON warning = safety net against typing into synced panes
set -g status-right "#[fg=red,bold]#{?pane_synchronized,SYNC ON ,}#[default]"
set -ag status-right "#{E:@catppuccin_status_session}"
set -ag status-right "#{E:@catppuccin_status_date_time}"

# --- plugins ---
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'catppuccin/tmux#v2.1.3'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'tmux-plugins/tmux-open'
set -g @plugin 'tmux-plugins/tmux-logging'
set -g @continuum-restore 'on'
set -g @continuum-save-interval '15'
set -g @resurrect-capture-pane-contents 'on'

run '~/.tmux/plugins/tpm/tpm'

# --- pane separation (after tpm so it wins over catppuccin) ---
set -g window-style "bg=#181825"
set -g window-active-style "bg=#1e1e2e"
set -g pane-border-lines heavy
set -g pane-border-style "fg=#313244"
set -g pane-active-border-style "fg=#cba6f7"
set -g pane-border-status top
set -g pane-border-format " #{?pane_active,#[fg=#cba6f7]#[bold],#[fg=#6c7086]}#{b:pane_current_path}#[nobold]#{?pane_active,#[fg=#fab387],#[fg=#6c7086]}#(~/.local/bin/tmux-git-title #{pane_current_path}) "
EOF
```

## 9. tmux plugins (TPM)

```sh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
tmux new-session -d -s setup
tmux run-shell ~/.tmux/plugins/tpm/bindings/install_plugins
tmux kill-session -t setup
```

Or inside tmux: `prefix + I` installs plugins.

## 10. Verify

```sh
fish -c 'echo shell ok'
tmux new -s test    # theme + borders should render; prefix r reloads
```

---

## Cheat sheet

### fish

| Key | Action |
|---|---|
| `ctrl+r` | history search (exact; `'term` for fuzzy) |
| `ctrl+t` | file picker (fd + bat preview) |
| `alt+c` | dir jump (fd) |
| `ctrl+/` | toggle preview in ctrl+r |
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
