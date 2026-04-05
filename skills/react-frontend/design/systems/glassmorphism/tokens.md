# Glassmorphism — Design Tokens

**Aesthetic:** Frosted glass, translucency, gradients, layered depth. iOS 16 / macOS Ventura quality.

## Color

```css
/* Dark base (glass works best on dark or gradient backgrounds) */
--color-bg:           #0f0f1a;
--color-bg-gradient:  linear-gradient(135deg, #0f0f1a 0%, #1a1a2e 50%, #16213e 100%);

/* Glass surfaces */
--glass-bg:           rgba(255, 255, 255, 0.05);
--glass-bg-hover:     rgba(255, 255, 255, 0.08);
--glass-bg-active:    rgba(255, 255, 255, 0.12);
--glass-border:       rgba(255, 255, 255, 0.12);
--glass-border-strong: rgba(255, 255, 255, 0.25);

/* Text */
--color-text:         rgba(255, 255, 255, 0.92);
--color-text-secondary: rgba(255, 255, 255, 0.55);
--color-text-muted:   rgba(255, 255, 255, 0.3);

/* Accent gradients */
--gradient-accent:    linear-gradient(135deg, #667eea 0%, #764ba2 100%);
--gradient-blue:      linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
--gradient-purple:    linear-gradient(135deg, #a18cd1 0%, #fbc2eb 100%);
--gradient-orange:    linear-gradient(135deg, #f093fb 0%, #f5576c 100%);

/* Glow */
--glow-purple:  0 0 40px rgba(102, 126, 234, 0.4);
--glow-blue:    0 0 40px rgba(79, 172, 254, 0.4);
```

## Blur & Effects

```css
/* Core glass effect */
--blur-sm:  blur(8px);
--blur-md:  blur(16px);
--blur-lg:  blur(24px);
--blur-xl:  blur(40px);

/* Noise texture overlay (subtle grain adds realism) */
--noise-opacity: 0.03;

/* Glass card shadow */
--shadow-glass: 0 8px 32px rgba(0, 0, 0, 0.4), inset 0 1px 0 rgba(255,255,255,0.1);
```

## Typography

```css
--font-sans: 'Inter', 'SF Pro Display', system-ui, sans-serif;

/* Weights — medium for readability on glass */
--font-weight-normal:   400;
--font-weight-medium:   500;
--font-weight-semibold: 600;
```

## Radius

```css
/* Glass = generous radius */
--radius-sm:  8px;
--radius-md:  16px;
--radius-lg:  24px;
--radius-xl:  32px;
--radius-2xl: 48px;
```

## Core Tailwind Utilities

```js
// In tailwind.config.js plugins or global CSS
// Glass card utility
'.glass': {
  background: 'rgba(255, 255, 255, 0.05)',
  backdropFilter: 'blur(16px)',
  WebkitBackdropFilter: 'blur(16px)',
  border: '1px solid rgba(255, 255, 255, 0.12)',
  borderRadius: '16px',
  boxShadow: '0 8px 32px rgba(0, 0, 0, 0.4)',
},
```

## Component Snippets

```tsx
// Glass card
<div className="bg-white/5 backdrop-blur-xl border border-white/10 rounded-2xl p-6
  shadow-[0_8px_32px_rgba(0,0,0,0.4)]">
  {children}
</div>

// Glass button with gradient border
<button className="relative bg-white/10 backdrop-blur-md rounded-xl px-6 py-3
  border border-white/20 text-white font-medium
  hover:bg-white/15 transition-colors">
  {label}
</button>

// Gradient accent text
<span className="bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent font-semibold">
  {text}
</span>
```

## Do / Don't

| Do | Don't |
|----|-------|
| Dark/gradient background behind glass | Light backgrounds (glass disappears) |
| Generous blur (16–24px) | Barely visible blur (4px) |
| Subtle border (white/10–white/20) | No border (glass loses definition) |
| Layered depths (multiple glass planes) | Single flat glass layer |
| Use noise/grain texture for realism | Pure clean glass (looks flat) |
