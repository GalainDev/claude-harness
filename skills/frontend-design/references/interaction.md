# Interaction Design Reference

## The Eight States

Every interactive element needs all eight states designed — not just default and hover:

| State | When | Treatment |
|-------|------|-----------|
| **Default** | At rest | Base styling |
| **Hover** | Pointer over (not touch) | Subtle lift, color shift |
| **Focus** | Keyboard/programmatic focus | Visible ring (see below) |
| **Active** | Being pressed | `scale(0.97)` or `translateY(-1px)`, darker |
| **Disabled** | Not interactive | Reduced opacity, `cursor: not-allowed`, no pointer events |
| **Loading** | Processing | Skeleton or spinner with meaningful copy |
| **Error** | Invalid state | Border color change, icon, inline message |
| **Success** | Completed | Confirmation — brief, then return to default |

**The common miss:** designing hover without focus. They serve different users — mouse and keyboard. Never conflate them.

---

## Focus Rings — Never Remove Without Replacing

`outline: none` with no replacement is an accessibility violation. Use `:focus-visible` to show rings only for keyboard navigation:

```css
/* Reset the browser default for mouse users */
*:focus { outline: none; }

/* Show a proper ring for keyboard/programmatic focus */
*:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 3px;
  border-radius: 3px;
}
```

Focus ring requirements:
- 3:1 contrast minimum against adjacent colors
- 2–3px thickness
- Offset from the element (not inside it)
- Consistent across all interactive elements

---

## States That Must Be Implemented

### Loading

**Skeleton screens over spinners.** Skeletons preview the content shape — users perceive them as faster because they understand what's coming. Spinners give no information.

```css
.skeleton {
  background: linear-gradient(
    90deg,
    var(--neutral-100) 25%,
    var(--neutral-200) 50%,
    var(--neutral-100) 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}
@keyframes shimmer {
  0%   { background-position: 200% center; }
  100% { background-position: -200% center; }
}
```

Match the skeleton to the actual layout shape — not a generic gray rectangle.

### Empty states

Empty states are onboarding moments, not error conditions. Three parts:
1. Acknowledge briefly ("No projects yet")
2. Explain the value ("Create one to start tracking work")
3. Provide the action (a CTA button that starts the flow)

Never: "No items found." with nothing else. Never: a sad icon with generic copy.

### Error states

Inline, specific, actionable. The formula: what happened + why + how to fix it.

| Bad | Good |
|-----|------|
| "Invalid input" | "Email must include an @ symbol — e.g. you@example.com" |
| "Error occurred" | "Couldn't save changes. Check your connection and try again." |
| "Access denied" | "You don't have access to this project. Ask an admin to invite you." |

Don't blame the user. "Please enter a date in MM/DD/YYYY format" — not "You entered an invalid date."

Place errors below the field they belong to, not at the top of the form. Connect them with `aria-describedby`.

---

## Optimistic UI

Update the UI immediately on user action, sync in the background, roll back on failure.

**Use for low-stakes actions:** likes, follows, reorders, toggles, preference saves.
**Never use for:** payments, destructive actions, anything irreversible.

```tsx
// Example: optimistic toggle
const [liked, setLiked] = useState(post.liked)

async function toggle() {
  setLiked(prev => !prev)          // immediate UI update
  try {
    await api.toggleLike(post.id)
  } catch {
    setLiked(prev => !prev)         // roll back on failure
    toast.error("Couldn't save. Try again.")
  }
}
```

---

## Progressive Disclosure

Start simple, reveal complexity through interaction. Not everything belongs on the surface.

Patterns:
- Basic options visible, advanced behind an expandable section
- Hover/click reveals secondary actions (don't show them until needed)
- Step-by-step forms instead of one overwhelming page
- Details in a drawer, not a modal

**Don't make every button primary.** Use ghost buttons, text links, and secondary styles. Hierarchy communicates importance — if everything is primary, nothing is.

---

## Modals — Use Sparingly

Modals interrupt context. Use only when there's genuinely no better alternative — confirmation of a destructive action, a focused multi-step flow with no logical inline location.

For most cases, prefer:
- **Inline expansion** — reveal content where the trigger is
- **Drawer/sheet** — slides in from an edge, preserves context
- **Popover** — anchored to the trigger, dismisses naturally

When you must use a modal, use native `<dialog>`:

```html
<dialog id="confirm-dialog">
  <h2>Delete project?</h2>
  <p>This can't be undone.</p>
  <button value="cancel" formmethod="dialog">Cancel</button>
  <button id="confirm">Delete</button>
</dialog>
```

```js
const dialog = document.getElementById('confirm-dialog')
dialog.showModal()  // opens with focus trap, Escape to dismiss
```

Or use the `inert` attribute to trap focus without a dialog element:

```html
<main inert><!-- blurred/disabled while modal is open --></main>
<div role="dialog" aria-modal="true"><!-- your modal --></div>
```

---

## Forms

- Label above input — always. Placeholders disappear on type and fail contrast.
- Validate on blur, not on every keystroke. Exception: password strength meters.
- Error text below the field, connected via `aria-describedby`.
- Helper text below label (above input) — visible before interaction.
- Standard block spacing between fields: `gap: var(--space-4)` for label + input, `gap: var(--space-5)` between fields.

```html
<div class="field">
  <label for="email">Email address</label>
  <span class="hint" id="email-hint">We'll send a confirmation link</span>
  <input
    type="email"
    id="email"
    aria-describedby="email-hint email-error"
    aria-invalid="true"
  />
  <span class="error" id="email-error">
    Include an @ symbol — e.g. you@example.com
  </span>
</div>
```

---

## Touch Targets

Minimum 44×44px for all interactive elements, regardless of visual size. Expand via padding or pseudo-element:

```css
.small-button {
  position: relative;
}
.small-button::before {
  content: '';
  position: absolute;
  inset: -10px;
}
```

---

## Hover Guards for Touch Devices

Touch devices fire `:hover` on tap and it sticks until the user taps elsewhere. Gate all hover effects:

```css
@media (hover: hover) and (pointer: fine) {
  .card:hover {
    transform: translateY(-2px);
    box-shadow: var(--shadow-md);
  }
}
```
