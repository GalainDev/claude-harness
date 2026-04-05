---
name: react-frontend
description: |
  Expert React and frontend engineering skill. Use this when the user is building UI components,
  pages, layouts, or any web interface — whether from scratch or modifying existing code.
  Triggers on: component creation, JSX/TSX work, styling (CSS, Tailwind, CSS-in-JS), state
  management (useState, useReducer, Zustand, Redux), hooks (custom or built-in), React Router,
  form handling, accessibility concerns, performance optimization (memoization, lazy loading,
  virtualization), frontend testing (React Testing Library, Vitest, Playwright), Next.js, Vite,
  data fetching (React Query, SWR, fetch, axios), animations (Framer Motion, CSS), design systems,
  and TypeScript in a React context. Also triggers when the user is reviewing or debugging
  React rendering issues, hydration errors, or layout problems.
---

# React Frontend Skill

A pragmatic, opinionated guide for building production-quality React applications. Bias toward
modern patterns (hooks, composition, TypeScript) and correctness over cleverness.

## Design System — Check Registry First

Before writing any UI code, determine the active design system:

1. **Check project root** for `.claude/design.json`:
   ```json
   { "system": "dark-modern" }
   ```
2. **Check `CLAUDE.md`** in the project for a `design:` declaration
3. **Fall back** to `defaultSystem` in `skills/react-frontend/design/registry.json`

Once identified, load the corresponding tokens and patterns from:
```
skills/react-frontend/design/systems/<system-name>/tokens.md
skills/react-frontend/design/systems/<system-name>/patterns.md
```

**Apply the active design system consistently** — use its color tokens, spacing scale, typography,
and component patterns throughout the session. Do not mix token values from different systems.

Available systems: `minimal-clean`, `brutalist`, `glassmorphism`, `corporate-saas`, `dark-modern`

To switch system mid-project: create/update `.claude/design.json` at project root.

---

## Core Philosophy

- **Composition over inheritance** — prefer small, focused components that compose well
- **Colocate related code** — keep a component's logic, styles, and tests near each other
- **Explicit over implicit** — name things clearly; avoid magic
- **Accessibility is not optional** — every interactive element needs keyboard and screen reader support

---

## Process

### 1. Understand the shape of the data first
Before writing JSX, identify:
- What data does this component receive (props)?
- What does it own internally (state)?
- What side effects does it need (effects/queries)?

### 2. Define types before implementation
```typescript
// Define the contract first
interface UserCardProps {
  user: Pick<User, 'id' | 'name' | 'avatarUrl'>
  onFollow: (userId: string) => void
  isFollowing: boolean
}
```

### 3. Component structure (canonical order)
```typescript
// 1. Imports (external → internal → types → styles)
// 2. Types/interfaces
// 3. Constants (outside component)
// 4. Component function
//    a. Hooks (in consistent order: state → refs → derived → effects → callbacks)
//    b. Early returns (loading, error, empty states)
//    c. JSX
// 5. Sub-components (small, only if not reused elsewhere)
// 6. Default export
```

### 4. State management decision tree
- **Local UI state** (open/closed, hover) → `useState`
- **Complex local state with transitions** → `useReducer`
- **Server state** (remote data, caching, invalidation) → React Query or SWR
- **Shared client state** (auth, theme, cart) → Zustand (small) or Redux Toolkit (large)
- **Form state** → React Hook Form
- **URL state** (filters, pagination) → search params via React Router or Next.js

### 5. Performance — only optimize when there's evidence
```typescript
// Memoize expensive calculations, not simple ones
const sorted = useMemo(() => expensiveSort(items), [items])

// Stabilize callbacks passed to memoized children
const handleClick = useCallback(() => doThing(id), [id])

// Memoize components that receive stable props but re-render often
const Row = memo(({ item, onSelect }: RowProps) => { ... })
```

### 6. Data fetching pattern (React Query)
```typescript
// Prefer query functions in a separate file (queries.ts)
export const useUser = (id: string) =>
  useQuery({ queryKey: ['user', id], queryFn: () => fetchUser(id) })

// Mutations — always invalidate or update cache
const mutation = useMutation({
  mutationFn: updateUser,
  onSuccess: () => queryClient.invalidateQueries({ queryKey: ['user'] }),
})
```

### 7. Error boundaries
Every route-level component and async data boundary should be wrapped:
```typescript
<ErrorBoundary fallback={<ErrorFallback />}>
  <Suspense fallback={<Skeleton />}>
    <AsyncComponent />
  </Suspense>
</ErrorBoundary>
```

---

## Current Best Practices (2025)

### Styling
- **Tailwind CSS** — utility-first, great for colocated styles; use `cn()` (clsx + tailwind-merge)
- **CSS Modules** — good for component-scoped styles without runtime cost
- Avoid inline styles except for dynamic values (e.g., `style={{ width: percent + '%' }}`)

### File structure (feature-based)
```
src/
  features/
    auth/
      components/
      hooks/
      api.ts
      types.ts
  components/          # shared/generic only
  lib/                 # utilities
  app/ or pages/       # routes
```

### TypeScript
- Enable `strict: true` in tsconfig
- Avoid `any` — use `unknown` and narrow it
- Prefer `type` over `interface` for unions/intersections; `interface` for extendable shapes
- Use `satisfies` operator for config objects to get both inference and type checking

### Testing
```typescript
// Test behavior, not implementation
// Use queries in priority order: getByRole > getByLabelText > getByText > getByTestId
it('submits the form with valid data', async () => {
  render(<LoginForm onSuccess={mockFn} />)
  await userEvent.type(screen.getByLabelText(/email/i), 'user@example.com')
  await userEvent.click(screen.getByRole('button', { name: /sign in/i }))
  expect(mockFn).toHaveBeenCalled()
})
```

### Accessibility checklist
- [ ] All images have meaningful `alt` text (or `alt=""` for decorative)
- [ ] Interactive elements are focusable and have visible focus rings
- [ ] Forms: every input has an associated `<label>`
- [ ] Color contrast: 4.5:1 for normal text, 3:1 for large text
- [ ] Dynamic content uses `aria-live` regions appropriately
- [ ] Modal dialogs trap focus and restore it on close

---

## Red Flags

- A component over ~200 lines — split it
- `useEffect` with no deps array or broad deps — likely a bug
- `key={index}` in lists with reorderable items — use stable IDs
- Direct DOM manipulation inside React — use refs
- Prop drilling more than 2–3 levels — lift to context or state manager
- `as any` or `@ts-ignore` — fix the type instead

---

## Verification Checklist

Before considering frontend work done:

- [ ] TypeScript compiles with no errors (`tsc --noEmit`)
- [ ] No ESLint errors or warnings
- [ ] Component renders correctly in happy path, loading, error, and empty states
- [ ] Keyboard navigation works (Tab, Enter, Escape, arrow keys where applicable)
- [ ] Tests pass (`vitest run` or `jest`)
- [ ] No console errors or warnings in the browser
- [ ] Responsive at mobile (375px), tablet (768px), and desktop (1280px)
