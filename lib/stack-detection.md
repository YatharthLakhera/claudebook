# Stack Detection

How `/claudebook:write` and `/claudebook:revise` identify the project's tech stack. Read this before generating `tech-stack.md` or `best-practices.md`.

The goal is **enough specificity to write useful best-practices and pattern docs** — not exhaustive cataloguing. Stop once you can answer: language, framework, build tool, package manager, test runner, key libraries.

## Detection order

Check files in this order; the first match wins for primary classification, but always cross-check for secondary stacks (e.g. a Next.js app may have a Python ML script — note both).

### Manifests (primary signal)

| File | Implies |
|---|---|
| `package.json` | Node/JS/TS — inspect `dependencies` for framework |
| `pyproject.toml` / `requirements.txt` / `Pipfile` / `setup.py` | Python — inspect for Django/Flask/FastAPI |
| `Cargo.toml` | Rust |
| `go.mod` | Go |
| `pubspec.yaml` | Flutter / Dart |
| `Gemfile` | Ruby — check for Rails |
| `composer.json` | PHP — check for Laravel/Symfony |
| `pom.xml` / `build.gradle` / `build.gradle.kts` | Java/Kotlin — check for Spring |
| `*.csproj` / `*.sln` | .NET / C# |
| `mix.exs` | Elixir |
| `Package.swift` | Swift |
| `deno.json` / `deno.jsonc` | Deno |
| `bun.lockb` / `bun.lock` | Bun (Node-compatible) |
| `manifest.json` containing `manifest_version` field | Browser extension (Chrome / Edge / Firefox WebExtensions) — inspect `content_scripts`, `background`, `host_permissions`, `web_accessible_resources` |

Note: `manifest.json` *without* `manifest_version` is usually a Node web app or PWA — don't classify as an extension on filename alone. Confirm by checking the JSON contents.

### Framework signals (inside Node `package.json`)

| Dependency | Framework |
|---|---|
| `react` + `react-dom` (no `next`) | React (SPA) — check Vite vs CRA via `vite` / `react-scripts` |
| `next` | Next.js |
| `vue` (no `nuxt`) | Vue |
| `nuxt` | Nuxt |
| `svelte` (no `@sveltejs/kit`) | Svelte |
| `@sveltejs/kit` | SvelteKit |
| `@angular/core` | Angular |
| `solid-js` | Solid |
| `astro` | Astro |
| `remix` / `@remix-run/*` | Remix |
| `react-native` | React Native |
| `expo` | Expo (React Native) |
| `electron` | Electron |
| `express` / `fastify` / `koa` / `hapi` | Node backend frameworks |
| `@nestjs/core` | NestJS |
| `hono` | Hono |

### Framework signals (browser extensions)

Read `manifest.json` and classify by entry-point shape. Extensions commonly have **no JS framework, no package manager, and no build tool** — raw ES modules loaded directly by the browser is the default.

| Manifest field | Implies |
|---|---|
| `manifest_version: 3` | MV3 — service worker model, stricter CSP, `chrome.scripting` API |
| `manifest_version: 2` | MV2 — background pages, legacy permissions (deprecated by Chrome) |
| `content_scripts[]` | Files injected into web pages — DOM-side code, sandboxed from page JS |
| `background.service_worker` | MV3 service worker (no DOM, no persistent state) |
| `background.scripts` / `background.page` | MV2 background page (long-lived) |
| `action` / `browser_action` / `page_action` | Toolbar popup UI (HTML page) |
| `options_ui` / `options_page` | Extension options page |
| `web_accessible_resources` | Files reachable from page JS via `chrome.runtime.getURL(...)` |
| `host_permissions` (MV3) / `permissions` (MV2) | Origins the extension can read/inject into |
| `commands` | Keyboard shortcuts |

If a `package.json` is also present alongside `manifest.json`, the project uses a build pipeline (e.g. webpack/vite plugin for extensions, CRX bundler) — note both. If only `manifest.json` exists, write "no package manager / no build tool — raw ES modules" in the stack table.

### TypeScript

If `tsconfig.json` or `tsconfig.*.json` present → TS. Read `compilerOptions.strict`, `target`, `moduleResolution` to inform best-practices.

### Build tool / bundler (Node ecosystem)

`vite` / `webpack` / `rollup` / `esbuild` / `parcel` / `turbopack` / `rspack` / `tsup` — check both devDependencies and config files (`vite.config.*`, `webpack.config.*`, etc.).

### Package manager

Look for lockfile: `package-lock.json` (npm), `yarn.lock` (yarn), `pnpm-lock.yaml` (pnpm), `bun.lockb` / `bun.lock` (bun). Also check `packageManager` field in `package.json`.

### Test runner

