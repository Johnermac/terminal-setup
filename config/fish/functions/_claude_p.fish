function _claude_p --description 'One-shot headless Claude call on stdin (_claude_p <model> <prompt>)'
    claude -p --model $argv[1] --tools '' --no-session-persistence --settings '{"disableAllHooks":true}' $argv[2..]
end
