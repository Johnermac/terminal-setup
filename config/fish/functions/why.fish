function why --description 'Ask Claude why a command failed (cmd 2>&1 | why, or why to re-run the last one)'
    set -l cmd '(piped)'
    set -l out

    if isatty stdin
        set cmd $history[1]
        string match -q 'why*' -- $cmd; and set cmd $history[2]
        read -l -P "re-run `$cmd` to capture its output? [y/N] " ans
        string match -qi y -- $ans; or return 1
        set out (eval $cmd 2>&1 | tail -n 80)
    else
        set out (tail -n 80)
    end

    printf 'cwd: %s\ncommand: %s\noutput:\n%s\n' $PWD "$cmd" (string join \n -- $out) |
        _claude_p sonnet 'A shell command failed. Give the cause in one or two lines, then the exact command that fixes it. No preamble.'
end
