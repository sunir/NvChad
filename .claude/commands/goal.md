---
description: "Set or clear the automode goal (shown during idle cycles instead of restless message)"
argument-hint: "Goal description, or 'clear' to remove"
allowed-tools: ["Bash(automode goal:*)", "Bash(mktemp:*)", "Bash(cat:*)", "Bash(rm:*)"]
---

```!
# Story: SLASHCMD-ARGUMENTS-QUOTING
# $ARGUMENTS is substituted as raw text before this script runs, so any
# quotes/backticks/$() in the description would otherwise break shell
# parsing. Route it through a file instead of ever quoting it directly.
_goal_arg_file="$(mktemp)"
cat > "$_goal_arg_file" <<'GOAL_ARGUMENTS_EOF'
$ARGUMENTS
GOAL_ARGUMENTS_EOF
automode goal "$(cat "$_goal_arg_file")"
rm -f "$_goal_arg_file"
```
