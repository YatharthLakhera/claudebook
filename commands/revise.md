---
description: Incrementally update claudebook docs based on git changes since the last write/revise. Reads CLAUDEBOOK.md for last-covered SHA, classifies changed files, updates only affected docs.
---

# /claudebook:revise

You are updating an existing claudebook documentation system. The goal is to bring `.claude/docs/` back in sync with the current state of the codebase by processing **only what changed since `Last commit covered`** — not regenerating from scratch.

Read these plugin files before doing anything project-side:
- `lib/routing-rules.md` — file→doc mapping (the core logic for this command)
- `lib/stack-detection.md` — to detect dep changes that require tech-stack/best-practices updates
- `lib/best-practices-spec.md` — to know when best-practices.md needs a refresh
- Templates under `lib/doc-templates/` — for shape reference if a doc is found missing

## Hard rules

1. **Diff-first, not regenerate-first.** Default action for any doc is *patch*, not *rewrite*. Only rewrite when the doc is materially out of date or the user asks.
2. **Never lose user edits.** If a doc lacks the `<!-- claudebook: generated ... -->` marker, treat it as user-authored and ask before changing.
3. **Confirm scope before writing.** Show the changeset summary first; wait for user OK unless ≤5 files all in inventory paths.
4. **Bump SHA atomically.** Only update `Last commit covered` (in `CLAUDEBOOK.md`) after all doc writes succeed. Partial success → don't bump.
5. **Update each touched doc's marker.** Every doc you patch must have its top-of-file marker `sha=<short-sha>` updated to the current `HEAD` short SHA, and the date refreshed to today. Untouched docs keep their old marker — that's how revise can later see which docs are stale relative to current `HEAD`.

## Workflow

### Step 1 — Pre-flight

1. Confirm cwd is the project root.
2. Read `<project>/.claude/docs/CLAUDEBOOK.md`. If missing, abort and recommend `/claudebook:write`.
3. Extract `Last commit covered: <sha>`. If missing or invalid, abort and ask the user — don't guess.
4. Extract the **Convention paths** table. These globs win over the generic `src/**` patterns in `lib/routing-rules.md` when classifying changed files. If the table is missing (older write), note it in the summary and fall back to the loosened generic patterns.
5. Run `git rev-parse HEAD` to get current SHA. If equal to last-covered SHA, report "Already up to date" and stop.
6. Run `git log --oneline <last-sha>..HEAD | wc -l` to size the change. If >200 commits, warn the user — they may want a fresh `/claudebook:write` instead.

### Step 2 — Collect the diff

```
git diff <last-sha> HEAD --name-status
git log --oneline <last-sha>..HEAD
```

Parse `--name-status` output into:
- Added (`A`)
- Modified (`M`)
- Deleted (`D`)
- Renamed (`R`) — extract old + new path

### Step 3 — Classify changes

For each changed file, apply `lib/routing-rules.md` rules. Build a map:

```
{
  "inventories/component-map.md": [list of changed paths],
  "inventories/utility-map.md":   [...],
  "patterns/api-integration.md":  [...],
  "tech-stack.md":                [...],
  ...
  "_unclassified":                [...],
}
```

Drop files that match the ignore list in routing-rules.

### Step 4 — Special-case: dep / config changes

Inspect these files specifically — they have outsized impact:
- `package.json` / `pyproject.toml` / `Cargo.toml` etc. — diff the deps. New framework? New ORM? Major version bump? → flag `tech-stack.md` and possibly `best-practices.md`.
- `tsconfig.json` strictness flag flipped → flag `conventions.md`.
- `tailwind.config.*` theme changes → flag `patterns/styling.md`.
- `eslint.config.*` rule changes → flag `conventions.md`.

### Step 5 — Show summary, wait for confirmation

Use the format from `lib/routing-rules.md`. Print:

```
claudebook:revise

Range:    <last-sha-short>..<HEAD-short>  (<N> commits)
Changed:  <N> files  (<A> added, <M> modified, <D> deleted, <R> renamed)

Will update:
  inventories/component-map.md  (+3 components, -1, ~2 modified)
  inventories/utility-map.md    (+2 utils)
  patterns/api-integration.md   (api.ts modified — patterns may have shifted)
  tech-stack.md                 (axios bumped 1.x → 2.x)

Unclassified (will skip — review manually if material):
  scripts/migrate-2026.ts

Proceed?
```

If the changeset is small (≤5 files, all inventories), skip the prompt and proceed.

### Step 6 — Apply updates

For each doc in the update map, read the current file and patch:

#### Inventories

- **Added file** → add entry per exported symbol, in the right feature group.
- **Deleted file** → remove all entries with that path.
- **Renamed file** → update `Path:` field; preserve other fields if export shape unchanged.
- **Modified file** → re-read exports; update entries whose signature/props changed; add new exports; remove removed ones.

If you can't determine purpose for a new symbol from the file alone, mark `Purpose: TBD — read <path>:<line>` rather than blocking.

#### Pattern docs

- Read the doc.
- Read the changed source file(s) that triggered the update.
- Determine if the **convention** changed (vs. just adding another instance of the existing convention). If just another instance, no update needed.
- If convention changed, append a "Recent shift" section noting the new pattern, OR rewrite the affected section with a one-line "previously, X" note.
- For `patterns/api-integration.md` specifically, if `src/utils/api.ts` (or equivalent) was modified, re-read it end-to-end and update interceptor/error/auth descriptions accordingly.

#### Project-level docs

- `tech-stack.md` — diff package manifests, update version pins, add/remove libraries. Keep the structure; just refresh values.
- `architecture.md` — only update if a top-level folder was added/removed.
- `conventions.md` — only update if lint config / tsconfig strictness changed, or if known-offenders need refresh (re-scan the largest 5 files).
- `best-practices.md` — refresh only on major framework version bump or new framework added. Otherwise leave alone.

#### CLAUDE.md

- Refresh "Stack" snapshot if `tech-stack.md` was updated.
- Refresh task→doc routing table if a pattern doc was added or removed.
- Don't touch the rest unless the user requests.

### Step 7 — Update CLAUDEBOOK.md

Set:
- `Last commit covered: <current HEAD SHA>`
- `Last revise: YYYY-MM-DD`
- Update doc index: line counts for any modified docs.
- Update `CLAUDE.md`'s footer: `Last commit covered: <current HEAD SHA>` (the router file mirrors this for human readability — keep in sync).
- For every doc you touched in step 6, update its top-of-file marker comment so `sha=<short-sha>` matches the new `HEAD` short SHA and the date is today. Leave untouched docs' markers alone.

### Step 8 — Final summary

Print:
- Docs updated: count + paths
- Symbols added / removed / modified across inventories
- New SHA recorded
- Anything skipped that the user should look at manually (the unclassified list)

## Failure handling

- If `git diff` fails, abort and surface the error — likely git state issue (rebase in progress, etc.).
- If a doc to be patched has no marker comment, ask the user before modifying it. They may have hand-edited it.
- If updating a doc would result in deleting >50% of its content, stop and ask — large deletions usually mean a misclassification.
- If the unclassified list is long (>10), surface it prominently — it usually means routing-rules needs to be extended for this project's structure.

## What NOT to do

- Don't regenerate docs from scratch unless explicitly asked.
- Don't update docs for files that match the ignore list (lockfiles, build artifacts, tests).
- Don't bump `Last commit covered` if any doc write failed.
- Don't add changelogs or "what changed" sections to docs — the docs describe current state, not history.
- Don't touch `overview.md` or pre-existing user-authored content unless asked.
