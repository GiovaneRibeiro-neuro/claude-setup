---
name: learn
description: Extract and save reusable patterns from the current session as learned notes. Triggers automatically when a non-trivial problem has been solved, or when the user says "save this pattern", "remember this fix", "extract this", or "learn from this".
agents: ["*"]
version: 1.0.0
---

# Learn — Extract Reusable Patterns

Analyze the current session and extract any patterns worth saving as learned notes.

## When to Activate

- A non-trivial problem was solved (error root-caused, workaround found, debugging technique applied)
- User says "save this pattern", "remember this fix", "extract this", "learn from this", or similar
- `continuous-learning` delegates pattern extraction to this skill

Do not activate for trivial fixes (typos, simple syntax errors) or one-time issues (specific API outages).

## What to Extract

Look for:

1. **Error Resolution Patterns**
   - What error occurred?
   - What was the root cause?
   - What fixed it?
   - Is this reusable for similar errors?

2. **Debugging Techniques**
   - Non-obvious debugging steps
   - Tool combinations that worked
   - Diagnostic patterns

3. **Workarounds**
   - Library quirks
   - API limitations
   - Version-specific fixes

4. **Project-Specific Patterns**
   - Codebase conventions discovered
   - Architecture decisions made
   - Integration patterns

## Output Format

Create a note file at `~/.claude/notes/learned/[pattern-name].md`:

```markdown
# [Descriptive Pattern Name]

**Extracted:** [Date]
**Context:** [Brief description of when this applies]

## Problem
[What problem this solves - be specific]

## Solution
[The pattern/technique/workaround]

## Example
[Code example if applicable]

## When to Use
[Trigger conditions - what should activate this skill]
```

## Process

1. Review the session for extractable patterns
2. Identify the most valuable/reusable insight
3. Draft the note file
4. **Scrub sensitive data** (see section below)
5. Ask user to confirm before saving
6. Save to `~/.claude/notes/learned/`

## Sensitive Data Handling (CRITICAL)

Before saving any note file, scan the draft for sensitive values:

- API tokens, passwords, secrets, JWTs
- Account IDs, user IDs, internal numeric IDs
- Internal URLs or hostnames that should not be hardcoded
- Email addresses used as credentials

**For each sensitive value found:**

1. Choose a descriptive env var name (e.g. `JIRA_ACCOUNT_ID`, `GITHUB_TOKEN`)
2. Add it to `~/.my_shell_stuff` in env var format (create the file if it does not exist):
   ```bash
   export VAR_NAME="value"
   ```
3. Replace the hardcoded value in the note draft with `$VAR_NAME`
4. Add a reference table to the note file listing which env vars it depends on and where they are defined:
   ```markdown
   ## Environment Variables (defined in ~/.my_shell_stuff)
   | Var | Purpose |
   |---|---|
   | `$VAR_NAME` | Description of what this holds |
   ```

**Never write raw secrets, tokens, or passwords into note files.**
Non-secret but personally identifying values (account IDs, emails) should also be externalised so the files are safe to share.

## Notes

- Keep focused — one pattern per file
- Prefer descriptive file names (e.g. `kind-docker-service-access.md`, not `fix1.md`)
- Files saved here are git-tracked in the repo under `notes/learned/` — commit them when they stabilize