| File / dep | Runner |
|---|---|
| `vitest` dep / `vitest.config.*` | Vitest |
| `jest` dep / `jest.config.*` | Jest |
| `@playwright/test` | Playwright |
| `cypress` | Cypress |
| `mocha` | Mocha |
| `pytest` in pyproject/requirements | Pytest |
| `unittest` imports only | Python stdlib |
| `cargo test` (default in Rust) | Rust built-in |
| `go test` (default in Go) | Go built-in |
| None of the above + zero `*.test.*` / `*.spec.*` / `__tests__/` files | **None configured** — render literally as `Test runner: none configured` in the classification table. Do not omit the row, do not write `Test runner: -`, and do not write a stub line like `npm test` in `tech-stack.md` commands. Note this in `conventions.md` known-offenders only if the project is sufficiently mature that missing tests is a real risk. |

### Linter / formatter

`eslint.config.*` / `.eslintrc.*`, `.prettierrc.*`, `biome.json`, `ruff.toml`, `.flake8`, `.rubocop.yml`, `rustfmt.toml`, `gofmt` (default).

### CSS / styling

| Signal | Approach |
|---|---|
| `tailwindcss` dep + `tailwind.config.*` | Tailwind |
| `styled-components` / `@emotion/*` | CSS-in-JS |
| `*.module.css` files | CSS Modules |
| `sass` / `*.scss` | Sass |
| `unocss` | UnoCSS |
| `@vanilla-extract/*` | vanilla-extract |
| Plain `*.css` only | Vanilla CSS |

### State management (Node frontends)

`redux` / `@reduxjs/toolkit`, `zustand`, `jotai`, `recoil`, `mobx`, `pinia`, `@tanstack/query`, `swr`, native `useContext` only.

### Routing (Node frontends)

`react-router-dom`, `@tanstack/router`, `next/router` (built-in), `vue-router`, file-based router (Next.js / SvelteKit / Nuxt).

### HTTP client

`axios`, `ky`, `node-fetch`, native `fetch`, `got`.

### Database / ORM (backends)

`prisma`, `drizzle-orm`, `typeorm`, `sequelize`, `mongoose`, `sqlalchemy`, `django.db`, `gorm`, `diesel`, `activerecord`.

## Classification output — canonical shape

There is **one canonical shape** for stack data: a markdown table with three columns (Layer, Choice, Version). Every doc that displays stack information uses this exact shape:

| Layer | Choice | Version |
|---|---|---|
| Language | TypeScript | 5.4 |
| Framework | React (SPA via Vite) | 18.3 |
| Build tool | Vite | 5.2 |
| Package manager | pnpm | 9.1 |
| Test runner | Vitest | 1.6 |
| Lint | ESLint | 9.x |
| Format | Prettier | 3.x |
| Styling | TailwindCSS | 3.4 |
| State | React Context | — |
| Routing | react-router-dom | 6.23 |
| HTTP | axios | 1.10 |
| ORM/DB | — | — |
| Analytics | mixpanel-browser | 2.73 |

### Standardized "not applicable" wording

When a row doesn't apply, render literally **`none configured`** in the Choice column and `—` (em-dash) in the Version column. Do not invent alternates like "N/A", "none", "not used", or blank cells. Examples:

| Layer | Choice | Version |
|---|---|---|
| Test runner | none configured | — |
| Build tool | none configured | — |
| Package manager | none configured | — |

### Skipping rows

Drop rows that genuinely don't make sense for the stack — e.g. a Rust CLI has no "Styling" or "State management" row; a browser extension has no "Routing" row. Skipping is fine; do not pad with `none configured` for irrelevant categories. Use `none configured` only when the *category applies* but the project hasn't picked one (e.g. a JS project without a test runner).

### Where this table is rendered

The same table is rendered verbatim in:
- `tech-stack.md` Snapshot section (primary)
- `CLAUDEBOOK.md` Stack-detected block
- `CLAUDE.md` Stack section (snapshot only — may be condensed to 4–6 most critical rows for context-budget reasons; full table stays in tech-stack.md)

Never render this data as a colon-prefixed text block, a bulleted list, or an inline sentence — table only.

## When detection is ambiguous

Multiple frameworks (e.g. monorepo with React frontend + FastAPI backend): **don't pick one** — generate a top-level `tech-stack.md` that lists workspaces, and run pattern/inventory generation **per workspace** if needed. Ask the user before fanning out.

If you find a manifest but can't confidently classify, ask the user — don't guess. A wrong best-practices doc is worse than no doc.

## What NOT to over-detect

Skip CI configs, deploy targets, env-var schemas, container files (`Dockerfile`, `docker-compose.yml`) for the purposes of `tech-stack.md`. Those belong in a separate operational doc only if the user explicitly wants one — not by default.
