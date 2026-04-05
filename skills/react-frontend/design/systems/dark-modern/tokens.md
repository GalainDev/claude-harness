# Dark Modern — Design Tokens

**Aesthetic:** Vercel dashboard, VS Code, Raycast dark, Linear dark. Developer-tool quality.

## Color

```css
/* Backgrounds — layered depth */
--color-bg:           #0a0a0a;
--color-bg-subtle:    #111111;
--color-bg-elevated:  #1a1a1a;
--color-bg-overlay:   #222222;

/* Borders */
--color-border:       rgba(255,255,255,0.08);
--color-border-strong: rgba(255,255,255,0.15);

/* Text */
--color-text:         #ededed;
--color-text-secondary: #888888;
--color-text-muted:   #555555;
--color-text-disabled: #333333;

/* Brand accent */
--color-accent:       #ffffff;
--color-accent-muted: rgba(255,255,255,0.06);

/* Functional accent (blue for links/CTAs) */
--color-blue:         #3b82f6;
--color-blue-muted:   rgba(59,130,246,0.15);

/* Status */
--color-success:      #22c55e;
--color-warning:      #f59e0b;
--color-error:        #ef4444;

/* Glow effects (use sparingly) */
--glow-blue:  0 0 20px rgba(59,130,246,0.3);
--glow-white: 0 0 20px rgba(255,255,255,0.1);
```

## Typography

```css
--font-sans: 'Geist', 'Inter', system-ui, sans-serif;
--font-mono: 'Geist Mono', 'JetBrains Mono', monospace;

/* Same scale as minimal-clean, applied to dark context */
--text-xs:   0.75rem;
--text-sm:   0.875rem;
--text-base: 1rem;
--text-lg:   1.125rem;
--text-xl:   1.25rem;
--text-2xl:  1.5rem;
--text-3xl:  1.875rem;
--text-4xl:  2.25rem;

--font-weight-normal:   400;
--font-weight-medium:   500;
--font-weight-semibold: 600;
```

## Radius & Shadows

```css
--radius-sm:  4px;
--radius-md:  6px;
--radius-lg:  10px;
--radius-xl:  14px;

/* Dark-mode shadows use opacity, not color */
--shadow-sm:  0 1px 3px rgba(0,0,0,0.4);
--shadow-md:  0 4px 12px rgba(0,0,0,0.5);
--shadow-lg:  0 12px 32px rgba(0,0,0,0.6);
```

## Tailwind Config Snippet

```js
module.exports = {
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        bg: {
          DEFAULT: '#0a0a0a',
          subtle: '#111111',
          elevated: '#1a1a1a',
          overlay: '#222222',
        },
        border: { DEFAULT: 'rgba(255,255,255,0.08)', strong: 'rgba(255,255,255,0.15)' },
        text: { DEFAULT: '#ededed', secondary: '#888888', muted: '#555555' },
        accent: { DEFAULT: '#ffffff', muted: 'rgba(255,255,255,0.06)' },
        brand: { DEFAULT: '#3b82f6', muted: 'rgba(59,130,246,0.15)' },
      },
      fontFamily: {
        sans: ['Geist', 'Inter', 'system-ui', 'sans-serif'],
        mono: ['Geist Mono', 'JetBrains Mono', 'monospace'],
      },
    },
  },
}
```

## Do / Don't

| Do | Don't |
|----|-------|
| Layer backgrounds: 0a → 11 → 1a | Flat single background |
| rgba borders over opaque | Pure white/black borders |
| Geist or Inter, medium weight | Heavy bold everywhere |
| Glow effects on primary actions only | Glows on every element |
| Monospace for data, paths, code | Monospace for body text |
