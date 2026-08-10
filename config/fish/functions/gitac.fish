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
