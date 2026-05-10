<h1 align="center">claudebook</h1>

<p align="center">
  <a href="./LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="#install"><img src="https://img.shields.io/badge/Claude%20Code-Plugin-D97757.svg" alt="Claude Code Plugin"></a>
</p>

Layered, AI-friendly project documentation for [Claude Code](https://docs.claude.com/en/docs/claude-code).

Two slash commands — `/claudebook:write` and `/claudebook:revise` — that generate and incrementally maintain a `CLAUDE.md` router plus topic docs, inventories, and pattern guides under `.claude/docs/`. Claude loads only what's relevant to the current task and reuses existing components instead of recreating them.

## The problem

`CLAUDE.md` is the file every Claude Code session loads on startup. It pays for itself when it's a thin router and turns into dead weight when it grows. The usual failure modes:

- **Bloated `CLAUDE.md`** — everything important gets stuffed into one file. Every session pays the token cost forever, even for tasks that don't need most of it.
- **Component recreation** — Claude has no inventory of what already exists, so it writes a new `Modal`, a new `useDebounce`, a new `formatDate` instead of reusing yours.
- **Convention drift** — naming, file organization, and project-specific rules get rediscovered (badly) every session.
- **Stale docs** — the docs that exist were written months ago, the codebase moved on, nobody updates them by hand.

`claudebook` fixes this with **three layers**: a thin always-loaded router (`CLAUDE.md`), task-triggered topic docs (`.claude/docs/*.md`), and per-symbol inventories (`.claude/docs/inventories/*.md`). `/claudebook:write` bootstraps the whole thing from your codebase. `/claudebook:revise` reads `git diff` since the last run and patches only the docs the diff touched.

## Commands at a glance

| Command | What it does |
| --- | --- |
| `/claudebook:write` | Bootstrap the full doc system. Detects stack, scans source, generates docs in dependency order, finalizes `CLAUDE.md` as the router. Run once per project. |
| `/claudebook:revise` | Incremental update. Reads the last-covered SHA from `CLAUDEBOOK.md`, runs `git diff`, classifies each change, and updates only the affected docs. Run after merging significant changes. |

Full behavior, edge cases, and usage examples are in [Commands in detail](#commands-in-detail) and [Usage](#usage) below.

## Requirements

- [Claude Code](https://docs.claude.com/en/docs/claude-code) installed.
- **For Option 1 (plugin install):** a version of Claude Code that supports the [plugin marketplace system](https://docs.claude.com/en/docs/claude-code/plugin-marketplaces). Type `/plugin` in any Claude Code session — if you see `marketplace` and `install` subcommands, you're good. If not, use Option 2 or 3.
- **For Options 2 and 3:** any version of Claude Code with custom slash command support.
- A git repository in the target project (so `/claudebook:revise` can diff against the last-covered commit). Non-git projects can run `/claudebook:write` but won't get incremental updates.

## Install

### Option 1 — As a Claude Code plugin (recommended)

In any Claude Code session, run these slash commands:

```
/plugin marketplace add YatharthLakhera/claudebook
/plugin install claudebook@claudebook
/reload-plugins
```

The repo is its own one-plugin marketplace, so `/plugin marketplace add` points directly at it. `/reload-plugins` applies the install — without it, the new commands won't appear in the slash menu.

**Verify it worked:**

Type `/` in your Claude Code prompt. You should see `claudebook:write` and `claudebook:revise` in the slash-command menu. If they don't show up, fully close and reopen your Claude Code session as a fallback — some older versions only refresh the command menu on session start.

### Option 2 — Manual copy

If you'd rather drop the commands directly into your config without going through the plugin system:

```bash
git clone https://github.com/YatharthLakhera/claudebook.git
mkdir -p ~/.claude/commands/claudebook
cp claudebook/commands/*.md ~/.claude/commands/claudebook/
```

The commands need access to the templates and rules under `lib/`. Either keep the cloned repo around and the commands will ask you to point at it on first run, or copy `lib/` next to the commands.

### Option 3 — Per-project install

Scope the commands to a single repo (so they only show up in that project):

```bash
mkdir -p .claude/commands/claudebook .claude/claudebook-lib
cp /path/to/claudebook/commands/*.md .claude/commands/claudebook/
cp -r /path/to/claudebook/lib/* .claude/claudebook-lib/
```

## Updating

For the plugin install (Option 1), pull the latest version with:

```
/plugin marketplace update claudebook
/reload-plugins
```

For manual copies (Options 2 and 3), `git pull` the repo and re-run the copy step.

---

## Commands in detail

| Command | What it does |
| --- | --- |
| `/claudebook:write` | Confirms project root, detects the stack from manifest files (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, etc.), scans the source tree, asks you for best-practices depth (Essentials / Standard / Comprehensive) and which pattern docs to include, generates docs in dependency order, finalizes `CLAUDE.md` as a thin router, and records the current `HEAD` SHA in `CLAUDEBOOK.md`. Skips pattern docs that don't apply (no forms in the project → no `forms.md`). |
| `/claudebook:revise` | Reads `Last commit covered` from `CLAUDEBOOK.md`, runs `git diff <sha> HEAD --name-status`, classifies each change against `routing-rules.md`, shows you a summary of what will be updated, and patches only the affected docs. Bumps the SHA only after all writes succeed. Refuses to silently overwrite docs without the `<!-- claudebook: generated ... -->` marker. |

Both commands generate **terse, scannable, factual** docs — no marketing prose, no emojis, no "summary" sections. The output is meant for an LLM to load quickly, not a human to read like a book.

## Usage

### First time on a project

```
/claudebook:write
```

The command will:

1. Confirm you're at the project root and the repo is a git repo.
2. Detect the stack and show you the classification table.
3. Scan the source tree (folder structure, file counts, presence of forms / modals / tables / state libraries).
4. Ask — in a single batched prompt — for stack confirmation, best-practices depth, which pattern docs to skip, and what to do with any pre-existing `CLAUDE.md` / `AGENTS.md`.
5. Generate `.claude/docs/` with project context (`overview.md`, `architecture.md`, `tech-stack.md`), conventions (`conventions.md`, `best-practices.md`), inventories (per exported symbol), and pattern docs (only the ones that apply).
6. Write a thin router `CLAUDE.md` (≤200 lines) with a task→doc table.
7. Write `CLAUDEBOOK.md` with the current `HEAD` SHA recorded as `Last commit covered`.

When it's done, **commit the new docs.** They're now part of the repo and version-controllable.

### Keeping docs current

After merging non-trivial changes (a new component family, a refactor, a dependency bump), run:

```
/claudebook:revise
```

The command will:

1. Read `Last commit covered` from `CLAUDEBOOK.md`.
2. Run `git diff <last-sha> HEAD --name-status` and `git log --oneline <last-sha>..HEAD`.
3. Classify each changed file against the routing rules:
    - `src/components/**` → `inventories/component-map.md`
    - `src/hooks/**` → `inventories/hook-map.md`
    - `src/utils/api.ts` → `patterns/api-integration.md`
    - `package.json` deps → `tech-stack.md` (and possibly `best-practices.md` on a major version bump)
    - …and so on.
4. Show you a summary of what will be updated, then proceed (auto-confirms for small inventory-only changesets).
5. Patch only the affected docs — never regenerate from scratch unless asked.
6. Bump `Last commit covered` to the current `HEAD` once all writes succeed.

If a doc lacks the `<!-- claudebook: generated ... -->` marker, the command treats it as user-authored and asks before changing anything.

### Day-to-day usage by Claude

Once the docs exist, you don't run anything — `CLAUDE.md` does the routing automatically:

- Building a new component? Claude reads `inventories/component-map.md` first, sees `Modal` already exists, reuses it.
- Wiring a new API endpoint? Claude reads `patterns/api-integration.md` and follows the existing interceptor / error-handling shape.
- Adding a form? Claude reads `patterns/forms.md` and uses the same form library and validation pattern.

That's the payoff. The docs do the work, sessions stay focused, and `CLAUDE.md` stays thin.

## What gets generated

```
<project-root>/
├── CLAUDE.md                       # Thin router, always loaded. Stack, critical rules, task→doc table.
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
        └── patterns/               # Task-triggered guides — only the ones that apply.
            ├── api-integration.md
            ├── modals.md
            ├── forms.md
            ├── tables.md
            ├── styling.md
            ├── state-management.md
            └── routing.md
```

Pattern docs that don't apply to your project are not generated. No forms? No `forms.md`. No tables? No `tables.md`.

### Inventory entry shape

Each exported symbol gets one entry, grouped by feature subfolder:

```markdown
### Modal
- Path: src/components/ui/Modal.tsx
- Kind: component
- Purpose: Accessible dialog with focus trap and escape-to-close.
- Signature: ({ open, onClose, title, children, size? }) => JSX
- Used by: ConfirmDialog, EditUserModal, DeleteConfirmation
```

That's the reuse contract. Before Claude writes a new component, it reads the relevant inventory.

## Design principles

1. **Three layers, three roles.** `CLAUDE.md` (always loaded, ~150 lines) → topic docs (task-triggered) → inventories (change-frequent). Bloat in `CLAUDE.md` costs tokens forever — keep it a router.
2. **Bifurcation by change rate × task trigger.** Stable docs (project context, conventions, patterns) are written once. Inventories change every PR — that's what `/claudebook:revise` mostly maintains.
3. **Specialize on write, not on every read.** Pattern docs ship as generic templates inside the plugin. When `/claudebook:write` runs, the **on-disk copy** is rewritten to reflect the actual conventions found in your codebase.
4. **Tech-agnostic.** Stack is detected from `package.json` / `pyproject.toml` / `Cargo.toml` / `go.mod` / etc. The best-practices doc is LLM-generated for the detected stack.
5. **Inventories are the reuse contract.** Per exported symbol: name, path, purpose, signature. Before creating anything new, Claude reads the relevant inventory.
6. **Diff-first, not regenerate-first.** `/claudebook:revise` patches only what changed. It refuses to silently overwrite docs you've hand-edited.

## Repo layout

```
claudebook/
├── README.md
├── LICENSE
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── commands/
│   ├── write.md                    # /claudebook:write
│   └── revise.md                   # /claudebook:revise
└── lib/
    ├── stack-detection.md          # how to detect the stack
    ├── routing-rules.md            # file-change → doc-to-update map
    ├── best-practices-spec.md      # the three depth options
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

## Uninstall

For the plugin install (Option 1):

```
/plugin uninstall claudebook@claudebook
/reload-plugins
```

`/reload-plugins` is required to clear the commands from the slash menu. To also forget the marketplace entirely (optional), run `/plugin marketplace remove claudebook` afterwards.

For manual copies (Options 2 and 3), delete the files you copied from `~/.claude/commands/claudebook/` (or `.claude/commands/claudebook/`) and any `lib/` content you copied alongside them.

The docs `claudebook` generated inside your project (`CLAUDE.md`, `.claude/docs/`) are yours — keep them, edit them, or delete them as you see fit.

## Contributing

PRs welcome. The two command files in `commands/` and the templates / rules under `lib/` are the entire surface area — keep them simple, terse, and scannable.

## License

[MIT](./LICENSE)
