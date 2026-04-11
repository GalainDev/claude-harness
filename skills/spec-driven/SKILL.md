---
name: spec-driven
description: Spec-driven development with a living overview and RLAIF loop. ALWAYS activates when the user discusses a new feature, app, or system — even in early conversation. Continuously updates specs/overview.md as requirements emerge. Use /decompose to break the overview into atomic task specs when ready to build. Each task spec runs its own Implement → Evaluate → Reflect → Iterate loop. Also triggers on "spec this out", "let's plan", "I want to build", BDD/ATDD mentions, or any feature discussion.
user-invocable: true
metadata:
  author: galain
  version: 1.0.0
  category: engineering
---

# Spec-Driven Development Skill

Two levels: an **overview** that evolves through conversation, and **task specs** that are small enough to implement and verify in one RLAIF loop.

**Don't wait to be asked.** When the user describes a feature or app — even casually — start capturing it in `specs/overview.md`. Update it continuously as the conversation develops. When the user is ready to build, `/decompose` breaks the overview into task specs.

---

## Level 1 — Overview Spec (always-on)

`specs/overview.md` is a living document. It is never "done" — it grows with the conversation.

Create it the moment a feature or app is being discussed. Update it after every meaningful exchange. It does not need to be complete or correct before you start — that's the point.

### Structure

```markdown
# Overview: [Feature / App Name]

**Last updated:** [date]
**Status:** Exploring | Ready to decompose | In progress | Done

## What we're building
[One paragraph. What is this, who uses it, what problem does it solve.]

## Scope
### In
- [confirmed things that are included]

### Out
- [explicitly excluded — equally important]

## Requirements emerging from conversation
- [bullet per requirement as it surfaces — not yet acceptance criteria, just captured]

## Open questions
- [ ] [unresolved things that will affect design or implementation]

## Decisions made
- [date] [decision] — [why]

## Proposed task breakdown
[filled in by /decompose — leave blank until then]
```

### Rules for keeping it current

| What happens in conversation | What you do |
|------------------------------|-------------|
| User describes the feature | Create overview.md, fill in What/Scope |
| A new requirement surfaces | Add to Requirements |
| User rules something out | Move to Scope: Out |
| An open question gets answered | Check it off, move to Decisions |
| User changes direction | Update overview, note the pivot in Decisions |
| A constraint is mentioned | Capture it immediately |

Never let more than one exchange pass without updating the overview if something relevant was said.

---

## Level 2 — Task Specs (/decompose)

When the overview has enough clarity to build — the user says "let's go", "start implementing", or you judge the scope is sufficiently understood — run decompose.

### /decompose

```bash
./skills/spec-driven/scripts/new-spec.sh --task "task name"
```

Decompose the overview into task specs following these rules:

**Each task spec must be:**
- **Atomic** — one concern, one area of the codebase
- **Independently shippable** — doesn't require another task to be testable
- **Small** — 3–7 acceptance criteria max. If you need more, split it.
- **Verifiable** — every AC can be checked by `rlaif-loop.sh` (type check, lint, test)

**Signs a task is too big:**
- More than 7 ACs
- Touches more than 2 files/components
- Requires another task to be "mostly done" first
- You can't write a test for it without mocking half the system

### Task spec structure

```markdown
---
status: todo
---

# Task: [Name]

**Overview:** specs/overview.md
**Date:** [date]

## Context
[One sentence: what this task does and why it exists in the broader feature]

## Acceptance Criteria
- [ ] AC1: Given [precondition], when [action], then [observable outcome]
- [ ] AC2: ...

## Out of scope for this task
- [things that belong to other tasks]

## Definition of done
- [ ] All ACs pass
- [ ] Types check / go build passes
- [ ] Tests cover happy path + edge cases in spec
- [ ] No regressions
```

### Proposed decomposition for a website

```
specs/
  overview.md              ← the full picture
  task-landing-page.md     ← hero, nav, CTA only
  task-contact-form.md     ← form, validation, submission
  task-responsive.md       ← breakpoint work across all pages
  task-accessibility.md    ← contrast, keyboard nav, ARIA
```

