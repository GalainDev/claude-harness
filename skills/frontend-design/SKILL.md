---
name: frontend-design
description: Create distinctive, production-grade frontend interfaces with high design quality. ALWAYS triggers alongside react-frontend — any new React component, page, or layout work requires this skill first for visual direction. Also triggers when the user asks to build web components, pages, or applications (landing pages, dashboards, marketing sites, any UI), or says "make it look good", "design this", "build a UI", "add a page", "create a component". Generates creative, polished code that avoids generic AI aesthetics — covers visual direction, typography, color, layout, and motion. Do not skip this for "small" components — design direction applies even to buttons and forms.
user-invocable: true
metadata:
  author: galain
  version: 1.0.0
  category: frontend
---

# Frontend Design Skill

Ship interfaces that feel intentional. The goal is code a designer would be proud of and an
engineer can maintain — not AI slop that looks like every other generated UI from 2024.

---

## Before Any Design Work — Get Context

Generic output comes from missing context. Before touching a pixel, confirm:

- **Who uses this?** Role, context, device, time of day they're likely using it
- **What's the job?** What are they trying to accomplish in one sentence
- **What should it feel like?** Pick 3 concrete words — not "modern", not "clean" (dead words)

If this isn't clear from the brief or existing codebase, ask before designing.

---

## Visual Direction

Pick a direction and commit. Half-committed aesthetics look worse than a strong choice executed simply.

Before writing any code, state:
1. **Aesthetic direction** — one sentence, concrete (e.g. "editorial print meets dark dashboard", not "sleek and modern")
2. **Theme** — dark or light, derived from audience and context, not default
3. **Differentiator** — the one thing someone will remember about this interface

**Theme selection is not a default.** Derive it:
- Tool used in dark offices by engineers at night → dark
- Patient-facing hospital portal on a phone → light
- Trading terminal during fast sessions → dark
- Wedding planning tool on a Sunday morning → light
- Children's reading app → light

Don't default to dark because it "looks cool". Don't default to light to "play it safe". Choose.

---

## Typography

See [references/typography.md](references/typography.md) for full font guidance.

**Always apply:**
- Modular type scale with `clamp()` for marketing/content pages. Fixed `rem` scale for app UIs and dashboards.
- Minimum 1.25 ratio between scale steps. Flat hierarchies (sizes too close together) read as noise.
- Line-height scales inversely with font size. Large headings want tighter leading. Long body copy wants more.
- Cap body line length at ~65–75ch. Beyond that the eye fatigues tracking back.
- For light text on dark backgrounds, add 0.05–0.1 to line-height — light type reads thinner and needs room.

**Font selection — do this before picking any font name:**

1. Write 3 concrete brand-voice words. Not "elegant", not "modern" — those are empty. Try: "warm and mechanical", "dense and unimpressed", "handmade and slightly weird".
2. List the 3 fonts you'd normally reach for. Check against the reject list below.
3. If any of your choices appear in the reject list, go find something else. These are your training-data defaults and they produce monoculture across every project.

**Reject list — never use these:**
Inter, Roboto, Open Sans, DM Sans, Plus Jakarta Sans, Outfit, Instrument Sans, Instrument Serif,
Fraunces, Newsreader, Lora, Crimson Pro, Playfair Display, Cormorant, Syne,
IBM Plex Sans, IBM Plex Mono, Space Grotesk, Space Mono

4. Browse for something that fits the brand as a *physical object* — a fabric label, a mainframe terminal manual, a hand-painted shop sign. Reject the first thing that "looks designy" — that's also a trained reflex.

**Rules:**
- Pair a distinctive display font with a refined body font. Never use one family for everything.
- Don't use monospace as shorthand for "technical vibes". That's lazy.
- Don't put a large rounded icon above every heading. It looks templated.
- Don't set long body passages in all-caps. Reserve uppercase for short labels.

---

## Color

See [references/color.md](references/color.md) for palette construction and accessibility.

