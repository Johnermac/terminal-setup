#!/bin/sh
state() {
  case "$1" in
    commit) git write-tree 2>/dev/null ;;
    push) git rev-parse HEAD 2>/dev/null ;;
  esac
}

if [ "$1" = mark ]; then
  gate="$2"
  case "$gate" in commit | push) ;; *)
    echo "usage: review-gates.sh mark commit|push" >&2
    exit 2
    ;;
  esac
  dir=$(git rev-parse --git-dir) || exit 1
  state "$gate" >"$dir/claude-gate-$gate"
  echo "$gate gate recorded for $(cat "$dir/claude-gate-$gate")"
  exit 0
fi

[ "$REVIEW_GATES" = off ] && exit 0
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
if [ -n "$cwd" ]; then
  cd "$cwd" 2>/dev/null || exit 0
fi

case "$cmd" in
  *"review-gates.sh mark"*) exit 0 ;;
  *"git push"*)
    gate=push
    todo="Run the Security assessment and the Validation gate from ~/.claude/CLAUDE.md (Review gates) on the commits being pushed and report the verdicts. Only if validation says READY, run: ~/.claude/hooks/review-gates.sh mark push"
    ;;
  *"git commit"*)
    gate=commit
    todo="Stage the changes in a separate command, run the Code quality assessment from ~/.claude/CLAUDE.md (Review gates) on the staged diff, apply or report the findings, re-stage, then run: ~/.claude/hooks/review-gates.sh mark commit"
    ;;
  *) exit 0 ;;
esac

dir=$(git rev-parse --git-dir 2>/dev/null) || exit 0
now=$(state "$gate")
[ -n "$now" ] && [ "$now" = "$(cat "$dir/claude-gate-$gate" 2>/dev/null)" ] && exit 0

jq -n --arg r "Review gate ($gate) not run on the current state. $todo. Then retry the same $gate command." \
  '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
