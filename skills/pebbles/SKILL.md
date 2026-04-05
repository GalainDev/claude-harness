---
name: pebbles
description: "Use when working in a Pebbles repo (pb CLI + Dolt) to manage missions, locks/relays, blockers/wards, protocols, history/branches, or the dashboard. Applies to both Codex CLI and Claude Code workflows."
license: MIT
metadata:
  author: pebbles
  version: "0.3.0"
---

# Pebbles: Mission Memory for Coding Agents

Pebbles is a local, Dolt-backed mission tracker that gives coding agents durable task memory across sessions.

## CRITICAL: Initialization Check

Before any `pb` command:

1. Verify `.pebbles/` exists in the repo root.
   - Codex CLI: use `ls` or `find . -maxdepth 2 -name .pebbles`.
   - Claude Code: use Glob with pattern `.pebbles`.
2. If missing, run `pb init` (or `./pb init` if `pb` is not on PATH).

Do not proceed until initialization is confirmed.

## Session Workflow

1. Run `pb start` to load lock, relay, ready, and blocked missions.
2. Lock exactly one mission: `pb lock <id>`.
3. Update status, comments, notes as you work.
4. Leave a relay before stopping: `pb relay "what changed and what is next"`.

## Core Capabilities

- Mission lifecycle: `pb create`, `pb update`, `pb close`, `pb list`, `pb ready`.
- Blockers: `pb link`, `pb unlink`, `pb chain`, `pb ward`, `pb breach`.
- Time travel: `pb log`, `pb history`, `pb recall`, `pb diff`, `pb checkpoint`, `pb branch`.
- Protocols: `pb protocol`, `pb launch`, `pb derive`, `pb archive`, `pb discard`.
- Dashboard: `pb serve --port 3333` (with write proxy support).

For the full command reference, read `references/cli.md`.

## Dashboard & Concurrent Access

When `pb serve` is running:
- Web dashboard available at `http://localhost:3333`
- CLI commands automatically proxy writes through the server
- This allows concurrent dashboard viewing and CLI usage
- Server writes a `.pebbles/serve.port` file for CLI detection

To use: run `pb serve` in one terminal, use `pb` commands in another.

## Codex + Claude Code Notes

- Prefer `./pb` if the CLI is not on PATH.
- If Claude Code prompts for permissions, allow `Bash(pb:*)` in `.claude/settings.json`.

## Guardrails

- Track work only through Pebbles, not ad-hoc TODOs.
- Keep the lock accurate at all times.
- Always leave a relay when switching context.
