function assume --description 'Assume an AWS profile in this shell via granted'
    set -q AWS_PROFILE; and set -gx AWS_PROFILE $AWS_PROFILE
    source (command -s assume.fish) $argv
end
