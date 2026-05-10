# Routing Rules

Maps **changed file paths** (from `git diff`) to **docs that need updating**. Used by `/claudebook:revise`.

The rules below are heuristics. When a file matches multiple rules, update all matched docs. When a file matches none, log it under "Unclassified" in the revise summary so the user can decide whether a new pattern doc is warranted.

## Project-specific paths come first

Before applying the generic table below, **read `CLAUDEBOOK.md`'s "Convention paths" section**. Those globs were captured at write time by scanning the actual project, and they win over the `src/**` defaults. Examples of projects where the defaults don't apply:

- Browser extensions: code at root + `libs/` + `apis/` + `content/` (no `src/`).
- Python projects: `app/`, `myapp/`, or package-named root.
- Monorepos: `packages/<pkg>/src/**` per workspace.
- Legacy projects: `js/`, `scripts/`, `assets/js/`.

If `CLAUDEBOOK.md` has no Convention paths table (older write), fall back to the generic table below AND the loosened patterns. Surface this as a note in the revise summary so the user can re-run `/claudebook:write` (or hand-edit) to populate it.

## How to apply

1. Read Convention paths from `CLAUDEBOOK.md` if present.
2. From `git diff <last-sha> HEAD --name-only`, classify each path against (a) Convention paths first, (b) the loosened generic table second.
3. Build a set of docs to update (deduped).
4. For each doc, read its current contents and apply only the deltas implied by the changes — do not regenerate from scratch unless the doc is materially out of date.
5. After updating, bump `Last commit covered` in `CLAUDEBOOK.md` to current `HEAD`.

## Path → Doc rules

### Inventories (most common)

The patterns below use `(src|libs|lib|app)` as a placeholder for "wherever this project keeps its code" — match against any of those alternates. For Convention-paths-aware matching, see the section above.

| Path pattern | Update |
|---|---|
| `(src\|libs\|lib\|app)/components/**/*.{tsx,jsx,vue,svelte}` (new/deleted/renamed) | `inventories/component-map.md` |
| `(src\|libs\|lib\|app)/components/**/*.{tsx,jsx}` (modified — props or exports changed) | `inventories/component-map.md` |
| `(src\|libs\|lib\|app)/utils/**/*.{ts,js}`, `(src\|libs\|lib\|app)/lib/**/*.{ts,js}`, `lib/**/*.py`, root `*.js` matching `*util*` / `*helper*` | `inventories/utility-map.md` |
| `(src\|libs\|lib\|app)/hooks/**/*.{ts,tsx}` (React) | `inventories/hook-map.md` |
| `(src\|libs\|lib\|app)/composables/**/*.{ts,js}` (Vue) | `inventories/hook-map.md` |
| `(src\|libs\|lib\|app)/services/**/*.{ts,js,py}`, `(src\|libs\|lib\|app)/api/**`, `apis/**` | `inventories/service-map.md` (and `patterns/api-integration.md` if the service makes raw HTTP calls — see note below) |
| `(src\|libs\|lib\|app)/pages/**`, `(src\|libs\|lib\|app)/routes/**`, `(src\|libs\|lib\|app)/app/**` (Next.js app router), `pages/**` | `inventories/route-map.md` |
| `(src\|libs\|lib\|app)/types/**/*.ts`, `*.d.ts` | `inventories/type-map.md` |
| Browser extension: `content_scripts` files per `manifest.json`, `background.{js,ts}`, `popup/**`, `options/**` | `inventories/component-map.md` (entry points) AND `patterns/browser-extension.md` if convention shifted |

For non-Node stacks, substitute the conventional locations (e.g. Python: `myapp/views.py` → routes; `myapp/models.py` → types/models map). For browser extensions, treat each `manifest.json` entry point (background, content scripts, popup, options) as an inventory entry — the manifest itself is the source of truth, not folder layout.

