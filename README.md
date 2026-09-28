# claude-setup

My configurations, scripts, skills, etc., for Claude Code. Got many things (including this structure) from this [amazing](https://github.com/affaan-m/everything-claude-code) project.

## Dependencies

* serena ([https://oraios.github.io/serena/02-usage/030_clients.html](https://oraios.github.io/serena/02-usage/030_clients.html))
* rtk ([https://github.com/rtk-ai/rtk](https://github.com/rtk-ai/rtk))
* caveman ([https://github.com/JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman))
* mattpocock/skills ([https://github.com/mattpocock/skills](https://github.com/mattpocock/skills))

### Installing mattpocock/skills

The skills in this repo complement the agents here — they handle interactive engineering
workflows (design drilling, tracer-bullet ticketing, TDD loops, debugging) that don't
warrant a full autonomous agent.

**Install via the Claude Code plugin system:**

```bash
claude mcp add --transport http mattpocock-skills https://skills.aihero.dev/mcp
```

Or clone and reference locally if you prefer not to use the hosted MCP:

```bash
git clone https://github.com/mattpocock/skills ~/workspace/mattpocock-skills
# Then add the local path as a project dependency or copy skills into ~/.claude/skills/
```

**Skills that integrate directly with this repo's workflow:**

| Pocock skill | Replaces / complements |
|---|---|
| `/grill-me` | Replaces `planner` agent for interactive design drilling |
| `/wayfinder` | Large-feature planning via decision tickets |
| `/to-spec` + `/to-tickets` | Replaces `tracker-integrator` agent for spec-to-Jira flow |
| `tdd` (model-invoked) | Replaces `tdd-guide` agent for red-green-refactor loops |
| `diagnosing-bugs` (model-invoked) | Hard-bug triage: minimize → hypothesize → instrument → fix |
| `domain-modeling` (model-invoked) | Domain model review, term challenges, edge-case stress tests |
| `/handoff` | Compact conversation → handoff doc for another agent |
| `refactor-clean` (model-invoked) | Complements the `/refactor-clean` command in this repo |

### Installation

Just clone this repo as:

```
# in a fresh install, before the claude installation:
$ git clone https://github.com/GiovaneRibeiro-neuro/claude-setup.git ~/.claude

# or, in an existent claude install:

$ cp -r ~/.claude ~/.claude.bkp
$ git clone https://github.com/GiovaneRibeiro-neuro/claude-setup.git ~/.claude
$ cp -r ~/.claude.bkp/**/*.* ~/.claude/
```

## Tracker integration (optional)

`/track-work` (backed by the `tracker-adapter` skill) creates tracker (Jira) epics/tasks
from an approved plan. Connection details, custom-field mappings, and the card/epic
description template are **per-client**, not host-global — each client gets its own
`TRACKER.md` under `~/workspace/<client_name>/`, resolved at runtime by the
`client-context` skill (walks up from the current working directory looking for a client
folder; asks which client if that fails — see `skills/client-context/SKILL.md`).

Before using `/track-work` for a new client:

1. Copy the blank templates from `~/workspace/_templates/client/` into a new
   `~/workspace/<client_name>/` folder: `VOCABULARY.md`, `CONTEXT-MAP.md`,
   `EPIC-STANDARDS.md`, `TRACKER.md` (and `CONTEXT.md` too, if you'll also use
   `pm-assistant` for Jira health reports/Epic authoring against this client).
2. Fill in `TRACKER.md` with your org's cloud id, project keys, required custom-field
   IDs, and description template — see `skills/tracker-adapter/adapters/jira.md` for the
   concrete Jira call sequence that reads it.
3. Optionally fill in `VOCABULARY.md` if you want stakeholder names auto-suggested for
   an Epic's "Stakeholders" section.

These files hold org-specific values on purpose and live outside this repo entirely —
`~/workspace/<client_name>/` isn't part of `~/.claude`, so there's nothing to gitignore
here. Design history for this and related decisions, if a client has one recorded, lives
at `<client_name>/_docs/adr/` — not in this repo, for the same reason the connection
details above aren't: real org-specific facts shouldn't be committed here even as
historical record.

## Example: a complete development flow

This walks one request through the full agent orchestration this repo defines — see
`rules/common/agents.md` for the roster and sequencing rules referenced below (rule
numbers in parens are that file's).

```mermaid
flowchart TD
    U["User: Add a JWT-protected POST /api/refresh-token\nendpoint, TDD, track it in Jira"] --> ARCH

    ARCH["architect\nvalidates approach, designs the endpoint\n(mandatory first step — rule 1)"] --> MGR

    MGR["manager\ndecomposes into a dispatch table\n(architect's design passed in)"] --> TRACK

    TRACK["/track-work skill\ncreates epic+tasks, reports keys, STOPS\n(opt-in — only because the user asked; rule 6)"] -.->|"explicit user go-ahead\nin conversation — not the table\ncompleting; TRACK never structurally\ngates this, it's a human checkpoint"| TDD

    TDD["tdd skill\nscaffolds failing tests first\n(TDD was requested)"] --> IMPL

    IMPL["Implementation\nmain session writes code to pass the tests"] --> BUILD

    BUILD["build-resolver\nfixes build/vet errors\n(runs before reviewers — rule 2)"] --> REV
    BUILD --> SEC

    subgraph PAR["parallel — same files, non-conflicting (rule 3)"]
        REV["lang-reviewer\nidiomatic Go, error handling"]
        SEC["security-reviewer\nfloor triggered: touches auth + an API endpoint\n(rule 4 — not optional here)"]
    end

    REV --> DOC["doc-updater\nupdates codemaps/docs\n(mandatory, always last — rule 6)"]
    SEC --> DOC
    DOC --> DONE["Report back to user"]
```

### Walkthrough

Scenario: *"Add a JWT-protected `POST /api/refresh-token` endpoint to the auth service,
write tests first, and track it in Jira."*

1. **You** (the main Claude Code session — subagents can't call the `Agent` tool
   themselves, so this orchestration always happens at the top level or in an agent that
   explicitly has `Agent` access) invoke **`architect`** first with the raw request. It
   comes back with a design: token-refresh contract, where it slots into the existing
   auth module, error-handling shape, and any storage/schema implications.

2. You invoke **`manager`** second, including architect's design in the prompt. Manager
   returns a dispatch table. Because the request touches an API endpoint and auth
   (rule 4's floor), `security-reviewer` is in the table even though the user never said
   "security" — manager scans for that regardless of what was asked. Because the user
   *did* ask to track the work, `/track-work` is included too (rule 6) — it
   wouldn't be by default.

3. You execute the table's steps via the `Agent` tool, in the order/parallelism manager
   specified:
   - **`/track-work`** (backed by the `tracker-adapter` skill) creates the epic + linked
     tasks, reports the issue keys/links, and stops. Its approval gate means
     implementation does **not** start yet — that needs your explicit "go" in
     conversation, separate from this table completing.
   - Once you confirm: the **`tdd` skill** scaffolds the failing tests for the new endpoint
     (interface first, per TDD).
   - Implementation happens (in this session or a delegated agent) to make those tests
     pass.
   - **`build-resolver`** runs before any reviewer touches the same code (rule 2),
     clearing build/vet/lint noise so reviewers aren't reading around compile errors.
   - **`lang-reviewer`** and **`security-reviewer`** run **in parallel** (rule 3) — they
     cover the same files but don't conflict, and the security pass is mandatory here
     specifically because of the auth/endpoint floor (rule 4), not because anyone asked
     for it.
   - **`doc-updater`** runs last, unconditionally (rule 6) — updates codemaps/docs even
     though nobody asked for documentation either.

4. Final report to the user bundles: the created Jira issue keys/links, what changed,
   review findings (if any survived), and what docs got touched.

Two things this scenario is chosen to demonstrate:
- **Floors aren't suggestions.** `security-reviewer` and `doc-updater` show up whether or
  not the user's wording mentioned them, because the request's *shape* (an auth-touching
  endpoint; a code change at all) triggers them.
- **Opt-in stays opt-in.** `/track-work` only appears because tracking was
  explicitly requested, and its own completion doesn't unblock implementation — your
  separate confirmation does (see `skills/tracker-adapter/SKILL.md`'s "Approval gate").
