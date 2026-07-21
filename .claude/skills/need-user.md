# /need-user — Signal that you need user attention

When you're stuck, blocked, or need user input to proceed, use:

```bash
Bash(hail "I need you to [specific action needed]")
```

## When to use this
- You need clarification on requirements
- You're blocked waiting for external input (API keys, credentials, decisions)
- You've hit a hard error you can't resolve independently
- You need the user to test something in their environment
- You need approval before proceeding with a risky operation

## What happens
The `hail` command sends a notification to the user without breaking your flow. They'll be alerted and can respond when available.

## Examples

```bash
# Need clarification
Bash(hail "I need you to clarify: should the API timeout be 30s or 60s?")

# Blocked on external resource
Bash(hail "I need you to provide the Stripe API key — add it to .env")

# Hard error
Bash(hail "I need you to investigate: database connection failing with error XYZ")

# Approval needed
Bash(hail "I need you to approve before I delete 500 old test files")
```

## What NOT to do
- Don't just announce you're stuck in chat — use `hail` to actually notify
- Don't sit idle waiting — signal immediately when blocked
- Don't ask rhetorical questions — be specific about what you need

## Pattern
The message should always start with "I need you to..." and be specific about the action required.
