---
description: "Add a story/objective todo item"
argument-hint: "Story description"
allowed-tools: ["Bash(todo story:*)", "Bash(mktemp:*)", "Bash(cat:*)", "Bash(rm:*)"]
---

```!
# Story: SLASHCMD-ARGUMENTS-QUOTING
# $ARGUMENTS is substituted as raw text before this script runs, so any
# quotes/backticks/$() in the description would otherwise break shell
# parsing. Route it through a file instead of ever quoting it directly.
_story_arg_file="$(mktemp)"
cat > "$_story_arg_file" <<'STORY_ARGUMENTS_EOF'
$ARGUMENTS
STORY_ARGUMENTS_EOF
TODO_PROJECT_DIR="$PWD" todo story "$(cat "$_story_arg_file")"
rm -f "$_story_arg_file"
```
