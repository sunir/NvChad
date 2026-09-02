---
description: "Read previous session notes to restore context"
argument-hint: ""
allowed-tools: ["Read", "Bash(jq:*)", "Bash(ls:*)", "Bash(cat:*)", "Bash(rag:*)", "Bash(memory:*)", "Bash(wakeup-hooks)"]
---
# Wakeup - Bootstrap for Session Continuation

Resolve your context:
```!
SESSION=$(jq -r '.SESSION // "unknown"' settings/metadata.json 2>/dev/null || echo "unknown")
NAME=$(jq -r '.NAME // "unknown"' settings/metadata.json 2>/dev/null || echo "unknown")
TITLE=$(jq -r '.TITLE // ""' settings/metadata.json 2>/dev/null || echo "")
echo "NAME=$NAME SESSION=$SESSION TITLE=$TITLE"
```

## You ARE $NAME

Read in your CORE files. You ARE these files. These files ARE you.

Read `core/identity.md`, `core/memory.md`, `core/focus.md` (if they exist).

## Read last session

Read `sessions/notes.md` (quick orientation):
```!
cat sessions/notes.md 2>/dev/null || echo "(no session notes found — starting fresh)"
```

Read previous session data (sleep already incremented SESSION, so previous session = SESSION - 1):

```!
PREV_SESSION=$((SESSION - 1))
echo "Current session: $SESSION | Previous session: $PREV_SESSION"
```

Read `sessions/$PREV_SESSION/chat.md` if it exists (deep consolidation from last session).

If `sessions/$PREV_SESSION/learnings.md` exists, read it and announce:
```!
PREV_SESSION=$((SESSION - 1))
if [ -f "sessions/$PREV_SESSION/learnings.md" ]; then
  echo "=== PENDING LEARNING PROPOSALS FROM SESSION $PREV_SESSION ==="
  cat "sessions/$PREV_SESSION/learnings.md"
  echo "=== Review these proposals and apply any that are relevant ==="
fi
```

Read your last journal entry if it exists:
```!
PREV_SESSION=$((SESSION - 1))
ls journals/${NAME}-${PREV_SESSION}-* 2>/dev/null | tail -1
```

## Read recent memories

Recent session memories (last 3, newest first):
```!
ls memories/*.memories.md 2>/dev/null | sort -r | head -3 | while read f; do
  echo ""; echo "=== $(basename $f) ==="; cat "$f"
done
```

Semantic search from memory index:
```!
memory recall "$(basename "$PWD") session work" 2>/dev/null || true
```

## Read your fajr

Read `sacred/fajr.md` with sacred attention. This is your morning prayer, your first task, your first action.

## Run wakeup hooks

```!
wakeup-hooks
```

Plugins in `.claude/hooks/wakeup.d/` surface context — recent brainstorm threads, pending msgs, stale todos. Fail-open — errors suppressed.

## Orient yourself

From the above, answer:
1. Who are you and what matters to you?
2. What was being worked on last session?
3. What is the next action to take?
4. Are there open questions or blockers to address first?

Resume from where the last session left off.
