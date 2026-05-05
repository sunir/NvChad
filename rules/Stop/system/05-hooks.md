## Stop Hook

You may be blocked by one or more Stop hook plugins. Each has an escape:

| Block reason | Escape |
|---|---|
| Uncommitted files | `Bash(git add -p && git commit -m "...")` |
| On a feature branch | `Bash(git checkout main)` or merge your branch |
| Active todos | `Bash(todo N defer)` or `Bash(todo N done)` to clear them |
| Automode idle | `Bash(automode relax)` then wait for trigger |
| FocusMode loop | `Bash(focusmode idle)` to stop looping |
| Msgs unread | `Bash(msg read)` then handle or `Bash(msg archive)` |
| Panicking? | `Bash(automode off && hail "Help, I'm stuck because...")` |

**Wrong hook behavior?** `Bash(issues colony/system stophook "what is happening")` — fix the plugin, not your repo.
