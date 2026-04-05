# Corporate SaaS — Design Tokens

**Aesthetic:** Stripe, Notion, Vercel marketing, GitHub. Polished, professional, trustworthy.

## Color

```css
/* Base */
--color-bg:          #ffffff;
--color-bg-subtle:   #fafafa;
--color-bg-muted:    #f4f4f5;

/* Borders */
--color-border:      #e4e4e7;
--color-border-strong: #a1a1aa;

/* Text */
--color-text:        #09090b;
--color-text-secondary: #71717a;
--color-text-muted:  #a1a1aa;

/* Brand — can be customized per-project */
--color-brand:        #6366f1;   /* indigo default */
--color-brand-light:  #e0e7ff;
--color-brand-dark:   #4338ca;

/* Status */
--color-success:      #16a34a;
--color-success-bg:   #f0fdf4;
--color-warning:      #d97706;
--color-warning-bg:   #fffbeb;
--color-error:        #dc2626;
--color-error-bg:     #fef2f2;
--color-info:         #2563eb;
--color-info-bg:      #eff6ff;
```

## Typography

```css
--font-sans: 'Inter', system-ui, sans-serif;
--font-mono: 'Fira Code', 'JetBrains Mono', monospace;

/* Scale — slightly more structured than minimal */
--text-xs:   0.75rem;
--text-sm:   0.875rem;
--text-base: 1rem;
--text-lg:   1.125rem;
--text-xl:   1.25rem;
--text-2xl:  1.5rem;
--text-3xl:  2rem;
--text-4xl:  2.5rem;
--text-5xl:  3rem;

--leading-tight:  1.2;
--leading-normal: 1.5;
--leading-loose:  1.8;

--tracking-tight: -0.02em;   /* headlines */
--tracking-normal: 0;
--tracking-wide: 0.05em;     /* labels, caps */
```

## Radius & Shadows

```css
--radius-sm:  4px;
--radius-md:  8px;
--radius-lg:  12px;
--radius-xl:  20px;

/* SaaS uses intentional, layered shadows */
--shadow-xs:  0 1px 2px rgba(0,0,0,0.05);
--shadow-sm:  0 1px 3px rgba(0,0,0,0.1), 0 1px 2px rgba(0,0,0,0.06);
--shadow-md:  0 4px 6px -1px rgba(0,0,0,0.1), 0 2px 4px -1px rgba(0,0,0,0.06);
--shadow-lg:  0 10px 15px -3px rgba(0,0,0,0.1), 0 4px 6px -2px rgba(0,0,0,0.05);
--shadow-xl:  0 20px 25px -5px rgba(0,0,0,0.1), 0 10px 10px -5px rgba(0,0,0,0.04);
```

## Tailwind Config Snippet

```js
module.exports = {
  theme: {
    extend: {
      colors: {
        brand: { DEFAULT: '#6366f1', light: '#e0e7ff', dark: '#4338ca' },
        text: { DEFAULT: '#09090b', secondary: '#71717a', muted: '#a1a1aa' },
        border: { DEFAULT: '#e4e4e7', strong: '#a1a1aa' },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      letterSpacing: {
        tighter: '-0.02em',
      },
    },
  },
}
```
