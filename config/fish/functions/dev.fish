function dev --description 'Attach-or-create tmux session for a project (dev <name> [path])'
    if test (count $argv) -eq 0
        set -l session (tmux list-sessions -F '#S' 2>/dev/null | fzf --height=40% --reverse --prompt='session> ')
        test -n "$session"; or return
        _dev_attach $session
        return
    end

    set -l name $argv[1]
    set -l dir $argv[2]

    if not tmux has-session -t $name 2>/dev/null
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
