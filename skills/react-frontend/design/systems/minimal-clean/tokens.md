# Minimal Clean — Design Tokens

**Aesthetic:** Figma, Linear, Raycast, Arc. Generous whitespace. Content is the hero.

## Color

```css
/* Base */
--color-bg:          #ffffff;
--color-bg-subtle:   #f9f9f9;
--color-bg-muted:    #f3f3f3;

/* Borders */
--color-border:      #e5e5e5;
--color-border-strong: #d0d0d0;

/* Text */
--color-text:        #111111;
--color-text-secondary: #666666;
--color-text-muted:  #999999;
--color-text-disabled: #bbbbbb;

/* Brand (single accent, used sparingly) */
--color-accent:      #0070f3;
--color-accent-hover: #005ee0;
--color-accent-muted: #e8f1fd;

/* Status */
--color-success:     #16a34a;
--color-warning:     #d97706;
--color-error:       #dc2626;
--color-info:        #2563eb;
```

## Typography

```css
--font-sans: 'Inter', system-ui, -apple-system, sans-serif;
--font-mono: 'Geist Mono', 'Fira Code', monospace;

/* Scale (use sparingly — pick 2–3 sizes per page) */
--text-xs:   0.75rem;   /* 12px — labels, captions */
--text-sm:   0.875rem;  /* 14px — body secondary */
--text-base: 1rem;      /* 16px — body primary */
--text-lg:   1.125rem;  /* 18px — subheadings */
--text-xl:   1.25rem;   /* 20px */
--text-2xl:  1.5rem;    /* 24px — section headings */
--text-3xl:  1.875rem;  /* 30px — page headings */
--text-4xl:  2.25rem;   /* 36px — hero */

--font-weight-normal:   400;
--font-weight-medium:   500;
--font-weight-semibold: 600;
--font-weight-bold:     700;

--leading-tight:  1.25;
--leading-normal: 1.5;
--leading-relaxed: 1.75;
```

## Spacing

```css
/* 4px base grid */
--space-1:  0.25rem;   /*  4px */
--space-2:  0.5rem;    /*  8px */
--space-3:  0.75rem;   /* 12px */
--space-4:  1rem;      /* 16px */
--space-5:  1.25rem;   /* 20px */
--space-6:  1.5rem;    /* 24px */
--space-8:  2rem;      /* 32px */
--space-10: 2.5rem;    /* 40px */
--space-12: 3rem;      /* 48px */
--space-16: 4rem;      /* 64px */
--space-20: 5rem;      /* 80px */
--space-24: 6rem;      /* 96px */
```

## Radius & Shadows

```css
--radius-sm:  4px;
--radius-md:  8px;
--radius-lg:  12px;
--radius-xl:  16px;
--radius-full: 9999px;

/* Minimal shadows — used only for elevation, not decoration */
--shadow-sm:  0 1px 2px rgba(0,0,0,0.06);
--shadow-md:  0 2px 8px rgba(0,0,0,0.08);
--shadow-lg:  0 8px 24px rgba(0,0,0,0.08);
```

## Tailwind Config Snippet

```js
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        accent: { DEFAULT: '#0070f3', hover: '#005ee0', muted: '#e8f1fd' },
        border: { DEFAULT: '#e5e5e5', strong: '#d0d0d0' },
        text: { DEFAULT: '#111111', secondary: '#666666', muted: '#999999' },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['Geist Mono', 'Fira Code', 'monospace'],
      },
    },
  },
}
```

## Do / Don't

| Do | Don't |
|----|-------|
| Let whitespace breathe | Cram elements close together |
| One accent color, used sparingly | Multiple competing accent colors |
| Light borders over shadows | Heavy drop shadows |
| Medium weight (500) for emphasis | Bold everywhere |
| Consistent 4px grid | Arbitrary pixel values |
