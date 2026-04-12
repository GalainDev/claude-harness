# AI SaaS — Design Tokens

**Aesthetic:** Cursor, Perplexity, Linear, Clerk, v0. Precision dark UI built for intelligent products.
Dense, geometric, one strong accent. Feels like the product was designed by engineers who genuinely
care about craft — not a designer who read "dark mode is cool".

**Differentiator:** Everything earns its place. No decorative anything. Depth through opacity, not shadows.
The accent color does all the signal work — use it for one thing and one thing only per view.

---

## Color

```css
/* Backgrounds — strict layering, no skipping levels */
--color-bg:           oklch(10% 0.010 260);   /* near-black, slightly cool */
--color-bg-subtle:    oklch(13% 0.010 260);   /* sidebar, secondary panels */
--color-bg-elevated:  oklch(16% 0.010 260);   /* cards, inputs, popovers */
--color-bg-overlay:   oklch(20% 0.010 260);   /* tooltips, dropdowns */
--color-bg-highlight: oklch(22% 0.015 260);   /* hover state on rows */

/* Borders — opacity-based, never opaque */
--color-border:        rgba(255,255,255,0.06);
--color-border-strong: rgba(255,255,255,0.12);
--color-border-accent: rgba(255,255,255,0.20); /* focus rings, selected states */

/* Text */
--color-text:          oklch(94% 0.005 260);  /* primary — warm near-white */
--color-text-secondary:oklch(58% 0.008 260);  /* secondary labels */
--color-text-muted:    oklch(38% 0.006 260);  /* placeholders, disabled */
--color-text-disabled: oklch(28% 0.005 260);

/* Accent — pick ONE per project, never mix */
/* Option A: Electric violet (Cursor, Linear) */
--color-accent:        oklch(68% 0.20 292);
--color-accent-muted:  oklch(68% 0.20 292 / 0.12);
--color-accent-strong: oklch(62% 0.22 292);

/* Option B: Amber (Valynix Vault) */
/* --color-accent:       oklch(72% 0.14 62);  */
/* --color-accent-muted: oklch(72% 0.14 62 / 0.12); */

/* Option C: Ice blue (Perplexity) */
/* --color-accent:       oklch(70% 0.14 222);  */
/* --color-accent-muted: oklch(70% 0.14 222 / 0.12); */

/* Status */
--color-success:       oklch(64% 0.16 145);
--color-success-muted: oklch(64% 0.16 145 / 0.12);
--color-warning:       oklch(72% 0.14 62);
--color-warning-muted: oklch(72% 0.14 62 / 0.12);
--color-error:         oklch(60% 0.20 25);
--color-error-muted:   oklch(60% 0.20 25 / 0.12);
```

---

## Typography

```css
/* Fonts — in priority order */
--font-sans: 'Geist', 'Söhne', system-ui, sans-serif;
--font-mono: 'Geist Mono', 'Berkeley Mono', monospace;

/* Scale — tight. This is a dense UI, not a marketing page. */
--text-xs:   0.6875rem;  /* 11px — labels, badges */
--text-sm:   0.8125rem;  /* 13px — body default */
--text-base: 0.9375rem;  /* 15px — comfortable reading */
--text-lg:   1.0625rem;  /* 17px — subheadings */
--text-xl:   1.25rem;    /* 20px */
--text-2xl:  1.5rem;     /* 24px */
--text-3xl:  2rem;       /* 32px */
--text-4xl:  2.75rem;    /* 44px — hero only */

/* Weight — restrained */
--font-weight-normal:   400;
--font-weight-medium:   500;  /* UI labels, nav */
--font-weight-semibold: 600;  /* headings */
/* 700+ only for single words of high emphasis — never paragraphs */

/* Tracking */
--tracking-tight:  -0.025em;  /* headings 24px+ */
--tracking-normal: -0.01em;   /* body default (slightly tight, feels precision) */
--tracking-wide:    0.06em;   /* uppercase labels only */

/* Line height */
--leading-dense:  1.25;  /* headings, UI rows */
--leading-normal: 1.5;   /* body */
--leading-loose:  1.7;   /* long-form content */
```

---

## Spacing

```css
/* 4pt base. Tighter than corporate-saas by default. */
--space-1:  4px;
--space-2:  8px;
--space-3:  12px;
--space-4:  16px;
--space-5:  20px;
--space-6:  24px;
--space-8:  32px;
--space-10: 40px;
--space-12: 48px;
--space-16: 64px;
--space-24: 96px;

/* Component-specific */
--padding-input:   6px 12px;    /* tight inputs */
--padding-button:  7px 14px;    /* default button */
--padding-button-sm: 4px 10px;
--padding-card:    16px;
--padding-panel:   20px;
```

