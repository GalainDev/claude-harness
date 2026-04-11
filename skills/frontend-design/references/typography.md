# Typography Reference

## Type Scale

Use fewer sizes with more contrast. A 5-step scale covers everything:

| Token | Size | Use |
|-------|------|-----|
| `--text-xs` | 0.75rem | Captions, legal, metadata |
| `--text-sm` | 0.875rem | Secondary UI, labels |
| `--text-base` | 1rem | Body copy |
| `--text-lg` | 1.25–1.5rem | Subheadings, lead text |
| `--text-xl+` | 2–4rem | Headlines, hero |

Minimum 1.25 ratio between steps. Sizes that are too close (14px, 15px, 16px, 18px) produce no hierarchy — just noise.

**Marketing/content pages**: use `clamp()` for fluid scaling.
**App UIs and dashboards**: use fixed `rem` — fluid type in product UI creates inconsistency.

### Vertical rhythm

Your `line-height` should be the base unit for all vertical spacing. Body at `line-height: 1.5` on `16px` = 24px grid. Section spacing should be multiples of that. Text and space share a mathematical foundation — users feel it without knowing why.

---

## Readability Rules

- **Line length**: cap body at 65–75ch. Beyond that, the eye fatigues tracking back to the next line.
- **Line height scales inversely with font size**: large headings want tight leading (`1.1–1.2`), long body copy wants more (`1.5–1.7`).
- **Light text on dark backgrounds**: add 0.05–0.1 to your normal line-height. Light type reads as thinner and needs more breathing room.
- **Never set long body passages in all-caps**. Reserve uppercase for short labels and UI chrome.

---

## Font Selection

Do this procedure on every project. The failure mode is picking the font you'd normally reach for.

### Step 1 — Write 3 brand-voice words
Concrete, specific words. Not "modern" or "elegant" — those are dead. Examples:
- "warm and mechanical and opinionated"
- "dense and unimpressed and fast"
- "handmade and slightly weird"
- "calm and clinical and careful"

### Step 2 — Imagine the font as a physical object
What physical thing could the brand ship that would fit those words? A typewriter ribbon, a hand-lettered shop sign, a 1970s mainframe terminal manual, a fabric label on the inside of a coat, a museum exhibit caption, a children's book on cheap newsprint. That physical object points at the right *kind* of typeface.

### Step 3 — Browse, then reject the obvious
Sources: Google Fonts, Pangram Pangram, Future Fonts, Adobe Fonts, ABC Dinamo, Klim, Velvetyne.

**Reject the first thing that "looks designy."** That's your trained reflex. Keep looking.

### Step 4 — Cross-check
These defaults are banned — they are training-data reflexes that produce monoculture:

```
Inter, Roboto, Open Sans, Lato, Montserrat
DM Sans, Plus Jakarta Sans, Outfit, Instrument Sans, Instrument Serif
Fraunces, Newsreader, Lora, Crimson Pro, Playfair Display, Cormorant
Syne, IBM Plex Sans, IBM Plex Mono, Space Grotesk, Space Mono
```

If your pick is on this list, go back to step 3.

### Anti-reflexes worth defending against
- Technical brief ≠ serif "for warmth". Tech tools should look like tech tools.
- Editorial brief ≠ the expressive serif everyone is using right now. Premium can be Swiss-modern, neo-grotesque, monospace, quiet humanist.
- Children's product ≠ rounded display font. Children's books use real type.
- "Modern" ≠ geometric sans. The most modern thing in 2026 is not using the font everyone else uses.

---

## Font Pairing

**You often don't need a second font.** One well-chosen family in multiple weights creates cleaner hierarchy than two competing typefaces. Only add a second font when you need genuine contrast.

When pairing, contrast on multiple axes simultaneously:
- Serif + Sans (structural contrast)
- Geometric + Humanist (personality contrast)
- Condensed display + Wide body (proportion contrast)

**Never pair fonts that are similar but not identical** — two geometric sans-serifs create visual tension without clear hierarchy.

---

## Web Font Loading

Layout shift from late-loading fonts is a UX problem. Fix it:

```css
/* 1. font-display: swap — text visible immediately, swaps when font loads */
@font-face {
  font-family: 'YourFont';
  src: url('font.woff2') format('woff2');
  font-display: swap;
  font-weight: 100 900;  /* variable font range */
}

/* 2. Preload critical weights in <head> */
/* <link rel="preload" href="font.woff2" as="font" type="font/woff2" crossorigin> */

/* 3. Size-adjust fallback to minimize reflow */
@font-face {
  font-family: 'YourFont-Fallback';
  src: local('Arial');
  size-adjust: 105%;
  ascent-override: 90%;
}
```

For variable fonts, use `font-weight: 100 900` in the `@font-face` declaration instead of loading separate weight files.

---

## OpenType Features

Worth enabling on body copy at scale:

```css
body {
  font-feature-settings:
    'kern' 1,   /* kerning */
    'liga' 1,   /* standard ligatures (fi, fl) */
    'calt' 1;   /* contextual alternates */
}

/* Numerals in tables — use tabular lining figures */
.data-table {
  font-variant-numeric: tabular-nums lining-nums;
}

/* Proportional oldstyle figures in body text */
p {
  font-variant-numeric: proportional-nums oldstyle-nums;
}
```

`font-variant-numeric: tabular-nums` is important for any data-heavy UI — it prevents columns from shifting width as numbers change.

---

## System Fonts

Underrated for apps where performance > personality:

```css
font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif;
```

Loads instantly, looks native, performs at 60fps. Consider this for internal tools, dashboards, or any UI where the brand isn't the differentiator.
