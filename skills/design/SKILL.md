---
name: design
description: Set the active design system for the current project by writing .claude/design.json. User-invocable as /design. Lists available design systems and writes the chosen one to the project. Use when starting a new project, switching design direction, or when the user asks "what design system should I use" or "set up the design for this project".
user-invocable: true
metadata:
  author: galain
  version: 1.0.0
  category: frontend
---

# Design System Selector

Sets the active design system for this project by writing `.claude/design.json`.
All frontend skills (react-frontend, frontend-design) read this file before generating any UI.

---

## Step 1 — Show options and ask

Present the six available systems and ask the user to pick one:

---

**Available design systems:**

| Key | Aesthetic | Best for |
|-----|-----------|---------|
| `minimal-clean` | Figma, Linear, Raycast — whitespace-led, typography-first | Productivity tools, docs, content-first apps |
| `brutalist` | Raw, high-contrast, bold borders, flat color | Editorial, portfolios, strong brand opinions |
| `glassmorphism` | Frosted glass, blurs, translucency, depth | Consumer apps, mobile-first, visually rich UIs |
| `corporate-saas` | Stripe, Notion, Vercel — polished, professional, trustworthy | B2B SaaS, marketing sites, dashboards |
| `dark-modern` | VS Code, Vercel dashboard, Raycast dark — developer tool quality | Dev tools, internal dashboards, technical users |
| `ai-saas` | Cursor, Perplexity, Linear — precision dark UI for AI products | AI-first products, chat interfaces, agent UIs, Vault |

---

Use the AskUserQuestion tool to ask:

> "Which design system? (minimal-clean / brutalist / glassmorphism / corporate-saas / dark-modern / ai-saas)"

If the user already passed a system name as an argument to /design, skip this step and use that value directly.

---

## Step 2 — Validate the choice

Accepted values: `minimal-clean`, `brutalist`, `glassmorphism`, `corporate-saas`, `dark-modern`, `ai-saas`

If the input doesn't match, say which values are valid and ask again.

---

## Step 3 — Write `.claude/design.json`

Check if `.claude/` exists in the current working directory. If not, create it.

Write `.claude/design.json` with:

```json
{ "system": "<chosen-system>" }
```

Example for ai-saas:
```json
{ "system": "ai-saas" }
```

---

## Step 4 — Confirm and summarise

Tell the user:
- Which system was set
- What it's optimised for (one sentence from the table above)
- That all subsequent frontend work in this project will use it
- The token file location for reference: `~/.claude/skills/react-frontend/design/systems/<system>/tokens.md`

Example:
> Set to `ai-saas` — precision dark UI for AI-first products (Cursor/Perplexity aesthetic).
> Token reference: `~/.claude/skills/react-frontend/design/systems/ai-saas/tokens.md`

---

## Notes

- Only write `.claude/design.json` — do not modify any other project file
- If `.claude/design.json` already exists, show the current value and ask if they want to replace it
- Do not infer or guess the design system — always confirm with the user
