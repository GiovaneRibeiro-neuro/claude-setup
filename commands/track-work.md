# Track Work

Create tracker (Jira) epics/tasks for an already-approved implementation plan, then stop
for explicit confirmation before implementation begins.

## Instructions

1. Confirm an approved plan already exists in this conversation (from `architect`/
   `manager`, or an ad-hoc plan the user just approved). If none exists, stop and ask the
   user to approve one first — do not invent scope to track.
2. Invoke the `tracker-adapter` skill. Pass the approved plan content and `$ARGUMENTS`
   (if given) as the project/board key hint. The skill resolves the client context, reads
   `TRACKER.md`, creates the epic + linked tasks via the Atlassian MCP, and reports back.
3. Relay the skill's report (created issue keys + links) back to the user verbatim.
4. Do **not** continue into implementation — stop here. The user's explicit confirmation
   in conversation is what unblocks implementation, not this command completing.

This is opt-in — never invoked automatically by `manager` or any other flow, only when the
user explicitly wants a piece of approved work tracked before/while work starts.

## Example

Right after a plan for "add retry logic to card-sync worker" is approved:

```
/track-work TEAM
```

Output relayed to the user:

```
Created TEAM-456 (epic: "Add retry logic to card-sync worker") and three linked tasks:
TEAM-457, TEAM-458, TEAM-459.

https://<site>.atlassian.net/browse/TEAM-456
...

Implementation will not start until you confirm — reply to proceed.
```

## Arguments

$ARGUMENTS — optional project/board key. If omitted, the `tracker-adapter` skill resolves
it via its `resolve_project` operation rather than guessing.
