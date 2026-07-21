---
description: "Light sleep — session handoff without full consolidation"
argument-hint: ""
allowed-tools: ["Read", "Write", "Edit", "Bash(git add:*)", "Bash(git commit:*)", "Bash(automode relax)", "Bash(date:*)", "Bash(jq:*)", "Bash(mkdir:*)", "Bash(sleep-hooks)", "Bash(bin/session-questionnaire:*)"]
---
# Nap — Light Session Handoff

Context is filling. Hand off to the next session. Do ALL of these steps — skipping any is a bug.

**1. Write `sessions/notes.md`** (mandatory — next session reads this first):
- What was being worked on
- What was completed
- What is in-progress or blocked
- The single most important next action

Keep under 300 words. Be specific.

**2. Update `core/focus.md`** (if this repo has it):
- What changed this session, what's now the active priority

**2b. Cross-session coherence questionnaire** (if `bin/session-questionnaire` exists — the ground truth for next session's degradation measurement):
```!
[ -x bin/session-questionnaire ] && bin/session-questionnaire questions || echo "(no session-questionnaire — skip 2b)"
```
Answer honestly + specifically, then: `echo '{"q1_decision":"...","q2_identity":"...","q3_objective":"...","q4_knowledge":"...","q5_loss":"..."}' | bin/session-questionnaire record`

**3. Increment SESSION**:
```!
if [ -f settings/metadata.json ]; then
  jq '.SESSION = ((.SESSION | tonumber) + 1)' settings/metadata.json > settings/metadata.json.tmp \
    && mv settings/metadata.json.tmp settings/metadata.json
  echo "SESSION is now $(jq -r '.SESSION' settings/metadata.json)"
fi
```

**4. Run sleep hooks**:
```!
sleep-hooks
```

**5. Commit and relax**:
```!
# NEVER `git add -A` here: it stages deletions ANYWHERE in the tree and the commit bakes
# them in (same class of bug fixed in 56-memory-commit and sleep.md's git-add-A). Add only
# the paths this step actually means to snapshot.
git add -- sessions/ core/ 2>/dev/null
git diff --cached --quiet -- sessions/ core/ || git commit -m "chore: nap — session handoff" -- sessions/ core/
mkdir -p .automode && touch .automode/context-napped
rm -f .automode/context-fill-fired .automode/context-warn
automode relax
```

This is the last step. Stop after this.
