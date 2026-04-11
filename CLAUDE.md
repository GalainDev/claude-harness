# Claude Code — Global Instructions

## Working Style

- Spec before code — for any non-trivial feature, create a `spec.md` with acceptance criteria first
- Verify before done — run types, lint, and tests before marking any task complete
- Terse responses — skip summaries of what was just done; lead with the result
- No trailing explanations — if the user can read the diff, don't describe it again

## Session Defaults

- Destructive operations (rm -rf, force-push, reset --hard, DROP TABLE) are blocked by hooks
- Do not attempt workarounds to the hooks — they are intentional safety gates
- When implementing a non-trivial feature, use the `spec-driven` skill first
- After implementation, run the `verify` skill before declaring done
- Check `.claude/design.json` or project `CLAUDE.md` before writing any frontend UI code

## Code Style

**TypeScript/React:**
- `strict: true` always
- Prefer `type` for unions, `interface` for extendable shapes
- Tailwind + `cn()` (clsx + tailwind-merge) for styling
- React Query for server state, Zustand for shared client state
- React Testing Library + Vitest for tests
- Test behavior, not implementation

**Go:**
- Errors are values — handle and wrap with context at every boundary
- stdlib first, then minimal dependencies
- `internal/` over `pkg/` for application code
- `log/slog` for structured logging
- Table-driven tests with `t.Run`
- `go test -race` always

## Tooling Quick Reference

| Task | Command |
|------|---------|
| New spec | `./skills/spec-driven/scripts/new-spec.sh "Feature Name"` |
| RLAIF eval | `./skills/spec-driven/scripts/rlaif-loop.sh specs/my-feature.md` |
| Full verify | `./skills/verify/scripts/verify.sh` |
| Verify (no e2e) | `./skills/verify/scripts/verify.sh --skip-e2e` |
| Commit | `/commit` (asks verbose or minimal) |
| Code review | `/review` |
| Browser (E2E) | `agent-browser open <url>` → `agent-browser snapshot` → `agent-browser click @eN` |

## Design Systems

Available: `minimal-clean`, `brutalist`, `glassmorphism`, `corporate-saas`, `dark-modern`

Declare per-project in `.claude/design.json`:
```json
{ "system": "dark-modern" }
```
