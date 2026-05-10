# claudebook

A Claude Code plugin that bootstraps and maintains a layered, AI-friendly documentation system inside a project so Claude (or any LLM agent) can:

- load **only** the docs relevant to the current task (token-efficient)
- **reuse** existing components and utilities instead of recreating them
- follow project conventions consistently across sessions

## What it builds in your project

```
<project-root>/
├── CLAUDE.md                       # Router — always loaded. Stack, critical rules, task→doc table.
├── AGENTS.md                       # One-line stub: "See CLAUDE.md".
└── .claude/
    └── docs/
        ├── CLAUDEBOOK.md           # Meta: stack, last commit covered, doc index.
        ├── overview.md             # Project purpose, business context.
        ├── architecture.md         # High-level architecture, data flow.
        ├── tech-stack.md           # Versions, choices, gotchas.
        ├── conventions.md          # Naming, file org, must-follow rules.
        ├── best-practices.md       # Stack-specific, LLM-generated at chosen depth.
        ├── inventories/            # Per-symbol maps so Claude reuses existing code.
        │   ├── component-map.md
        │   ├── utility-map.md
        │   ├── hook-map.md
        │   ├── service-map.md
        │   ├── route-map.md
        │   └── type-map.md
        └── patterns/               # Task-triggered guides, only the ones that apply.
            ├── api-integration.md
            ├── modals.md
            ├── forms.md
            ├── tables.md
            ├── styling.md
            ├── state-management.md
            └── routing.md
```

## Design principles

1. **Three layers.** CLAUDE.md (always loaded, ~150 lines) → topic docs (task-triggered) → inventories (change-frequent). Bloat in CLAUDE.md costs tokens forever — keep it a router.
2. **Bifurcation by change rate × task trigger.** Stable docs (project context, conventions, patterns) are written once. Inventories change every PR — that's what `/claudebook:revise` mostly maintains.
3. **Specialize on write, not on every read.** Pattern docs ship as generic templates inside the plugin. When `/claudebook:write` runs, the **on-disk copy** is rewritten to reflect the actual conventions found in the codebase.
4. **Tech-agnostic.** Stack is detected from package.json / pyproject.toml / Cargo.toml / go.mod / etc. Best-practices doc is LLM-generated for the detected stack.
5. **Inventories are the reuse contract.** Per exported symbol: name, path, purpose, signature. Before creating anything new, Claude reads the relevant inventory.

## Commands

### `/claudebook:write`

Bootstrap the full documentation system for a new project. Detects the stack, scans the source tree, asks the user for best-practices depth, generates docs in dependency order, finalizes CLAUDE.md as the router, and records the current git HEAD in CLAUDEBOOK.md.

Run once per project.

### `/claudebook:revise`

Incremental update. Reads `Last commit covered` from CLAUDEBOOK.md, runs `git diff <sha> HEAD`, classifies each change against `lib/routing-rules.md`, and updates only the affected docs. Bumps the SHA when done.

Manual trigger only. Run after merging significant changes.

## Repo layout

```
claudebook/
├── README.md
├── .claude-plugin/plugin.json
├── commands/
│   ├── write.md
│   └── revise.md
└── lib/
    ├── stack-detection.md          # how to detect the stack
    ├── routing-rules.md            # file-change → doc-to-update map
    ├── best-practices-spec.md      # the 3 depth options
    └── doc-templates/              # generic templates (specialized at write time)
        ├── CLAUDE.md.template
        ├── CLAUDEBOOK.md.template
        ├── overview.md.template
        ├── architecture.md.template
        ├── tech-stack.md.template
        ├── conventions.md.template
        ├── inventories/*.template
        └── patterns/*.template
```