---

## Radius

```css
/* Geometric. Not pill-shaped. */
--radius-sm:  4px;   /* badges, tags, small inputs */
--radius-md:  6px;   /* buttons, inputs default */
--radius-lg:  8px;   /* cards, popovers */
--radius-xl:  12px;  /* modals, large panels */
/* Never: border-radius > 12px on product UI. Pills are for consumer apps. */
```

---

## Depth & Elevation

```css
/* No colored shadows. Depth via background lightness + borders. */
--shadow-sm: 0 1px 2px rgba(0,0,0,0.4);
--shadow-md: 0 4px 12px rgba(0,0,0,0.5);
--shadow-lg: 0 12px 32px rgba(0,0,0,0.6);

/* Accent glow — use ONLY on primary CTAs and active AI states */
--glow-accent: 0 0 16px oklch(68% 0.20 292 / 0.35);

/* Never: colorful glows on non-accent elements */
/* Never: multiple glow layers */
```

---

## Tailwind Config Snippet

```js
module.exports = {
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        bg: {
          DEFAULT:   'oklch(10% 0.010 260)',
          subtle:    'oklch(13% 0.010 260)',
          elevated:  'oklch(16% 0.010 260)',
          overlay:   'oklch(20% 0.010 260)',
          highlight: 'oklch(22% 0.015 260)',
        },
        border: {
          DEFAULT: 'rgba(255,255,255,0.06)',
          strong:  'rgba(255,255,255,0.12)',
        },
        text: {
          DEFAULT:   'oklch(94% 0.005 260)',
          secondary: 'oklch(58% 0.008 260)',
          muted:     'oklch(38% 0.006 260)',
        },
        accent: {
          DEFAULT: 'oklch(68% 0.20 292)',
          muted:   'oklch(68% 0.20 292 / 0.12)',
          strong:  'oklch(62% 0.22 292)',
        },
      },
      fontFamily: {
        sans: ['Geist', 'Söhne', 'system-ui', 'sans-serif'],
        mono: ['Geist Mono', 'Berkeley Mono', 'monospace'],
      },
      fontSize: {
        '2xs': ['0.6875rem', { lineHeight: '1rem' }],
        xs:    ['0.8125rem', { lineHeight: '1.25rem' }],
        sm:    ['0.9375rem', { lineHeight: '1.5rem' }],
      },
      letterSpacing: {
        tighter: '-0.025em',
        tight:   '-0.01em',
      },
    },
  },
}
```

---

## AI-Specific Patterns

### Streaming text
When displaying AI output streaming in real time:
- Use a blinking `|` cursor at the stream head, `animation: blink 1s step-end infinite`
- Never animate the container — only the cursor
- Text color stays `--color-text`, not the accent
- Stop the cursor immediately on stream complete — don't linger

### Thinking/loading state
- Skeleton: 3 lines at 100%/80%/60% width, `--color-bg-overlay` fill, pulse animation
- NOT a spinner — spinners imply unknown duration. Skeletons imply shape.
- Pulse: `opacity: 0.4 → 1`, `ease-in-out`, `1.4s`, `infinite alternate`

### Source citations
- Inline superscript reference: `[1]` in accent color, small, clickable
- Citation panel: slides in from right, never a modal
- Each source: favicon + domain + excerpt, tight layout

### Input area (chat / command)
- Full-width, `--color-bg-elevated` background
- Top border only: `--color-border`
- No outer card wrapper — the input IS the surface
- Send button: icon only at rest, label appears on hover
- Keyboard shortcut hint: `⌘↵` in `--color-text-muted`, right-aligned

---

## Do / Don't

| Do | Don't |
|----|-------|
| Single accent, used for one semantic purpose | Two accent colors in the same view |
| Depth via background layering (10→13→16→20%) | Shadows as the primary depth signal |
| Tight spacing — 12–16px default padding | Generous padding that wastes vertical space |
| -0.025em tracking on headings | Default tracking on large type |
| Geist or Söhne for UI | Anything on the reject list |
| `oklch()` for all color values | `hsl()` or hex for brand colors |
| Skeleton loading matching layout shape | Spinner for AI responses |
| Border on focus, not glow ring | `box-shadow: 0 0 0 3px accent` focus rings |
| Status colors at 12% opacity for backgrounds | Full-opacity status colors on surfaces |
