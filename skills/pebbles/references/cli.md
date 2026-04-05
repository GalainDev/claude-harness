# Pebbles CLI Reference

Use these commands via `pb` (or `./pb` if not on PATH). Add `--json` for machine-readable output.

## Session

- `pb start`
- `pb lock <id>` / `pb lock --clear`
- `pb relay "message"` / `pb relay --clear`
- `pb path <id>`

## Missions

- `pb create "Title" [--type mission|feature|bug|chore|epic|protocol] [--priority 0-4]`
- `pb show <id>`
- `pb update <id> [--status open|in_progress|blocked|done|deferred] [--priority 0-4]`
- `pb close <id> --summary "wrap-up"`
- `pb list [--status ...] [--type ...]`
- `pb ready`
- `pb defer <id> [--until "time"]`
- `pb undefer <id>`

## Blocking

- `pb link <id> <blocker-id>`
- `pb unlink <id> <blocker-id>`
- `pb chain <id1> <id2> <id3>`
- `pb ward --await timer:2h --blocks <id>`
- `pb wards`
- `pb breach <ward-id>`

## Notes and Comments

- `pb comment <id> "text"`
- `pb note <id> "state"`

## History and Branching

- `pb log`
- `pb history <id>`
- `pb recall <id> --as-of <commit>`
- `pb diff <from> <to>`
- `pb checkpoint [name]`
- `pb branch [name] [--create] [--delete]`

## Protocols

- `pb protocol list`
- `pb protocol show <id>`
- `pb protocol new "Title"`
- `pb launch <protocol-id> [--probe]`
- `pb derive <mission-id>`
- `pb archive <probe-id> "summary"`
- `pb discard <probe-id>`

## Dashboard

- `pb serve --port 3333` — starts web dashboard with write proxy support
  - When running, CLI commands automatically proxy writes through the server
  - Allows concurrent dashboard viewing and CLI usage

## Maintenance

- `pb repair [--fix]` — check/fix data integrity
- `pb purge [--days 30]` — remove old completed missions
- `pb compact` — run Dolt garbage collection

## Import/Export

- `pb export > backup.json`
- `pb import < backup.json`
- `pb parse <file>` — parse document into missions
