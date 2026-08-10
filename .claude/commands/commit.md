---
description: "Commit current changes with a clear message"
argument-hint: "[optional message]"
allowed-tools: ["Bash(git add:*)", "Bash(git commit:*)", "Bash(git status:*)", "Bash(git diff:*)"]
---
# Git Commit

Check what's changed:
```!
git status --short
git diff --cached --stat
```

If there are staged or unstaged changes, commit them.

## Commit message format

Write a message that explains WHY, not just what:
- One short summary line (under 72 chars)
- Blank line
- Body if needed (what changed and why)
- Always end with:
  ```
  Co-Authored-By: {reponame} (colony/claude)
  ```

## Stage and commit

Stage relevant files (prefer explicit paths over `git add -A`):
```!
git add <files>
git status --short
```

Then commit:
```!
git commit -m "$(cat <<EOF
<your message here>

Co-Authored-By: $(reponame) (colony/claude) 
EOF
)"
```

If the user provided a message as an argument, use it as the commit summary.
