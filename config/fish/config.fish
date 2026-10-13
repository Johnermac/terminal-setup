if status is-interactive
    set -g fish_greeting ''

    fish_add_path -g $HOME/.local/bin $HOME/.cargo/bin $HOME/go/bin /usr/local/go/bin

    set -gx EDITOR vim
    set -gx PAGER less

    set -gx FZF_DEFAULT_OPTS '
        --height=50%
        --layout=reverse
        --border=rounded
        --info=inline
        --cycle
        --pointer=▶
        --marker=✓
        --color=bg+:#313244,spinner:#f5e0dc,hl:#f38ba8,fg:#cdd6f4,header:#f38ba8
        --color=info:#cba6f7,pointer:#f5e0dc,marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7
        --color=hl+:#f38ba8,selected-bg:#45475a,border:#6c7086,label:#cdd6f4'

    set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --exclude .git'
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_CTRL_T_OPTS "--preview 'bat --style=numbers --color=always --line-range=:200 {}'"
    set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --exclude .git'

    fzf --fish | source
    functions -q fzf_configure_bindings; and fzf_configure_bindings --directory= --history= --variables=

    zoxide init fish | source
    starship init fish | source
    command -q atuin; and atuin init fish --disable-up-arrow | source

    abbr -a g git
    abbr -a gs git status
    abbr -a ga git add
    abbr -a gc git commit
    abbr -a gco git checkout
    abbr -a gd git diff
    abbr -a gl 'git log --oneline --graph -20'
    abbr -a gp git push
    abbr -a d docker
    abbr -a dc 'docker compose'
    abbr -a dps 'docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"'
    abbr -a k kubectl
    abbr -a kg 'kubectl get'
    abbr -a kd 'kubectl describe'
    abbr -a tf terraform
    abbr -a cat bat
    abbr -a bcp 'bat -p'
    if command -q eza
        abbr -a ll 'eza -la --git --icons --group-directories-first'
        abbr -a lt 'eza --tree --level=2 --git-ignore --icons'
    else
        abbr -a ll 'ls -lah'
    end
end

test -f ~/.config/fish/local.fish; and source ~/.config/fish/local.fish
