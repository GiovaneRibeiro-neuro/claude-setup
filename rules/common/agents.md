# Agent Orchestration

## Agent roster

| Agent | When to use |
|---|---|
| manager | Decompose complex multi-step/multi-domain user requests, dispatch to specialists. |
| architect | System design, scalability, architectural trade-offs. Mandatory first step in any `manager` plan. |
| code-reviewer | General code review for quality/security/maintainability. Use after any code change. |
| security-reviewer | Vulnerability detection after code touching input, auth, endpoints, secrets. |
| lang-reviewer | Language-specific code review for Go, Java, Python, and Rust — auto-detects from changed files. Replaces the former per-language reviewer agents. |
| build-resolver | Fix build/vet/lint/compilation failures for Go, Java/Maven/Gradle, and Rust/Cargo — auto-detects from build files. Replaces the former per-language build resolver agents. |
| doc-updater | Update docs/codemaps. Mandatory last step in any `manager` plan. |
| pm-assistant | Jira board health reports, Epic authoring, executive summaries, sprint retros. |

## Agent vs skill

**Agent** = own context window, tool access, autonomy; does multi-step judgment where the path isn't predetermined.
**Skill** = reference knowledge or fixed procedure loaded into the caller's context; no autonomy, caller already decided to act.

When adding new capability: if it requires branching judgment across multiple steps, it's an agent. If it's know-how or a checklist consumed by an already-deciding caller, it's a skill.

## Skill<->agent frontmatter convention

Skill files may declare `agents: ["name", ...]` (or `agents: ["*"]` for any agent) to indicate intended callers.
Agent files may declare `skills: ["name", ...]` to indicate skills that agent is expected to invoke via the Skill tool.

**Limitation:** this is a documentation/prompt convention, not access control. The Skill tool resolves by name only and does not check caller identity. Treat these fields as a discoverability aid for humans and tooling (e.g. `skill-health`), not a security boundary. Don't force-fit links that aren't real — an empty `skills: []` is correct when no genuine overlap exists.

## Caveman-ultra dispatch

Subagents run in fresh sessions and do not inherit the main session's caveman flag file (`~/.claude/.caveman-active`). There is no peer-to-peer agent messaging in Claude Code — a dispatched agent's only channel back is its final text report to whoever invoked it. So every dispatch prompt must explicitly request caveman-ultra style:

```
Respond in caveman-ultra style per the caveman skill (abbreviate, strip conjunctions,
one word where one word suffices). Keep code blocks, error messages, and security
warnings verbatim — do not compress those.
```

## Invoking manager

Subagents in this harness cannot call the Agent tool themselves — no nested delegation. So `manager` cannot invoke `architect` on its own, even though architect validation is mandatory. Whoever invokes `manager` (the main session, or another agent with Agent-tool access) must:

1. Invoke `architect` first with the user's request.
2. Invoke `manager` second, including architect's output in the prompt.
3. Execute each step of manager's returned dispatch table in order, via the Agent tool.

If `manager` is invoked without an architect design already in the prompt, it will refuse to fabricate a plan and instead ask its caller to run step 1 first.

## Manager plan sequencing rules

1. `architect` always runs first — mandatory plan composition/validation step, never skipped.
2. `build-resolver` runs before reviewers touching the same code.
3. `lang-reviewer` and `code-reviewer` run in parallel when they don't conflict on the same files.
4. `security-reviewer` is conditional, not unconditional like `doc-updater` — but the condition is a floor, not a suggestion: **any** step touching auth, secrets/credentials, user input parsing, deserialization, or API endpoints MUST get a `security-reviewer` pass, in parallel with `lang-reviewer` covering the same files, regardless of whether the user asked for a security review. Manager must scan each step's description against this list before finalizing the plan, not just wait for the user to mention security.
5. `doc-updater` always runs last — mandatory documentation step, included even if the user's request never mentioned documentation.
6. `/track-work` (skill) is opt-in — not a floor like `security-reviewer`, not unconditional like `doc-updater`. Include it in the dispatch table ONLY when the user's request explicitly signals they want this work tracked (e.g. "create a Jira card for this", "track this epic"). When included: it runs after `architect` validates the plan, and its step never gates subsequent implementation — the user's separate, explicit "go" in conversation is what unblocks implementation.
