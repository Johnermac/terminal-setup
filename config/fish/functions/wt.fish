function wt --description 'Git worktree per task with its own Claude window (wt <task> [base] | wt ls | wt rm <task>)'
    set -l common (git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    or begin
        echo 'wt: not in a git repo' >&2
        return 1
    end
    set -l main (path dirname $common)
    set -l trees $main.wt

    switch "$argv[1]"
        case ''
            echo 'usage: wt <task> [base] | wt ls | wt rm <task>' >&2
            return 1
        case ls
            git worktree list
        case rm
            _wt_check_name $argv[2]; or return
            git worktree remove $trees/$argv[2]; or return
            git branch -d wt/$argv[2]
        case '*'
            set -l task $argv[1]
            _wt_check_name $task; or return
            set -l dir $trees/$task
            if set -q argv[2]; and begin
                    test -d $dir; or git show-ref --verify --quiet refs/heads/wt/$task
                end
                echo "wt: wt/$task already exists, ignoring base '$argv[2]'" >&2
            end
            if not test -d $dir
                if git show-ref --verify --quiet refs/heads/wt/$task
                    git worktree add $dir wt/$task; or return
                else
                    git worktree add -b wt/$task $dir $argv[2]; or return
                end
            end
            if set -q TMUX
                tmux new-window -n $task -c $dir claude
            else
                cd $dir
            end
    end
end

function _wt_check_name
    if contains -- "$argv[1]" ls rm
        echo "wt: '$argv[1]' is a subcommand, pick another task name" >&2
        return 1
    end
    string match -qr '^[A-Za-z0-9._-]+$' -- "$argv[1]"; and return
    echo "wt: task name must match [A-Za-z0-9._-]+, got '$argv[1]'" >&2
    return 1
end
