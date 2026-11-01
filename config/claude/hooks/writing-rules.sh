#!/bin/sh
jq -Rs '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:.}}' <"$HOME/.claude/writing-rules.md"
