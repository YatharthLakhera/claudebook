---
description: Bootstrap the full claudebook documentation system for a new project — detects stack, scans source, prompts for depth, generates docs, finalizes CLAUDE.md as router.
---

# /claudebook:write

You are bootstrapping the claudebook documentation system in the user's current project. The goal is a layered, AI-friendly doc set so future Claude sessions load only what's relevant to the task and reuse existing components instead of recreating them.

Read these plugin files before doing anything project-side:
- `lib/stack-detection.md` — how to identify the stack
- `lib/routing-rules.md` — file→doc mapping (used later by revise; informs structure now)
- `lib/best-practices-spec.md` — the three depth options
- All templates under `lib/doc-templates/` — generic scaffolds you will specialize

Resolve those plugin file paths from your plugin install location. If you cannot find them, ask the user where the plugin lives.

## Hard rules

1. **Never overwrite existing user content silently.** If `CLAUDE.md`, `AGENTS.md`, `.claude/docs/` already exist, stop and route to `/claudebook:revise` — unless the user explicitly says "regenerate from scratch."
2. **Templates are scaffolds, not final files.** The on-disk copy in the project must be **specialized to observed conventions** (read the actual code), not pasted verbatim.
3. **Inventories are per exported symbol**, grouped by file. One entry = name, path, signature/props, purpose, callers if obvious.
4. **Skip pattern docs that don't apply.** No forms in the project → no `forms.md`. The skill produces only what the codebase needs.
5. **Mark generated, ask when unsure.** Every generated doc gets a `<!-- claudebook: generated YYYY-MM-DD, depth=<chosen>, sha=<short-sha> -->` HTML comment at the top so revise can identify them and judge freshness. The `sha` is the 7-char short form of `git rev-parse HEAD` at write time. Future revise runs update this marker on every doc they touch — see `commands/revise.md`.
6. **No emojis.** No marketing prose. Terse, scannable, dense with paths and names. **This applies to migrated content too** — when promoting existing `AGENTS.md` / `CLAUDE.md` content into the new docs, strip emojis from headings, bullets, and inline text. Do not preserve them verbatim.

## Workflow

### Step 1 — Pre-flight

1. Confirm cwd is the project root (look for the manifest file — `package.json`, `pyproject.toml`, etc.).
2. Run `git rev-parse --show-toplevel` and `git rev-parse HEAD`. If not a git repo, warn the user — `/claudebook:revise` won't be able to track changes. Ask whether to proceed anyway.
3. Check for `CLAUDE.md`, `AGENTS.md`, `.claude/docs/`. If any exist:
   - If they look claudebook-generated (have the marker comment), suggest `/claudebook:revise` and stop.
   - If user-authored, preserve their content as **input** — extract any project-specific rules and feed them into the new `conventions.md`. Confirm with the user before overwriting.
