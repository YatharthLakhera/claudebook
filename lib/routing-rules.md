# Routing Rules

Maps **changed file paths** (from `git diff`) to **docs that need updating**. Used by `/claudebook:revise`.

The rules below are heuristics. When a file matches multiple rules, update all matched docs. When a file matches none, log it under "Unclassified" in the revise summary so the user can decide whether a new pattern doc is warranted.

## How to apply

1. From `git diff <last-sha> HEAD --name-only`, classify each path.
2. Build a set of docs to update (deduped).
3. For each doc, read its current contents and apply only the deltas implied by the changes — do not regenerate from scratch unless the doc is materially out of date.
4. After updating, bump `Last commit covered` in `CLAUDEBOOK.md` to current `HEAD`.

## Path → Doc rules

### Inventories (most common)

| Path pattern | Update |
|---|---|
| `src/components/**/*.{tsx,jsx,vue,svelte}` (new/deleted/renamed) | `inventories/component-map.md` |
| `src/components/**/*.{tsx,jsx}` (modified — props or exports changed) | `inventories/component-map.md` |
| `src/utils/**/*.{ts,js}`, `src/lib/**/*.{ts,js}`, `lib/**/*.py` | `inventories/utility-map.md` |
| `src/hooks/**/*.{ts,tsx}` (React) | `inventories/hook-map.md` |
| `src/composables/**/*.{ts,js}` (Vue) | `inventories/hook-map.md` |
| `src/services/**/*.{ts,js,py}`, `src/api/**` | `inventories/service-map.md` (and `patterns/api-integration.md` if the service makes raw HTTP calls — see note below) |
| `src/pages/**`, `src/routes/**`, `src/app/**` (Next.js app router), `pages/**` | `inventories/route-map.md` |
| `src/types/**/*.ts`, `*.d.ts` | `inventories/type-map.md` |

For non-Node stacks, substitute the conventional locations (e.g. Python: `myapp/views.py` → routes; `myapp/models.py` → types/models map).

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
