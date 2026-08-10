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
        --color=hl:yellow,hl+:bright-yellow,pointer:cyan,marker:green,info:gray,border:gray,prompt:cyan'

    set -gx FZF_CTRL_R_OPTS "
        --exact
        --preview 'echo -- {} | fish_indent --ansi'
        --preview-window=bottom:3:hidden:wrap
        --bind ctrl-/:toggle-preview"

    set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --exclude .git'
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_CTRL_T_OPTS "--preview 'bat --style=numbers --color=always --line-range=:200 {}'"
    set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --exclude .git'

    fzf --fish | source

    zoxide init fish | source
    starship init fish | source

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
    abbr -a ll 'ls -lah'
end

test -f ~/.config/fish/local.fish; and source ~/.config/fish/local.fish