Update `specs/overview.md` Proposed task breakdown section with the full list once decomposed.

---

## Task Status Lifecycle

Every task spec has a `status` field in its frontmatter. **Keep it current — this is how you pick up where you left off after closing a session.**

| Status | Meaning |
|--------|---------|
| `todo` | Created, not started |
| `in_progress` | Actively being implemented |
| `blocked` | Waiting on another task or external input |
| `done` | All ACs checked off, verify passed |

**Rules:**
- Set `in_progress` when you start implementing a task
- Set `done` immediately when all ACs pass and `verify.sh` is green — don't batch updates
- Set `blocked` with a note in the spec explaining what's blocking
- **After every 2–3 completed implementations, scan all task specs and update any stale statuses**

**Session resume:** at the start of a new session, run:
```bash
grep -r "^status:" specs/task-*.md 2>/dev/null | sort
```
This gives you the full picture of what's done, in progress, and todo — so you can pick up exactly where you left off without re-reading everything.

---

## RLAIF Loop (per task spec)

Run this loop for each task spec. Do not run it on the overview.

```
1. IMPLEMENT  Minimal code to satisfy the spec ACs
      ↓
2. EVALUATE   Run: ./skills/spec-driven/scripts/rlaif-loop.sh specs/task-name.md
              Score each AC: ✅ Pass | ❌ Fail | ⚠ Partial
      ↓
3. REFLECT    For each failure: root cause, not symptom
              Classify: implementation error | spec ambiguity | scope creep
      ↓
4. ITERATE    Targeted fix → back to EVALUATE
              Max 3 iterations before surfacing to user
      ↓
DONE when all ACs pass → check them off in the task spec → update overview status
```

---

## Red Flags

- Waiting for the user to explicitly ask for a spec before capturing requirements — too late
- Overview with more than 15 bullet requirements — time to decompose
- Task spec with more than 7 ACs — split it
- ACs that say "works correctly" or "handles errors" — not testable, rewrite
- Running RLAIF on the overview instead of a task spec
- Spec written after implementation — that's documentation

## The RLAIF Loop

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│  1. SPEC      Define clear, testable criteria       │
│       ↓                                             │
│  2. IMPLEMENT Write the minimal code that could     │
│               satisfy the spec                      │
│       ↓                                             │
│  3. EVALUATE  Check each criterion — pass/fail/gap  │
│       ↓                                             │
│  4. REFLECT   Diagnose failures; identify root      │
│               cause, not just symptoms              │
│       ↓                                             │
│  5. ITERATE   Targeted fix → back to EVALUATE       │
│       ↓                                             │
│  DONE when all criteria pass (or are explicitly     │
│  deferred with a decision record)                   │
└─────────────────────────────────────────────────────┘
```

---

## The Spec File Is the Source of Truth

Every non-trivial feature starts with a `spec.md` in the project root (or `specs/<feature>.md`
for multi-feature projects). **This file is never final — update it continuously** as you learn.

### When to update spec.md

| Event | Update |
|-------|--------|
| An open question gets answered | Move from Open Questions → Decisions Made |
| An AC is found to be ambiguous | Rewrite the AC with a concrete example |
| An AC is found impossible or out of scope | Move to Out of Scope with reasoning |
| A new edge case is discovered mid-impl | Add a new AC or note it in Decisions Made |
| A technical approach is chosen | Document the choice and rationale |
| An AC passes verification | Check it off: `- [x] AC1: ...` |

The spec is not a contract — it's a living record of what we know, what we decided, and why.
A fully checked-off spec with a complete Decisions Made section is the artifact of done work.

---

## Process

### Phase 1: Spec

Before writing a single line of code, produce a spec document. This takes 5–15 minutes and
saves hours of rework.

**Spec structure:**
```markdown
## Feature: [Name]

### Context
[One paragraph: why does this exist, who uses it, what problem does it solve]

### Acceptance Criteria
- [ ] AC1: Given [precondition], when [action], then [observable outcome]
- [ ] AC2: ...
- [ ] AC3: Edge case — [scenario] results in [behavior]

### Out of Scope
- [Things explicitly NOT included in this feature]

### Open Questions
- [Unknowns that need to be resolved before or during implementation]

