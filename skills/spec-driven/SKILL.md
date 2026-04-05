---
name: spec-driven
description: |
  Spec-driven development with an iterative RLAIF (Reinforcement Learning from AI Feedback) loop.
  Use this skill when the user wants to build something from a spec or requirements, is doing
  spec-first or test-first development, wants to define behavior before writing code, needs to
  refine requirements iteratively, asks "can we spec this out first", mentions BDD, ATDD, or
  specification by example, wants to break down a feature into verifiable units before coding,
  or wants Claude to self-evaluate and improve its own output through iteration.
  The loop: Spec → Implement → Self-Evaluate → Reflect → Iterate until acceptance criteria pass.
---

# Spec-Driven Development Skill

Spec-first engineering with an embedded RLAIF feedback loop. Instead of jumping straight to code,
we define acceptance criteria first — then implement, evaluate against the spec, reflect on gaps,
and iterate. This produces more correct code with fewer surprises.

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
