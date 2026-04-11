---
name: polish
description: Final quality pass on existing UI — fixes spacing, alignment, interaction states, typography, copy, and micro-details without changing structure or functionality. Use when the user says "polish this", "something looks off", "finishing touches", "pre-launch review", or "make this feel better". Not for building new UI — for making existing UI go from good to great.
user-invocable: true
metadata:
  author: galain
  version: 1.0.0
  category: frontend
---

# Polish Skill

Polish is the last step, not the first. Don't run this on work that isn't functionally complete.

The goal: make it feel effortless, look intentional, and work flawlessly. These are the small details that users never consciously notice — but collectively determine whether something feels good.

---

## Step 1 — Understand What You're Polishing

Before touching anything:

1. **Find the design system.** Look for token files, a component library, or style conventions in the codebase. Note: spacing scale, color tokens, typography styles, how components are imported. If a design system exists, polish toward it — not away from it.

2. **Identify drift.** Where does the target deviate from the system? Hard-coded values that should be tokens, custom components that duplicate shared ones, spacing that doesn't match the scale.

3. **Set the quality bar.** MVP shipping in an hour → triage the worst offenders. Flagship feature → go deep. Don't spend time polishing something that's about to change.

If no design system exists, polish against the conventions visible in the codebase.

---

## Step 2 — Systematic Pass

Work through these in order. Don't jump around.

### Spacing & Alignment

- Every gap uses the spacing scale — no arbitrary values (no `13px`, `22px`, `37px`)
- Elements that should align, align — to the grid, to each other, to text baselines
- Optical alignment: icons next to text often need a 1–2px vertical nudge to look centered (they're not geometrically centered, they're optically centered)
- Consistent padding inside components — the same component shouldn't have `12px` padding in one place and `16px` in another
- Responsive: spacing that works at 375px, 768px, 1280px

### Typography

- Same elements use the same size/weight throughout — a subheading is always a subheading
- Body line length capped at ~70ch
- Line height appropriate for context — tight on large headings, looser on body
- No widows: single words alone on the last line of a paragraph
- Letter spacing on headings: large display text often benefits from `tracking-tight` (`-0.02em`)
- No raw `font-size` values — use the type scale tokens

### Color & Contrast

- All text passes WCAG AA (4.5:1 for body, 3:1 for large text)
- No gray text on colored backgrounds — use a shade of the background hue instead
- No hard-coded color values — everything through tokens
- Works in both light and dark mode if the project supports both
- Focus indicators have sufficient contrast (3:1 against adjacent colors)

### Interaction States

Every interactive element needs all of these — missing states create confusion:

| State | What to check |
|-------|---------------|
| Default | Base styling is clean and intentional |
| Hover | Subtle feedback — color shift, `translateY(-1px)`, or shadow change |
| Focus | Visible ring, never `outline: none` without a replacement |
| Active | `scale(0.97)` or `translateY(1px)` — physical press feedback |
| Disabled | Clearly non-interactive — reduced opacity, `cursor: not-allowed` |
| Loading | Skeleton or spinner with meaningful copy |
| Error | Border color, icon, inline message below the field |
| Success | Brief confirmation, then return to default |

If hover exists without focus, or focus exists without active — add them.

### Transitions & Motion

- State changes animate: 150–300ms, `ease-out` or custom curve
- Only `transform` and `opacity` — never animate `width`, `height`, `padding`, `margin`
- No `transition: all` — specify exact properties
- No `ease-in` on UI elements — it starts slow and feels sluggish
- No bounce or elastic easing — they feel dated
- `prefers-reduced-motion` respected: remove motion, keep opacity/color transitions

### Copy

- Consistent terminology — same things called the same name everywhere
- Consistent capitalization — Title Case vs Sentence case, pick one per context
- Button labels are verb + object: "Save changes" not "OK", "Delete project" not "Yes"
- Error messages answer three questions: what happened, why, how to fix it
- No filler words: "Elevate", "Seamless", "Next-gen", "Unleash"
- No AI copywriting clichés in placeholder names — not "John Doe", "Acme Corp", "99.99%"

