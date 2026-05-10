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

## Classification output

After detection, summarize the stack in this exact shape (used by templates):

```
Language(s):       <e.g. TypeScript 5.x, Python 3.12>
Framework:         <e.g. React 18.3, Next.js 14, Django 5>
Build tool:        <e.g. Vite 5>
Package manager:   <e.g. pnpm 9>
Test runner:       <e.g. Vitest>
Lint/format:       <e.g. ESLint, Prettier>
Styling:           <e.g. TailwindCSS 3>
State management:  <e.g. React Context only>
Routing:           <e.g. react-router-dom 6>
HTTP client:       <e.g. axios 1>
Key libraries:     <comma-separated, only ones that materially affect patterns>
```

## When detection is ambiguous

Multiple frameworks (e.g. monorepo with React frontend + FastAPI backend): **don't pick one** — generate a top-level `tech-stack.md` that lists workspaces, and run pattern/inventory generation **per workspace** if needed. Ask the user before fanning out.

If you find a manifest but can't confidently classify, ask the user — don't guess. A wrong best-practices doc is worse than no doc.

## What NOT to over-detect

Skip CI configs, deploy targets, env-var schemas, container files (`Dockerfile`, `docker-compose.yml`) for the purposes of `tech-stack.md`. Those belong in a separate operational doc only if the user explicitly wants one — not by default.
