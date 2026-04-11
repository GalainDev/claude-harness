# Animation Reference

Deep reference for the frontend-design skill's motion section.

## The Full Decision Framework

### Step 1 — Should it animate at all?

Frequency is the primary filter:

| Use pattern | Decision |
|-------------|----------|
| 100+ times/day — keyboard shortcuts, command toggles | No animation. Ever. |
| Tens of times/day — hover, list navigation | Remove or reduce to near-zero |
| Occasional — modals, drawers, toasts | Standard animation |
| Rare / first-time — onboarding, empty state, celebration | Can add delight |

Raycast has no open/close animation. That's the right call for something used hundreds of times daily.

### Step 2 — What's the purpose?

Every animation must answer: "why does this animate?" Valid answers:

- **Spatial continuity** — toast enters and exits from the same edge, making swipe-to-dismiss feel logical
- **State change** — morphing button communicates the operation completed
- **Explanation** — marketing animation shows how a feature works
- **Feedback** — button scales down on press, confirming the UI heard the user
- **Preventing jarring cuts** — element appearing instantly without transition reads as broken

"It looks cool" with something shown repeatedly → don't animate.

### Step 3 — Easing

```
Is it entering or exiting?
  Yes → ease-out (starts fast, responsive)
  No →
    Moving/morphing on screen?
      Yes → ease-in-out (natural arc)
    Hover or color change?
      Yes → ease
    Constant motion (marquee, progress)?
      Yes → linear
    Default → ease-out
```

**Never use ease-in for UI.** It starts slow — exactly when the user is watching most closely. A 300ms ease-in dropdown _feels_ slower than a 300ms ease-out one even though the duration is identical.

**Use custom curves.** Built-in CSS easings are too weak:

```css
--ease-out-strong:   cubic-bezier(0.23, 1, 0.32, 1);
--ease-in-out-strong: cubic-bezier(0.77, 0, 0.175, 1);
--ease-drawer:       cubic-bezier(0.32, 0.72, 0, 1);  /* iOS drawer feel */
```

### Step 4 — Duration

| Element | Range |
|---------|-------|
| Button press feedback | 100–160ms |
| Tooltips, small popovers | 125–200ms |
| Dropdowns, selects | 150–250ms |
| Modals, drawers | 200–350ms |
| Page transitions | 250–400ms |
| Marketing / explanatory | Longer is fine |

Hard limit for UI: **300ms**. Beyond that, the interface feels like it's making the user wait.

Perceived speed matters as much as real speed. A faster-spinning loader makes an app feel faster at the same actual load time. `ease-out` at 200ms feels faster than `ease-in` at 200ms.

---

## Spring Animations

Springs feel natural because they simulate real physics — no fixed duration, they settle based on parameters.

**Use springs for:**
- Drag interactions with momentum
- Elements that should feel "alive"
- Gestures that can be interrupted mid-flight
- Decorative mouse-tracking interactions

**Apple's approach (easiest to reason about):**
```js
{ type: "spring", duration: 0.5, bounce: 0.2 }
```

**Traditional physics (more control):**
```js
{ type: "spring", mass: 1, stiffness: 100, damping: 20 }
```

Keep `bounce` between 0.1–0.3. Avoid bounce in most UI contexts — use it for drag-to-dismiss and deliberately playful interactions.

**Key advantage:** Springs maintain velocity when interrupted. CSS keyframes restart from zero. This makes springs ideal for gestures the user might reverse mid-motion.

---

## CSS Patterns

### `@starting-style` — entry animation without JS

```css
.popover {
  opacity: 1;
  transform: scale(1);
  transition: opacity 200ms ease-out, transform 200ms ease-out;

  @starting-style {
    opacity: 0;
    transform: scale(0.95);
  }
}
```

Replaces the `useEffect` + `data-mounted` pattern for simple enter animations.

### `clip-path` reveals

`clip-path: inset(top right bottom left)` — each value eats into the element from that side.

```css
/* Hidden (clipped from right) */
.hidden { clip-path: inset(0 100% 0 0); }

/* Visible */
.visible { clip-path: inset(0 0 0 0); }
```

Use cases:
- **Tab color transitions** — duplicate the tab bar, style copy as "active", clip to show only the active tab. Animate clip on change. Produces seamless color transitions timing can't achieve.
- **Hold-to-confirm** — `clip-path: inset(0 100% 0 0)` on an overlay. On `:active`, transition to `inset(0 0 0 0)` over 2s linear. Release snaps back in 200ms ease-out.
- **Image reveal on scroll** — start `inset(0 0 100% 0)`, animate to `inset(0 0 0 0)` on viewport entry via IntersectionObserver.