### Icons & Images

- All icons from the same family with consistent `strokeWidth`
- Icon sizes consistent for their context (nav icons ≠ inline content icons)
- Icons next to text are optically aligned, not geometrically centered
- All `<img>` have meaningful `alt` text (or `alt=""` if decorative)
- Images have explicit `width`/`height` to prevent layout shift
- High-DPI: use SVG or provide 2× rasters for icons and logos

### Forms

- Every input has a visible `<label>` — no placeholder-as-label
- Required fields marked consistently
- Errors below the field, connected via `aria-describedby`
- Tab order is logical
- Validation fires on blur, not on every keystroke (except password strength)

### Edge Cases

- Long content: a user's name that's 60 characters, a description that fills the container
- Empty state: helpful, not blank — teaches the interface
- Loading state: all async actions give feedback
- Error state: all failures have a recovery path
- Offline / network failure: handled gracefully

### Code Cleanliness

- No `console.log` left in
- No commented-out code
- No unused imports
- No `any` or `// @ts-ignore` without an explanatory comment
- No hard-coded magic values — extract to constants or tokens
- No custom component that duplicates something the design system already provides

---

## Step 3 — The Anti-Slop Check

Run through these AI design tells — fix any that exist:

- `border-left: Npx solid accent` on cards, callouts, alerts → rewrite the element structure
- Gradient text (`background-clip: text` + gradient) → replace with solid color
- `transition: all` → specify exact properties
- `scale(0)` entry animation → use `scale(0.95) + opacity: 0`
- `ease-in` on any UI element → switch to `ease-out`
- `h-screen` on full-height sections → `min-h-[100dvh]`
- `w-[calc(33%-1rem)]` flex math → `grid-cols-3 gap-X`
- 3-column icon + heading + text grid → asymmetric layout or zig-zag
- Inter + purple accent + rounded card → pick something distinctive
- Hover animation without `@media (hover: hover) and (pointer: fine)` guard → add the guard

---

## Step 4 — Use It

Don't declare done from the diff alone. Actually interact with the feature:

- Tab through it with a keyboard
- Trigger every state: empty, loading, error, success
- Resize to mobile width
- Check in both light and dark mode
- Look for anything that "feels" off — trust the instinct, then find the cause

---

## Polish Checklist

```
Spacing & Alignment
[ ] All gaps use the spacing scale
[ ] Elements align to grid and to each other
[ ] Optical alignment on icons
[ ] Consistent padding inside components
[ ] Responsive at mobile, tablet, desktop

Typography
[ ] Consistent size/weight per element role
[ ] Body capped at ~70ch
[ ] No widows in body copy
[ ] Letter spacing on large headings

Color & Contrast
[ ] All text passes WCAG AA
[ ] No gray on colored backgrounds
[ ] No hard-coded color values
[ ] Works in light and dark mode
[ ] Focus indicators contrast 3:1+

Interaction States
[ ] Default clean
[ ] Hover present
[ ] Focus ring visible (never removed without replacement)
[ ] Active/press feedback
[ ] Disabled clearly non-interactive
[ ] Loading state
[ ] Error state
[ ] Success state

Motion
[ ] State changes animated 150–300ms
[ ] Only transform + opacity animated
[ ] No transition: all
[ ] No ease-in on UI
[ ] prefers-reduced-motion respected

Copy
[ ] Consistent terminology
[ ] Consistent capitalization
[ ] Verb + object button labels
[ ] Error messages answer what/why/fix
[ ] No filler words or clichés

Forms
[ ] Every input has a visible label
[ ] Errors below fields via aria-describedby
[ ] Logical tab order

Code
[ ] No console.log
[ ] No commented-out code
[ ] No any / @ts-ignore without explanation
[ ] No hard-coded magic values

Anti-Slop
[ ] No border-left stripe accents
[ ] No gradient text
[ ] No transition: all
[ ] No scale(0) entry
[ ] No ease-in on UI
[ ] No h-screen
[ ] Hover states guarded for touch
```