4. **Scan the repo root for other user-authored markdown.** List every top-level `*.md` file other than the noise ones (`README.md`, `CHANGELOG.md`, `CHANGELOG`, `LICENSE.md`, `LICENSE`, `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `SECURITY.md`, the two above). Examples that ARE relevant: `ANALYTICS_SETUP.md`, `DEPLOY.md`, `ARCHITECTURE.md`, `NOTES.md`, `TODO.md`. For each, surface to the user with the same options as `AGENTS.md`: "Migrate content into the appropriate generated doc" (recommended — usually `architecture.md`, `conventions.md`, or a pattern doc), "Leave in place" (default for things like ARCHITECTURE.md if user wants to keep curated prose), or "Discard". Do NOT auto-delete user files. After migration, leave a one-line stub pointing at the new location only if the user picks "migrate".
5. Note the absolute path of the project root. All subsequent writes go under it.

### Step 2 — Detect stack

Follow `lib/stack-detection.md`. Output the classification table to the user.

### Step 3 — Scan source tree

Build a structural picture, not a full read. For each:
- Top-level folders under `src/` **or whatever the project actually uses** (`libs/`, `app/`, `apis/`, root, etc. — do not assume `src/`)
- Counts: components, utils, hooks, services, routes, types
- Presence checks: any `*Modal*`/`*Popup*`/`*Dialog*`? any forms (`react-hook-form`/`formik`/native form components)? any tables? any contexts/stores?
- Existing `tailwind.config.*` / theme tokens
- Largest 5 files (paths + line counts) — these often violate convention rules and are worth flagging in `conventions.md` as known offenders

**Capture convention paths.** As you scan, record the actual glob(s) for each kind of code in this project. These get written to `CLAUDEBOOK.md` "Convention paths" so `/claudebook:revise` can route `git diff` paths correctly without assuming `src/**`. Examples:

- `src/`-style React: `components → src/components/**/*.{tsx,jsx}`, `utils → src/utils/**/*.{ts,js}`, etc.
- Browser extension: `services → apis/**/*.js`, `utilities → libs/**/*.js`, `content scripts → content/**/*.js`.
- Python: `services → app/services/**/*.py`, `routes → app/routers/**/*.py`.

If a kind has no directory in this project, omit it (do not invent a path).

Keep all of this in working memory; do not write anything yet.

### Step 4 — Decide which docs to generate

Inventories — always generate ones that have content:

| Doc | Generate if |
|---|---|
| `component-map.md` | ≥1 component file found |
| `utility-map.md` | ≥1 file in `utils/` / `lib/` / equivalent |
| `hook-map.md` | ≥1 file in `hooks/` (React) or `composables/` (Vue) |
| `service-map.md` | ≥1 file in `services/` / `api/` |
| `route-map.md` | route directory exists |
| `type-map.md` | ≥1 file in `types/` or shared `*.d.ts` |

Pattern docs — generate only if the codebase actually uses the pattern:

| Doc | Generate if |
|---|---|
| `api-integration.md` | HTTP client present (axios/fetch wrapper/etc.) |
| `modals.md` | ≥1 modal/popup/dialog component |
| `forms.md` | ≥1 non-trivial form OR a form library dep |
| `tables.md` | ≥1 table component |
| `styling.md` | Always |
| `state-management.md` | Always |
| `routing.md` | Routing solution present |
| `browser-extension.md` | `manifest.json` with `manifest_version` field detected (MV2/MV3 extension) |
| `integrations.md` | ≥2 third-party SDKs init'd in the entry file (analytics, error tracking, session replay, feature flags, email, etc.) — grep the entry file for `init(`, `Sentry.init`, `mixpanel.init`, `clarity(`, `posthog.init`, `emailjs.init`, `LDClient.initialize`, etc. |

Project docs — always: `overview.md`, `architecture.md`, `tech-stack.md`, `conventions.md`, `best-practices.md`.

### Step 5 — Confirm with user (AskUserQuestion)

Ask in **one batched** AskUserQuestion call (multiple questions in a single tool call):

1. **Stack confirmation** — show the detected stack table; options: "Looks right" / "Adjust" (if adjust, follow up).
2. **Best-practices depth** — Essentials (recommended) / Standard / Comprehensive. Use the descriptions from `lib/best-practices-spec.md`.
3. **Pattern docs to skip** — show the auto-included list with checkboxes; user can deselect any (multiSelect). **An empty selection means "skip none"** (i.e. include every auto-detected pattern doc), NOT "skip all". This applies whether the user (a) selected zero options, (b) didn't see/answer the question (e.g. answered only some questions in the batched call), or (c) answered with a no-op response. The default is always "include every detected pattern." If the user genuinely wants to skip everything, they must say so in free-text follow-up.
4. **Existing CLAUDE.md / AGENTS.md** — only ask if step 1 found user-authored versions. Options: "Migrate content into new docs" (recommended) / "Discard" / "Abort and review manually".

Wait for answers before proceeding.

### Step 6 — Generate docs in dependency order

**File-location rules** (important — do not get this wrong):

| File | Goes here |
|---|---|
| `CLAUDE.md` (the router) | `<project>/CLAUDE.md` — at the project ROOT. Claude Code expects it there. |
| `AGENTS.md` (the stub, if migrated) | `<project>/AGENTS.md` — at the project ROOT. |
| Everything else (`overview.md`, `architecture.md`, `tech-stack.md`, `conventions.md`, `best-practices.md`, `CLAUDEBOOK.md`, `inventories/*.md`, `patterns/*.md`) | `<project>/.claude/docs/<filename>` |

If you put `CLAUDE.md` under `.claude/docs/`, Claude Code will not find it on session startup and the whole router is dead. Likewise, `CLAUDEBOOK.md` at project root would be confusing — it's a meta file, kept with the docs it tracks.

Use `Write`, not `Edit` (these are new files). The tone for every doc: terse, factual, scannable. Bullet points and tables over prose.

**Always include the marker comment at the top:**
```html
<!-- claudebook: generated YYYY-MM-DD, depth=<essentials|standard|comprehensive>, sha=<short-sha> -->
```

The `sha` is `git rev-parse --short HEAD` at write time. If the project is not a git repo, omit the `, sha=...` segment (the marker remains valid).

#### 6a. Project context

- **`overview.md`** — Project purpose (1 paragraph from README + manifest metadata + user input if clearly missing). What it does, who uses it, key flows. No marketing. If the README is empty (≤30 chars), surface this and ask the user for a 2-3 sentence summary.
- **`architecture.md`** — Top-level module map: `src/<folder> → role`. Data flow at a high level (e.g. "Auth context → axios interceptor → backend"). State management approach. Where business logic lives vs UI vs networking. ~50 lines.
- **`tech-stack.md`** — Use the classification table from Step 2. Add: notable version pins, why a choice constrains code (e.g. "axios is required for shared interceptors — do not use fetch directly"). ~40 lines.

#### 6b. Conventions

Extract from: existing `AGENTS.md` / `CLAUDE.md` content (if any), `eslint.config.*`, `tsconfig.json`, observed patterns in code. Sections:
- **File organization** (where things go)
- **Naming** (case rules per file/symbol type)
- **Critical rules** (must-follow, with consequences if broken)
- **Known offenders** (files exceeding self-imposed rules — flag for refactor without breaking session work)

#### 6c. Pattern docs (specialized)

For each pattern doc to generate:
1. Read the relevant template under `lib/doc-templates/patterns/`.
2. Read 2–3 representative examples from the project's source.
3. Specialize: rewrite the template so the examples in the doc are from this project, the rules reflect what the code actually does, and the "common pitfalls" section is informed by what you saw.

Each pattern doc should be ≤100 lines. If a pattern is huge, link to the most exemplary file as the canonical reference rather than restating it.

#### 6d. Inventories

For each inventory to generate:
1. List source files in scope (per the path table above).
2. For each file, identify exported symbols. Use `grep` / file reads judiciously — full reads only when the export shape isn't obvious.
3. **Build a reverse-import index once, before populating any "Used by" fields.** This avoids repeating the same grep per symbol. Run something like:

   ```sh
   git grep -nE "from ['\"][^'\"]*<symbol-name>['\"]|import.*<symbol-name>" -- 'src/**/*.{ts,tsx,js,jsx}'
   ```

   Or for the whole inventory in one pass:

   ```sh
   git grep -nE "^import|^const.*= require\(" -- 'src/**/*.{ts,tsx,js,jsx}'
   ```

   Cache the results in working memory keyed by imported-symbol → list of importing files. Then look up each symbol's callers from the cache instead of re-grepping.

4. For each exported symbol, write one entry:

```markdown
### <SymbolName>
- Path: <relative path>
- Kind: <component | hook | util | service | type | route>
- Purpose: <one line>
- Signature: <props/args/return — abbreviated>
- Used by: <2–3 callers from the reverse-import index, OR omit this field entirely>
```

**`Used by` is optional.** If the reverse-import index has no hits for a symbol (e.g. unused export, dynamic import, JSX usage that doesn't show in import lines), **omit the field entirely** — do not write `Used by: —`. The dash is noise; absence is information ("we couldn't quickly identify callers"). The reader can grep when they need to. Aim for `Used by` populated when you have it, omitted when you don't, never `—`.

Group entries by feature subfolder. If a project has 100+ symbols of one kind, split into per-feature inventory files (`component-map-<feature>.md`) and link from the top-level map.

**Do not invent.** If you can't determine purpose from the file, write `Purpose: TBD — read <path>:<line>` and move on. The user can fill in or we'll catch it during revise.

#### 6e. Best practices

Follow `lib/best-practices-spec.md` strictly for the chosen depth. Single combined file. Per-stack sections if multiple stacks detected.

#### 6f. CLAUDE.md (router) — last

Use `lib/doc-templates/CLAUDE.md.template`. Fill in:
- Project name + one-line description
- Stack snapshot (from Step 2)
- Commands (extract from `package.json` scripts / equivalent)
- Critical rules (5–10 from `conventions.md`)
- Task → doc routing table (only entries for docs that were generated)
- "Always before writing code" reminder pointing to inventories

Keep CLAUDE.md ≤200 lines. If it's longer, the routing table is too verbose — collapse rare entries.

#### 6g. CLAUDEBOOK.md (meta) — write LAST

Write CLAUDEBOOK.md only after every other doc has been written. Reasons: (a) the doc index needs accurate line counts, (b) the Notes section may need to record decisions surfaced during generation.

Use `lib/doc-templates/CLAUDEBOOK.md.template`. Record:
- Skill version (read from `.claude-plugin/plugin.json`)
- Date of write
- Stack detected
- Depth chosen
- Last commit covered: current `HEAD` SHA
- **Doc index with accurate line counts.** Run `wc -l` on each generated file rather than estimating:

  ```sh
  wc -l <project>/CLAUDE.md <project>/.claude/docs/**/*.md
  ```

  Use the actual integer from `wc -l` in the doc index table. Do not estimate from memory — estimates are routinely off by 5–20 lines and the table is meant to be authoritative.
- **Convention paths table** — populate from Step 3. One row per kind of code with the actual glob(s) used in this project. This is what `/claudebook:revise` reads to route `git diff` paths to docs without assuming `src/**`.

### Step 7 — AGENTS.md

If the project had an `AGENTS.md`, replace its contents with the canonical stub at `lib/doc-templates/AGENTS.md.template`. The stub is exactly:

```markdown
# AGENTS

See `CLAUDE.md`.
```

Strip emojis and any other formatting from the original — the stub is the entire new content. Any project-specific rules from the original AGENTS.md should already be migrated into `conventions.md` per Step 1.

If the project did not have an `AGENTS.md`, do not create one — the convention is CLAUDE.md is canonical.

### Step 8 — Final summary

Print to the user:
- Files written (count + paths)
- Stack detected
- Pattern docs included / skipped (with reasons)
- Total inventory entries (per kind)
- Last commit SHA recorded
- One sentence on next steps: "Run `/claudebook:revise` after merging significant changes."

Mark all tasks completed.

## Failure handling

- If a tool fails or output looks wrong, stop and report — do not write partial docs that look authoritative.
- If you can't classify a file confidently for an inventory, mark `Purpose: TBD` and continue. Don't block the whole run on one file.
- If the user denies a tool call, ask why and adjust — don't retry the identical call.

## What NOT to do

- Don't generate docs for sections that don't apply (e.g. `forms.md` when there are no forms).
- Don't paste template content verbatim into project docs.
- Don't invent symbols, props, or callers.
- Don't add emojis or decorative formatting.
- Don't write a "summary" or "conclusion" section in any generated doc.
- Don't add comments explaining what a doc is for — the doc itself should be self-evident.
