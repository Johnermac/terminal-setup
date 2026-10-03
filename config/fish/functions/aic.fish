function aic --description 'Commit staged changes with a Claude-written subject line'
    if git diff --cached --quiet
        echo 'aic: nothing staged' >&2
        return 1
    end

    set -l msg (begin
            git log -10 --pretty=%s 2>/dev/null
            echo ---
            git diff --cached --stat
            git diff --cached | head -c 60000
        end | _claude_p haiku 'Above: the last commit subjects, then a staged diff. Write one commit subject line for the diff in conventional commit format, matching the style of the recent subjects, max 72 chars. Output only the line.' | string trim)
    set msg $msg[1]
    test -n "$msg"; or return 1

    echo $msg
    read -l -P 'commit? [y/e/N] ' ans
    switch $ans
        case y Y
            git commit -m "$msg"
        case e E
            git commit -e -m "$msg"
        case '*'
            return 1
    end
end
