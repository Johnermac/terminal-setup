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
