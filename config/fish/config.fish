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

# machine-specific extras (version managers, secrets, per-host paths).
# Not tracked in git — created empty by install.sh.
test -f ~/.config/fish/local.fish; and source ~/.config/fish/local.fish
