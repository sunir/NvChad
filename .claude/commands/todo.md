---
description: "Add a normal todo item"
argument-hint: "Task description"
allowed-tools: ["Bash(todo add:*)", "Bash(mktemp:*)", "Bash(cat:*)", "Bash(rm:*)"]
---

```!
# Story: SLASHCMD-ARGUMENTS-QUOTING
# $ARGUMENTS is substituted as raw text before this script runs, so any
# quotes/backticks/$() in the description would otherwise break shell
# parsing. Route it through a file instead of ever quoting it directly.
_todo_arg_file="$(mktemp)"
cat > "$_todo_arg_file" <<'TODO_ARGUMENTS_EOF'
$ARGUMENTS
TODO_ARGUMENTS_EOF
TODO_PROJECT_DIR="$PWD" todo add "$(cat "$_todo_arg_file")"
rm -f "$_todo_arg_file"
```