### Definition of Done
- [ ] All ACs pass
- [ ] Types check
- [ ] Tests cover happy path + at least 2 edge cases
- [ ] No regressions in adjacent features
```

**Spec quality checks:**
- Each criterion is **testable** — you can write a test that proves it passes or fails
- Each criterion is **atomic** — one observable outcome per criterion
- "Should" is vague — use "does", "returns", "renders", "throws"
- No implementation details in the spec — describe behavior, not mechanism

### Phase 2: Implement

Write the minimal code to satisfy the spec. No gold-plating.

- Start with the data shape and interfaces
- Implement the happy path first
- Add edge case handling after each AC is mapped to code
- Write tests alongside implementation (or test-first if the AC is very clear)

### Phase 3: Evaluate

Score the implementation against each AC:

| Criterion | Status | Evidence |
|-----------|--------|----------|
| AC1       | ✅ Pass | test `TestAC1` passes |
| AC2       | ❌ Fail | returns 200 instead of 201 |
| AC3       | ⚠ Partial | works for strings, fails for null |

Be honest about partial passes — a partial pass is a fail for shipping purposes.

### Phase 4: Reflect

For each failing criterion:
1. **Identify the root cause** — don't just describe the symptom
2. **Classify the gap**:
   - *Implementation error* — code doesn't match intent (fix the code)
   - *Spec ambiguity* — criterion is underspecified (clarify the spec first)
   - *Scope creep* — criterion wasn't in original scope (decide: include or defer)
3. **Plan the fix** — one sentence describing what changes

### Phase 5: Iterate

Apply targeted fixes. Only change what's needed to address the failing criteria.
After each fix, re-run the full evaluation — a fix for AC2 should not break AC1.

**Maximum iterations before escalating to user:** 3
If the same criterion keeps failing after 3 attempts, surface the issue — there's likely
a deeper problem with the spec, an external dependency, or a fundamental assumption that
needs user input.

---

## Scripts

### Generate a spec template
```bash
./skills/spec-driven/scripts/new-spec.sh "Feature Name"
```

### Run the RLAIF evaluation loop
```bash
./skills/spec-driven/scripts/rlaif-loop.sh specs/my-feature.md
```

---

## Spec-Driven for Different Contexts

### API endpoint spec
```markdown
## POST /users

### Acceptance Criteria
- [ ] Returns 201 with `{ id, email, createdAt }` on valid input
- [ ] Returns 400 with `{ error: "email required" }` when email missing
- [ ] Returns 409 when email already exists
- [ ] Does NOT return password hash in any response
- [ ] Idempotent with same email within 1 second (dedup)
```

### React component spec
```markdown
## UserCard component

### Acceptance Criteria
- [ ] Renders user name and avatar
- [ ] Shows "Follow" button when `isFollowing=false`
- [ ] Shows "Unfollow" button when `isFollowing=true`
- [ ] Calls `onFollow(userId)` when Follow clicked
- [ ] Shows skeleton while loading
- [ ] Is keyboard navigable (Tab to button, Enter/Space to activate)
```

### Refactor spec
```markdown
## Refactor: Extract auth middleware

### Acceptance Criteria
- [ ] All existing auth tests still pass
- [ ] Auth logic is in one file, not duplicated across 3 handlers
- [ ] Public routes remain accessible without auth header
- [ ] Protected routes still return 401 without valid token
- [ ] No behavior changes — this is structural only
```

---

## Red Flags

- Spec written after implementation — that's documentation, not a spec
- ACs reference implementation details ("uses useState") rather than behavior
- More than 8 ACs for a single feature — split the feature
- ACs that say "works correctly" or "handles errors" — too vague to test
- Skipping the reflect phase and jumping straight to more code
- Treating the spec as immutable — it's a living document; update it when you learn more

---

## Decision Record for Deferred Items

When an AC is explicitly deferred (not just forgotten):
```markdown
## Decision: [AC description] deferred

- **Date:** [date]
- **Reason:** [why it's not being done now]
- **Condition for revisit:** [what would trigger picking this up]
- **Risk of deferral:** [what could go wrong by not doing this now]
```
