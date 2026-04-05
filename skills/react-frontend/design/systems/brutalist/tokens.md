# Brutalist — Design Tokens

**Aesthetic:** Raw, unapologetic, high-contrast. Bold borders, heavy type, flat color.
Reference: Gumroad, some Framer templates, neo-brutalist web.

## Color

```css
/* Flat, bold palette */
--color-bg:          #ffffff;
--color-bg-alt:      #f5f5f5;

/* Brutalist uses thick black borders over color borders */
--color-border:      #000000;
--border-width:      2px;   /* minimum; hero elements use 3–4px */

/* Text */
--color-text:        #000000;
--color-text-secondary: #333333;

/* Accent — one loud color, used intentionally */
--color-accent:      #ffee00;   /* electric yellow — change per project */
--color-accent-alt:  #ff4f00;   /* secondary pop */

/* Status — bold, flat */
--color-success:     #00cc44;
--color-warning:     #ff9900;
--color-error:       #ff0000;
```

## Typography

```css
/* Brutalist uses display/grotesque fonts */
--font-display: 'Space Grotesk', 'Syne', 'DM Sans', sans-serif;
--font-sans:    'Space Grotesk', system-ui, sans-serif;
--font-mono:    'Space Mono', monospace;

/* Scale — bigger jumps between sizes */
--text-sm:    0.875rem;
--text-base:  1rem;
--text-lg:    1.25rem;
--text-xl:    1.5rem;
--text-2xl:   2rem;
--text-3xl:   2.75rem;
--text-4xl:   3.5rem;
--text-5xl:   5rem;

--font-weight-normal: 400;
--font-weight-bold:   700;
--font-weight-black:  900;   /* used in heroes */

--leading-tight: 1.1;        /* headlines */
--leading-normal: 1.5;

--tracking-tight:  -0.02em;
--tracking-wide:    0.1em;   /* uppercase labels */
```

## Borders & Shadows

```css
/* Brutalist: thick borders, hard offset shadows (no blur) */
--border-thin:   1px solid #000;
--border-normal: 2px solid #000;
--border-heavy:  3px solid #000;

/* Hard shadow — no blur, just offset. Signature brutalist style. */
--shadow-hard-sm: 3px 3px 0px #000;
--shadow-hard-md: 4px 4px 0px #000;
--shadow-hard-lg: 6px 6px 0px #000;
--shadow-hard-xl: 8px 8px 0px #000;

--radius: 0px;   /* brutalist = sharp corners by default */
```

## Component Snippets

```tsx
// Brutalist button — hard shadow lifts on hover
<button className="border-2 border-black bg-yellow-300 font-bold px-5 py-2.5
  shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]
  hover:translate-x-[2px] hover:translate-y-[2px]
  hover:shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]
  transition-all duration-100">
  Click me
</button>

// Brutalist card
<div className="border-2 border-black shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] p-6">
  {children}
</div>
```

## Do / Don't

| Do | Don't |
|----|-------|
| Black borders everywhere | Subtle gray borders |
| Hard offset shadows (no blur) | Soft Gaussian shadows |
| One loud accent color | Gradient or multiple accents |
| Sharp corners | Rounded corners |
| Heavy/black weight headlines | Light or thin type |
