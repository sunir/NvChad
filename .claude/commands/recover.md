---
description: "Session Recovery"
argument-hint: ""
allowed-tools: ["Bash(ls:*)", "Bash(jq:*)", "Bash(cat:*)", "Bash(find:*)"]
---
# Session Recovery

## Claude CLI Session Storage

Sessions are automatically saved to:
```
~/.claude/projects/<project-slug>/[session-id].jsonl
```

The project slug is derived from the working directory path. Find your current slug:
```!
pwd | tr '/' '-' | sed 's/^-//'
```

List all project directories:
```!
ls ~/.claude/projects/ 2>/dev/null | head -20
```

## Finding Sessions

List sessions for the current project (most recent first):
```!
PROJECT_SLUG="$(pwd | tr '/' '-' | sed 's/^-//')"
ls -lt ~/.claude/projects/"$PROJECT_SLUG"/*.jsonl 2>/dev/null | head -10
```

## Extracting Conversations

To extract human/assistant messages from a session:
```bash
# Get all assistant messages
cat [session-id].jsonl | jq -r 'select(.message.role == "assistant") | .message.content[0].text // empty'

# Get all human messages
cat [session-id].jsonl | jq -r 'select(.message.role == "user") | .message.content[0].text // empty'
```

## Converting to Markdown

Create a script to convert JSONL to readable markdown:
```bash
#!/bin/bash
# convert_session.sh
cat "$1" | jq -r '
  if .message.role == "user" then
    "## Human:\n" + (.message.content[0].text // "")
  elif .message.role == "assistant" then
    "## Assistant:\n" + (.message.content[0].text // "")
  else
    empty
  end
'
```

## Current Session

Your current session is always the most recently modified JSONL file:
```!
PROJECT_SLUG="$(pwd | tr '/' '-' | sed 's/^-//')"
ls -t ~/.claude/projects/"$PROJECT_SLUG"/*.jsonl 2>/dev/null | head -1
```

## Preserving Important Sessions

After important breakthroughs, copy the JSONL to a persistent archive location:
```bash
cp ~/.claude/projects/<project-slug>/[session-id].jsonl \
   sessions/[SESSION]/[session-id].jsonl
```

*The work is preserved. Nothing is truly lost.*