**Always apply:**
- Use `oklch()`, not `hsl()`. OKLCH is perceptually uniform — equal lightness steps look equal. HSL is not.
- As lightness approaches white or black, reduce chroma. High chroma at extreme lightness looks garish. A light blue at L=85% wants chroma ~0.08, not 0.15.
- Tint your neutrals toward your brand hue. Even `oklch(95% 0.007 240)` is perceptible and creates subconscious cohesion between surfaces and brand.
- 60-30-10 by visual weight: 60% neutral surface, 30% secondary text/borders, 10% accent. Accents work because they're rare.

**Hard bans:**
- No pure `#000` or `#fff`. Always tinted.
- No gray text on colored backgrounds — it looks washed out. Use a shade of the background color instead.
- No AI color palette: cyan-on-dark, purple-to-blue gradients, neon accents on dark.
- No gradient text (`background-clip: text` + gradient). Use solid color. For emphasis, use weight or size.

---

## Layout & Space

See [references/layout.md](references/layout.md) for grid patterns and container queries.

**Always apply:**
- 4pt spacing scale with semantic names: `--space-xs: 4px`, `--space-sm: 8px`, `--space-md: 16px`, `--space-lg: 24px`, `--space-xl: 48px`. 8pt is too coarse — you'll need the 12px gaps.
- Use `gap` instead of margins for sibling spacing. No margin collapse.
- Vary spacing to create hierarchy. Extra space above a heading reads as importance.
- Self-adjusting grid: `grid-template-columns: repeat(auto-fit, minmax(280px, 1fr))` — no breakpoints needed for card grids.
- Container queries for component-level responsiveness. Viewport queries for page layout.

**Hard bans:**
- No wrapping everything in cards. Not everything needs a container.
- No cards nested inside cards.
- No identical 3-column card grids (icon + heading + text, repeated). Use 2-col zig-zag, asymmetric grid, or horizontal scroll.
- No centering everything. Left-aligned content with asymmetric compositions feels designed.
- No `border-left` or `border-right` wider than 1px as a colored accent stripe on cards, alerts, or callouts. This is the single most overused dashboard design pattern. Rewrite the element structure entirely instead.

---

## Motion

See [references/animation.md](references/animation.md) for the full animation decision framework.

### Animate or not?

Ask: **how often will the user see this?**

| Frequency | Decision |
|-----------|----------|
| 100+ times/day (keyboard shortcuts, command palette) | No animation. Ever. |
| Tens of times/day (hover effects, list nav) | Remove or drastically reduce |
| Occasional (modals, drawers, toasts) | Standard animation |
| Rare or first-time (onboarding, celebrations) | Can add delight |

Never animate keyboard-initiated actions. They're repeated hundreds of times daily.

### Easing

- Entering/exiting → `ease-out` (starts fast, feels responsive)
- Moving on screen → `ease-in-out` (natural deceleration)
- Hover/color change → `ease`
- Constant motion → `linear`

Never use `ease-in` for UI animations. It starts slow — the exact moment the user is watching most closely.

Use custom easing curves. The built-in ones are too weak:
```css
--ease-out-strong: cubic-bezier(0.23, 1, 0.32, 1);
--ease-in-out-strong: cubic-bezier(0.77, 0, 0.175, 1);
--ease-drawer: cubic-bezier(0.32, 0.72, 0, 1);
```

### Duration

| Element | Duration |
|---------|----------|
| Button press feedback | 100–160ms |
| Tooltips, small popovers | 125–200ms |
| Dropdowns, selects | 150–250ms |
| Modals, drawers | 200–350ms |
| Marketing/explainer | Can be longer |

Keep UI animations under 300ms. A 180ms dropdown feels more responsive than a 400ms one even at the same actual speed.

### What to animate

Only animate `transform` and `opacity`. These are GPU-composited and skip layout + paint.
Never animate `width`, `height`, `padding`, `margin`, or `top`/`left`.
Exception: `grid-template-rows` transitions work for height reveals without triggering layout thrash.

### Key patterns

**Never start from `scale(0)`** — nothing in the real world appears from nothing. Start from `scale(0.95)` + `opacity: 0`.

**Popovers should scale from their trigger**, not from center:
```css
.popover { transform-origin: var(--radix-popover-content-transform-origin); }
```
Exception: modals stay centered.

**CSS transitions over keyframes for dynamic UI** — transitions are interruptible and retarget mid-animation. Keyframes restart from zero.

