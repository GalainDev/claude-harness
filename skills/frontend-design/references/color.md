# Color Reference

## Use OKLCH, Not HSL

OKLCH is perceptually uniform — equal lightness steps *look* equal. HSL is not: 50% lightness in yellow looks bright, 50% in blue looks dark. OKLCH eliminates this.

```css
/* OKLCH syntax: oklch(lightness chroma hue) */
/* lightness: 0–100%  |  chroma: ~0–0.4  |  hue: 0–360 */

--color-brand:       oklch(55% 0.18 240);   /* mid blue */
--color-brand-light: oklch(85% 0.08 240);   /* light blue — reduced chroma */
--color-brand-dark:  oklch(30% 0.12 240);   /* dark blue — reduced chroma */
```

**Critical rule**: as lightness approaches white or black, reduce chroma. High chroma at extreme lightness looks garish. A light blue at L=85% wants chroma ~0.08, not 0.18.

---

## Tinted Neutrals

Pure gray (`oklch(50% 0 0)`) feels dead next to a colored brand. Add tiny chroma — 0.005–0.015 — hued toward your brand color:

```css
/* Brand hue is ~240 (blue). Tint all neutrals toward it. */
--neutral-50:  oklch(98% 0.006 240);
--neutral-100: oklch(95% 0.007 240);
--neutral-200: oklch(90% 0.008 240);
--neutral-300: oklch(82% 0.009 240);
--neutral-400: oklch(70% 0.010 240);
--neutral-500: oklch(58% 0.010 240);
--neutral-600: oklch(46% 0.009 240);
--neutral-700: oklch(36% 0.008 240);
--neutral-800: oklch(26% 0.007 240);
--neutral-900: oklch(16% 0.006 240);
--neutral-950: oklch(10% 0.005 240);
```

The chroma is small enough that it doesn't read as "tinted" consciously, but it creates subconscious cohesion between brand and surface.

**The hue comes from THIS brand.** Don't tint everything toward warm orange (friendly default) or cool blue (tech default). Those are the two laziest choices and they produce their own monoculture.

---

## Palette Structure

| Role | Purpose | Scale |
|------|---------|-------|
| **Brand/Primary** | CTAs, key actions, links | 1 hue, 5–9 shades |
| **Neutral** | Text, backgrounds, borders | 11 shades (50–950) |
| **Semantic** | Success, error, warning, info | 4 hues, 2–3 shades each |
| **Surface** | Cards, modals, overlays | 2–3 elevation levels |

Skip secondary/tertiary accent colors unless you have a clear need. Most apps work fine with one accent. More colors = more decision fatigue.

### 60-30-10 by visual weight (not pixel count)

- **60%** — neutral surfaces, backgrounds, white space
- **30%** — secondary: text, borders, inactive states
- **10%** — accent: CTAs, focus rings, highlights, active states

Accent colors work *because* they're rare. Using brand color everywhere kills its power.

---

## Contrast & Accessibility

### WCAG requirements

| Content | AA minimum | AAA target |
|---------|------------|------------|
| Body text | 4.5:1 | 7:1 |
| Large text (18px+ or 14px bold) | 3:1 | 4.5:1 |
| UI components, icons | 3:1 | 4.5:1 |
| Decorative elements | None | — |

Placeholder text counts as text and needs 4.5:1. The light gray placeholder everyone uses almost always fails.

### Common failures

- **Gray text on colored backgrounds** — gray looks washed out and dead on color. Use a darker shade of the background hue instead, or an opaque tint: `color-mix(in oklch, var(--bg) 30%, black)`.
- **Light text on images** — unpredictable contrast. Always add a scrim: `background: linear-gradient(to bottom, transparent, oklch(0% 0 0 / 0.7))`.
- **Red on green or green on red** — 8% of men can't distinguish these.
- **Yellow text on white** — almost always fails contrast.
- **Pure black `#000`** — doesn't exist in nature. Tint it: `oklch(8% 0.005 240)`.

### Test — don't trust your eyes

- Chrome DevTools → Rendering → Emulate vision deficiencies
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- Figma or Polypane for real-time coverage

---

## Light vs Dark Mode

Use `light-dark()` and `@media (prefers-color-scheme)` together:

```css
:root {
  color-scheme: light dark;

  --bg:        light-dark(oklch(98% 0.006 240), oklch(12% 0.006 240));
  --surface:   light-dark(oklch(100% 0 0),      oklch(18% 0.007 240));
  --text:      light-dark(oklch(15% 0.008 240),  oklch(93% 0.005 240));
  --text-muted:light-dark(oklch(45% 0.008 240),  oklch(65% 0.007 240));
  --border:    light-dark(oklch(88% 0.007 240),  oklch(28% 0.007 240));
  --accent:    light-dark(oklch(50% 0.18 240),   oklch(65% 0.18 240));
}
```

Note: dark mode accents often need to be *lighter* (higher lightness) than their light mode counterparts to maintain 4.5:1 contrast on a dark surface.

### For manual toggle (class-based)

```css
:root[data-theme="dark"] {
  --bg: oklch(12% 0.006 240);
  /* ... */
}
```

---

## Semantic Colors

```css
:root {
  /* Success */
  --color-success:      oklch(55% 0.18 145);   /* green */
  --color-success-bg:   oklch(95% 0.04 145);

  /* Error */
  --color-error:        oklch(55% 0.22 25);    /* red */
  --color-error-bg:     oklch(96% 0.04 25);

  /* Warning */
  --color-warning:      oklch(70% 0.18 75);    /* amber */
  --color-warning-bg:   oklch(96% 0.04 75);

  /* Info */
  --color-info:         oklch(55% 0.15 240);   /* blue */
  --color-info-bg:      oklch(95% 0.03 240);
}
```

Background tints (`-bg` tokens) should pass 4.5:1 with the base color used as text on top of them.

---

## Hard Bans

- No pure `#000000` or `#ffffff` — always tinted
- No gray text on colored backgrounds
- No AI color palette: cyan-on-dark, purple-to-blue gradients, neon on dark
- No gradient text (`background-clip: text` + gradient) — use solid color; for emphasis, use weight or size
- No defaulting to dark + glowing accents because it "looks cool"
- No defaulting to light because it's "safe" — derive the theme from context
