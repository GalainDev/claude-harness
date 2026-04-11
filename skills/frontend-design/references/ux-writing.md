# UX Writing Reference

## Button Labels

Never use "OK", "Submit", "Yes", or "No". These are ambiguous — users don't know what will happen.

Use verb + object patterns:

| Bad | Good | Why |
|-----|------|-----|
| OK | Save changes | Says what happens |
| Submit | Create account | Outcome-focused |
| Yes | Delete project | Confirms the specific action |
| Cancel | Keep editing | Clarifies what cancelling means |
| Click here | Download PDF | Describes the destination |
| Remove | Delete | "Delete" communicates permanence; "remove" implies recoverable |

**For destructive actions:** name the destruction and show the count.
- "Delete 5 messages" not "Delete selected"
- "Archive team" not "Continue"
- "Cancel subscription" not "Proceed"

---

## Error Messages

Every error answers three questions: what happened, why, and how to fix it.

### Templates

| Situation | Template |
|-----------|----------|
| Format error | "[Field] needs to be [format]. Example: [example]" |
| Missing required | "Please enter [what's missing]" |
| Permission denied | "You don't have access to [thing]. [What to do instead]" |
| Network error | "Couldn't reach [thing]. Check your connection and try again." |
| Server error | "Something went wrong on our end. Try again in a moment." |

### Rules
- Don't blame the user: "Please enter a valid date" not "You entered an invalid date"
- Be specific: "Email must include @" not "Invalid email"
- Give a fix: every error message should end with an action
- Never use humor in error messages — users are already frustrated

---

## Empty States

Empty states are onboarding moments, not dead ends. Three parts:

1. **Acknowledge** — "No projects yet"
2. **Value** — "Create one to start tracking your work"
3. **Action** — a CTA button that starts the relevant flow

Examples:
- "No results for 'search term'. Try a different keyword or browse all items."
- "Your inbox is empty. When teammates mention you, it'll show up here."
- "No activity yet. Share this link to get your first response."

---

## Microcopy by Moment

**Voice** is consistent — your brand's personality.
**Tone** adapts to the moment:

| Moment | Tone | Example |
|--------|------|---------|
| Success | Celebratory, brief | "Done! Your changes are live." |
| Error | Empathetic, helpful | "That didn't work. Here's what to try." |
| Loading | Reassuring | "Saving your work..." |
| Destructive confirm | Serious, clear | "Delete this project? This can't be undone." |
| First-time | Encouraging | "You're all set. Here's what to do first." |
| Destructive complete | Neutral, informative | "Project deleted." (no celebration) |

---

## Link Text

Link text must make sense out of context — screen readers navigate by links:

| Bad | Good |
|-----|------|
| Click here | View pricing plans |
| Learn more | Learn more about team permissions |
| This article | Read the getting started guide |
| Read more | Read the full changelog |

---

## Placeholder Text

Placeholders are not labels. They disappear on input, fail contrast requirements, and create usability problems for users who need to check what a field is for after typing.

**Use placeholders only for:** format examples ("MM/DD/YYYY"), sample values ("e.g. Engineering"), or search hints ("Search by name or email").

**Never use placeholders for:** required information, instructions, or anything users need to reference while typing.

---

## Accessibility in Copy

**Alt text:** describe information, not the image. "Revenue grew 40% in Q4" not "Bar chart". Use `alt=""` for purely decorative images.

**Icon buttons** need `aria-label`. A button containing only a trash icon needs `aria-label="Delete comment"`.

**Form hints and errors** connect to inputs via `aria-describedby`. Both hint and error can be referenced together: `aria-describedby="field-hint field-error"`.

---

## Writing for Translation

German is ~30% longer than English. French ~20%. Plan for it:

| Language | Expansion |
|----------|-----------|
| German | +30% |
| French | +20% |
| Finnish | +30–40% |
| Chinese | −30% characters (but roughly same rendered width) |

**Translation-safe patterns:**
- Numbers separate from text: `"New messages: {count}"` not `"You have {count} new messages"` — word order varies by language
- Full sentences as single strings — don't concatenate halves
- No abbreviations in UI copy: "5 minutes ago" not "5 mins ago"
- Avoid idioms — "hit the ground running" doesn't translate

---

## Consistency

Pick one term per concept and never vary it. Common sources of inconsistency:

| Inconsistent | Consistent |
|-------------|------------|
| Delete / Remove / Clear | Delete |
| Sign in / Log in / Login | Sign in |
| Team / Workspace / Organization | Team |
| Settings / Preferences / Config | Settings |
| Save / Apply / Confirm | Save |

If the codebase uses "workspace", every button, label, error, and empty state uses "workspace". Inconsistency reads as broken — users wonder if "workspace" and "team" are different things.
