# Minimal Clean — Component Patterns

## Button

```tsx
// Primary — single accent, no gradients
<button className="bg-accent hover:bg-accent-hover text-white text-sm font-medium 
  px-4 py-2 rounded-md transition-colors duration-150">
  Save changes
</button>

// Secondary — bordered, no fill
<button className="border border-border text-text text-sm font-medium 
  px-4 py-2 rounded-md hover:bg-bg-muted transition-colors duration-150">
  Cancel
</button>

// Ghost — text only
<button className="text-text-secondary text-sm hover:text-text transition-colors">
  View all
</button>
```

## Input

```tsx
<div className="flex flex-col gap-1.5">
  <label className="text-sm font-medium text-text">Email</label>
  <input
    type="email"
    placeholder="you@example.com"
    className="border border-border rounded-md px-3 py-2 text-sm text-text
      placeholder:text-text-muted bg-white
      focus:outline-none focus:ring-2 focus:ring-accent/20 focus:border-accent
      transition-shadow"
  />
  <p className="text-xs text-text-muted">We'll never share your email.</p>
</div>
```

## Card

```tsx
// Minimal — border only, no shadow
<div className="border border-border rounded-lg p-6 bg-white">
  {children}
</div>

// Elevated — subtle shadow for interactive cards
<div className="border border-border rounded-lg p-6 bg-white shadow-sm
  hover:shadow-md transition-shadow duration-200 cursor-pointer">
  {children}
</div>
```

## Layout

```tsx
// Page container
<div className="max-w-5xl mx-auto px-6 py-12">
  {children}
</div>

// Section spacing
<section className="space-y-8">
  <header className="space-y-2">
    <h2 className="text-2xl font-semibold text-text tracking-tight">Title</h2>
    <p className="text-text-secondary">Description text goes here.</p>
  </header>
  {content}
</section>
```

## Badge / Tag

```tsx
<span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs 
  font-medium bg-bg-muted text-text-secondary border border-border">
  Label
</span>
```

## Empty State

```tsx
<div className="flex flex-col items-center justify-center py-16 text-center gap-3">
  <div className="text-text-muted text-4xl">{icon}</div>
  <h3 className="text-base font-medium text-text">Nothing here yet</h3>
  <p className="text-sm text-text-muted max-w-xs">Descriptive text explaining next action.</p>
  <button className="...">Primary action</button>
</div>
```