**HTTP-client convention check for services:** When a `src/services/**` file is added or modified, scan it for raw HTTP calls (`fetch(`, `axios(` direct construction, `XMLHttpRequest`, `ky(` etc.) that bypass the project's centralized client (e.g. `src/utils/api.ts`). If any are found, also flag `patterns/api-integration.md` for review — this is a **convention violation**, not just an inventory entry, and the pattern doc may need a "Recent shift" note or the offending file flagged in `conventions.md` known-offenders.

### Pattern docs (less frequent — only when conventions actually shift)

| Trigger | Update |
|---|---|
| `src/utils/api.{ts,js}` modified, or new HTTP client added in `package.json` | `patterns/api-integration.md` |
| New modal component added under `src/components/**` matching `*Modal.*` / `*Popup.*` / `*Dialog.*` | `patterns/modals.md` |
| Form component added/changed using `react-hook-form` / `formik` / native | `patterns/forms.md` |
| Table component added/changed | `patterns/tables.md` |
| `tailwind.config.*` modified, or theme tokens / CSS variables changed | `patterns/styling.md` |
| `src/contexts/**` or store files changed | `patterns/state-management.md` |
| Route file added/removed | `patterns/routing.md` AND `inventories/route-map.md` |
| `manifest.json` modified (browser extension) — permissions, content_scripts, web_accessible_resources, background changed | `patterns/browser-extension.md` AND `tech-stack.md` if scope materially shifted |

Pattern doc updates should be **delta-only** — append new conventions or correct stale claims. Do not rewrite the whole doc unless the user requests it.

### Project-level docs (rare)

| Trigger | Update |
|---|---|
| `package.json` / `pyproject.toml` / `Cargo.toml` deps changed | `tech-stack.md` |
| Major dep added (framework, ORM, state lib) | `tech-stack.md` + possibly `best-practices.md` |
| `tsconfig.json` strictness changed | `conventions.md` + `best-practices.md` |
| `eslint.config.*` / lint rules changed | `conventions.md` |
| Top-level folder added/removed under `src/` | `architecture.md` |
| README significantly rewritten | `overview.md` (cross-check) |
| `CLAUDE.md` manually edited by user | flag — do not overwrite, integrate carefully |

### Files to ignore

| Path | Why |
|---|---|
| `node_modules/**`, `dist/**`, `build/**`, `.next/**`, `.nuxt/**`, `target/**`, `__pycache__/**` | Build artifacts |
| `*.lock`, `*.lockb`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml` | Lockfile churn — only check if `package.json` itself changed |
| `*.test.{ts,tsx,js,jsx,py}`, `*.spec.*`, `__tests__/**` | Tests don't change conventions |
| `*.config.{js,ts,cjs,mjs}` (vite, postcss, tailwind, jest, vitest, etc.) | Build/tool configs — only relevant when adding/removing the tool itself; tailwind theme changes are handled separately |
| `postcss.config.*`, `babel.config.*`, `.eslintrc.*`, `prettier.config.*` | Tool configs — handled by the project-level rules above only when they imply convention shifts |
| `amplify.yml`, `vercel.json`, `netlify.toml`, `*.github/workflows/*.yml`, `Dockerfile`, `docker-compose.yml` | Deploy / CI / container — not code conventions |
| `*.md` under `.claude/docs/` | These are our outputs — don't double-count |
| Image/binary assets | Not code |

## Conflict resolution

If a single change implies updating both a pattern doc *and* an inventory, update the inventory first (factual), then the pattern doc (interpretive). Pattern doc updates may need user input — surface a one-line summary and ask before rewriting prose.

## Output: revise summary

After classification, present a summary in this shape before doing any writes:

```
Files changed since <sha>: <N>
  Components: <count>     → component-map.md
  Utilities:  <count>     → utility-map.md
  Hooks:      <count>     → hook-map.md
  Services:   <count>     → service-map.md
  Routes:     <count>     → route-map.md
  Types:      <count>     → type-map.md
  Pattern shifts:         → <list of pattern docs>
  Project-level:          → <list>
  Unclassified:           → <list of paths — ask user>

Will update: <doc list>
Proceed?
```

Wait for user confirmation before writing. Skip the prompt only if the changeset is small (≤5 files, all in inventory paths).
