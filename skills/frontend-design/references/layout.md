# Layout & Spatial Design Reference

## Spacing Scale

Use 4pt base, not 8pt. 8pt is too coarse — you'll frequently need 12px:

```css
:root {
  --space-1:  4px;
  --space-2:  8px;
  --space-3:  12px;
  --space-4:  16px;
  --space-5:  24px;
  --space-6:  32px;
  --space-8:  48px;
  --space-10: 64px;
  --space-14: 96px;
}
```

Name by relationship, not value. `--space-sm` over `--spacing-8`. When the scale shifts, semantic names stay meaningful.

**Use `gap` for sibling spacing**, not margins. Eliminates margin collapse and its cleanup hacks. Use margins only for flow-level separation (paragraph spacing, section breaks).

**Vary spacing to create hierarchy.** Extra space above a heading communicates importance. Same padding everywhere reads as no hierarchy.

---

## Grid Patterns

### Self-adjusting card grid (no breakpoints needed)

```css
.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: var(--space-5);
}
```

Columns are minimum 280px, as many as fit per row, remainders stretch. Works from mobile to wide desktop without a single media query.

### Named grid areas for complex layouts

```css
.layout {
  display: grid;
  grid-template-areas:
    "header header"
    "sidebar main"
    "footer footer";
  grid-template-columns: 240px 1fr;
}

@media (max-width: 768px) {
  .layout {
    grid-template-areas:
      "header"
      "main"
      "sidebar"
      "footer";
    grid-template-columns: 1fr;
  }
}
```

### Container queries — components, not viewport

Viewport queries are for page layout. Container queries are for components that live in different contexts:

```css
.card-container {
  container-type: inline-size;
  container-name: card;
}

/* Card adapts to its container, not the viewport */
@container card (min-width: 400px) {
  .card {
    grid-template-columns: 120px 1fr;
  }
}
```

A card in a narrow sidebar stays compact. The same card in a wide content area expands. No viewport hacks, no duplicated components.

---

## Visual Hierarchy

### The squint test

Blur your eyes (or screenshot + blur in an image editor). Can you still identify:
- The most important element?
- The second most important?
- Clear groupings without labels?

If everything blurs to equal weight, you have a hierarchy problem.

### Stack hierarchy across multiple dimensions

Don't rely on size alone. Combine tools:

| Tool | Strong | Weak |
|------|--------|------|
| Size | 3:1 ratio or more | Under 2:1 |
| Weight | Bold vs Regular | Medium vs Regular |
| Color | High contrast | Similar tones |
| Position | Top/left = primary | Bottom/right = secondary |
| Space | Surrounded by white space | Crowded in |

The strongest hierarchy uses 2–3 dimensions at once: a heading that's larger *and* bolder *and* has more space above it. Single-dimension hierarchy is fragile.

---

## Cards

Cards are overused. Not everything needs a box. Spacing and alignment create grouping naturally — visual separation without chrome.

**Use cards when:**
- Content is truly distinct and actionable
- Items need visual comparison in a grid
- Content needs a clear interaction boundary (clickable, draggable)

**Never:**
- Nest cards inside cards — use spacing and typography for internal hierarchy
- Use identical card grids (icon + heading + text, repeated) — use zig-zag layouts, asymmetric grids, or horizontal scroll
- Add box shadows to everything — when a shadow appears everywhere it communicates nothing
- Use `border-left: 4px solid accent` as the design element on callouts or list items — rewrite the structure entirely

---

## Responsive Design

### Mobile-first

Write base styles for mobile, layer up with `min-width` queries:

```css
.component { /* mobile base */ }

@media (min-width: 768px) { .component { /* tablet */ } }
@media (min-width: 1280px) { .component { /* desktop */ } }
```

### Fluid spacing with `clamp()`

```css
.section {
  padding-block: clamp(var(--space-6), 5vw, var(--space-14));
}

h1 {
  font-size: clamp(2rem, 5vw, 4rem);
}
```

Use `clamp()` for values that should breathe proportionally on large screens. Use fixed values in product UIs where consistency matters more than fluidity.

### Don't hide — adapt

Hiding critical functionality on mobile is wrong. Adapt the interaction model instead:
- Wide table → horizontally scrollable, or collapsed to card view
- Multi-column form → single column
- Sidebar nav → bottom nav or hamburger (only if genuinely needed)

### Full-height sections

```css
/* Never h-screen — iOS Safari address bar causes layout jumps */
.hero {
  min-height: 100dvh;
}
```

`100dvh` accounts for the dynamic viewport (browser chrome appearing/disappearing). `100vh` does not.

---

## Optical Adjustments

Text at `margin-left: 0` often looks visually indented due to letterform whitespace. Optically align with a small negative margin (`-0.03em` to `-0.05em`).

Geometrically centered icons often look off-center. Play buttons need to shift right. Arrows shift toward their direction. Trust your eye over the math.

Touch targets must be at least 44×44px even if the visual element is smaller. Use padding or pseudo-elements to expand the hit area without changing the visual:

```css
.icon-button {
  position: relative;
}
.icon-button::before {
  content: '';
  position: absolute;
  inset: -12px;  /* expand hit area by 12px each side */
}
```

---

## Layout Anti-patterns

- **Centering everything** — left-aligned content with asymmetric composition reads as designed. Centering reads as default.
- **Equal spacing everywhere** — without rhythm, layouts feel like a grid of facts rather than a communication.
- **Body text over ~80ch** — add `max-width: 65ch` or `max-width: 75ch` on prose containers.
- **`calc(33% - 1rem)` flex math** — use `grid-template-columns: repeat(3, 1fr)` instead.
- **Overlapping z-index without a system** — define a z-index scale: `--z-base: 0`, `--z-dropdown: 100`, `--z-sticky: 200`, `--z-modal: 300`, `--z-toast: 400`. Never use arbitrary values.