### CSS transitions vs keyframes

| | Transitions | Keyframes |
|---|---|---|
| Interruptible | Yes — retarget mid-animation | No — restart from zero |
| Dynamic values | Yes | No |
| Use for | Rapidly triggered UI (toasts, toggles) | Predetermined, one-shot animations |

For anything that can be triggered repeatedly or interrupted (toast queue, list reorder), use transitions.

### Height reveals without layout thrash

```css
.expandable {
  display: grid;
  grid-template-rows: 0fr;
  transition: grid-template-rows 250ms ease-out;
}
.expandable.open {
  grid-template-rows: 1fr;
}
.expandable > * { overflow: hidden; }
```

Avoids animating `height` (which triggers layout) by animating grid track size instead.

### Blur to mask imperfect crossfades

When a crossfade between two states feels off despite correct timing, add `filter: blur(4px)` during the transition. Blur bridges the visual gap — the eye perceives a single smooth transformation instead of two objects swapping.

Keep blur under 20px. Heavy blur is expensive, especially in Safari.

---

## Performance

### GPU-composited properties only

Only `transform` and `opacity` skip layout and paint. Everything else triggers the full rendering pipeline.

```
Animating: transform, opacity → compositor thread (smooth)
Animating: padding, margin, height, width, top, left → main thread (janky)
```

### Framer Motion hardware acceleration

`x`, `y`, `scale` shorthand props are NOT hardware-accelerated — they use `requestAnimationFrame` on the main thread. Under load (page navigation, data fetch), they drop frames.

```jsx
// Hardware-accelerated — stays smooth under main thread load
<motion.div animate={{ transform: "translateX(100px)" }} />

// Not hardware-accelerated
<motion.div animate={{ x: 100 }} />
```

Use the shorthand for simple interactions, the full `transform` string when 60fps is critical.

### CSS animations vs JS animations under load

CSS animations run off the main thread. Framer Motion's `requestAnimationFrame`-based animations run on the main thread. When the browser is loading a page, running scripts, or painting, CSS animations remain smooth while JS animations drop frames.

Rule of thumb:
- Predetermined, non-interactive → CSS animations
- Dynamic, interruptible, data-driven → JS (Framer Motion)
- Needs JS control with CSS performance → Web Animations API (`element.animate([...], {...})`)

### CSS variables on animated elements

Changing a CSS variable on a parent triggers style recalculation for all its children. In a list with many items, this is expensive.

```js
// Expensive — recalculates all children
container.style.setProperty('--offset', `${y}px`);

// Cheap — only affects this element
element.style.transform = `translateY(${y}px)`;
```

---

## Gesture Patterns

### Momentum-based dismissal

Don't require dragging past a pixel threshold. Calculate velocity:

```js
const velocity = Math.abs(swipeAmount) / timeTakenMs;
if (Math.abs(swipeAmount) >= THRESHOLD || velocity > 0.11) {
  dismiss();
}
```

A quick flick should dismiss. Users shouldn't have to drag 50% of the screen.

### Damping at boundaries

When dragging past a natural boundary (drawer already fully open, pulled further), apply damping — the more they drag, the less the element moves. Hard stops feel broken. Real things slow down before they stop.

### Multi-touch guard

Ignore additional touch points after drag starts. Without this, switching fingers mid-drag causes the element to jump.

```js
function onPointerDown(e) {
  if (isDragging) return;
  // start drag
}
```

---

## Accessibility

### `prefers-reduced-motion`

```css
@media (prefers-reduced-motion: reduce) {
  /* Keep: opacity, color, filter transitions */
  /* Remove: transform-based motion, position changes */
  .animated {
    transition: opacity 150ms ease;
    /* no transform */
  }
}
```

```jsx
const prefersReduced = useReducedMotion();
const enterX = prefersReduced ? 0 : '-100%';
```

Reduced motion means fewer, gentler animations — not zero. Opacity and color transitions aid comprehension and should stay.

### Touch hover guard

```css
@media (hover: hover) and (pointer: fine) {
  .card:hover { transform: translateY(-2px); }
}
```

Touch devices fire hover on tap. Without this guard, hover effects trigger on tap and stick until the user taps elsewhere.
