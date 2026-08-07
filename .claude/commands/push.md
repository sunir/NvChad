---
description: "Add an urgent todo item"
argument-hint: "Urgent task description"
allowed-tools: ["Bash(todo push:*)", "Bash(mktemp:*)", "Bash(cat:*)", "Bash(rm:*)"]
---

```!
# Story: SLASHCMD-ARGUMENTS-QUOTING
# $ARGUMENTS is substituted as raw text before this script runs, so any
# quotes/backticks/$() in the description would otherwise break shell
# parsing. Route it through a file instead of ever quoting it directly.
_push_arg_file="$(mktemp)"
cat > "$_push_arg_file" <<'PUSH_ARGUMENTS_EOF'
$ARGUMENTS
PUSH_ARGUMENTS_EOF
TODO_PROJECT_DIR="$PWD" todo push "$(cat "$_push_arg_file")"
rm -f "$_push_arg_file"
```