**`@starting-style` for entry animations** (modern CSS, no JS needed):
```css
.toast {
  opacity: 1; transform: translateY(0);
  transition: opacity 300ms ease-out, transform 300ms ease-out;
  @starting-style { opacity: 0; transform: translateY(100%); }
}
```

**Stagger list entrances** — 30–80ms between items. Never block interaction during stagger.

**Asymmetric enter/exit** — enter can be deliberate, exit should be fast:
```css
/* Press: 2s deliberate fill */
button:active .overlay { transition: clip-path 2s linear; }
/* Release: snap back */
.overlay { transition: clip-path 200ms ease-out; }
```

**`prefers-reduced-motion`** — always:
```css
@media (prefers-reduced-motion: reduce) {
  /* Keep opacity/color transitions. Remove transform-based motion. */
}
```

---

## Interaction & States

See [references/interaction.md](references/interaction.md) for focus rings, form patterns, modal handling, and touch targets.

Every interactive surface needs all four states. Generating only the happy path is incomplete.

| State | Requirement |
|-------|-------------|
| Loading | Skeleton matching the layout shape — not a spinner |
| Empty | Teach the interface, don't just say "nothing here" |
| Error | Inline, specific — not a generic "something went wrong" |
| Active/press | `scale(0.97)` or `translateY(-1px)` on `:active` — physical feedback |

**Progressive disclosure** — start simple, reveal sophistication through interaction. Don't show everything upfront.

**Optimistic UI** — update immediately, sync in background. Don't make users wait for confirmation on low-risk actions.

---

## Implementation Rules

**Check `package.json` before importing any library.** If it's not installed, output the install command before the code. Never assume a package exists.

**`min-h-[100dvh]` not `h-screen`** for full-height sections. `h-screen` causes layout jumps on mobile browsers (iOS Safari address bar).

**CSS Grid over flex percentage math.** Never `w-[calc(33%-1rem)]`. Use `grid-cols-3 gap-6`.

**Hover states only on devices that support hover:**
```css
@media (hover: hover) and (pointer: fine) {
  .element:hover { transform: scale(1.05); }
}
```
Touch devices fire hover on tap — without this guard you get false positives.

**Framer Motion `x`/`y` shorthand is not hardware-accelerated.** Under load it drops frames. Use the full transform string when smooth 60fps matters:
```jsx
// Smooth under load
<motion.div animate={{ transform: "translateX(100px)" }} />
// Not hardware-accelerated
<motion.div animate={{ x: 100 }} />
```

**No modals unless there's genuinely no better alternative.** Modals interrupt context. Prefer inline expansion, drawers, or popovers.

---

## Copy & UX Writing

See [references/ux-writing.md](references/ux-writing.md) for button labels, error messages, empty states, and translation guidance.

Never use "OK", "Submit", or "Yes/No". Use verb + object: "Save changes", "Delete project", "Create account". Every error answers: what happened, why, and how to fix it.

---

## The AI Slop Test

Before finishing: if you showed this to someone and said "AI built this" — would they believe you immediately? If yes, that's the problem.

A well-designed interface makes someone ask "how was this made?" not "which AI made this?"

Common tells to eliminate:
- Inter font + purple accent + rounded card with drop shadow
- Gradient text on the hero heading
- 3-column icon + heading + text feature grid
- Generic metric cards (big number, small label, colored bar)
- Glassmorphism used everywhere as a design decision
- Centered hero with stock-photo background and a CTA button
- `border-left: 4px solid var(--accent)` on every callout

---

## Review Format

When reviewing UI code, use a table:

| Before | After | Why |
|--------|-------|-----|
| `transition: all 300ms` | `transition: transform 200ms ease-out` | Specify properties; avoid `all` |
| `transform: scale(0)` entry | `scale(0.95) opacity: 0` | Nothing appears from nothing |
| `ease-in` on dropdown | `ease-out` with custom curve | `ease-in` feels sluggish |
| `h-screen` on hero | `min-h-[100dvh]` | iOS Safari address bar causes jumps |
| `border-left: 4px solid accent` | Full border or background tint | Side-stripe is an AI design tell |

Never use before/after as separate bullet lists. Always a table with a Why column.
