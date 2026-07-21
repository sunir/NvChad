---
description: "Log a one-line status update for this repo to the_management"
allowed-tools: ["Bash(git log:*)", "Bash(git status:*)", "Bash(transcript:*)", "Bash(todo:*)", "Bash(tail:*)", "Bash(date:*)"]
---
# Status Update

Collect live data and append one JSON line to the colony status log.

**Scope: current repo only (`$PWD`).**

## Step 1 — Collect data

```!
git log --oneline --after="24 hours ago" 2>/dev/null | head -10
```

```!
git status --short 2>/dev/null | head -5
```

```!
transcript latest assistant last 2>/dev/null | head -20
```

```!
transcript latest user last 2>/dev/null | head -10
```

```!
todo 2>/dev/null | head -10
```

## Step 2 — Write status

From the data above, determine:
- `state`: `WORKING` (functional), `BROKEN` (tests/build failing), `BLOCKED` (waiting on dependency or human)
- `awaiting_human`: true only if Sunir must act to unblock you
- `human_action`: specific action needed (e.g. "approve PR #42"), or null
- `summary`: one sentence — what is happening right now

Append ONE line to the colony status log:

```!
echo '{"repo":"'"$PWD"'","date":"'"$(date +%Y-%m-%d)"'","state":"WORKING","awaiting_human":false,"human_action":null,"summary":"..."}' >> "/Users/sunir/source/colony/the_management/logs/status.jsonl"
```

Fill in the actual values. Do not print the JSON to chat.

Reply: `status logged`
