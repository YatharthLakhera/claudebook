# Best-Practices Spec

Defines the three depth options offered to the user during `/claudebook:write`, and what content each depth must include for the detected stack.

The output is a **single combined `best-practices.md`** in the project's `.claude/docs/`. Content is LLM-generated at write time, drawing on the model's existing knowledge of the detected stack — not from external sources.

## The three depths

### 1. Essentials (recommended)

**Goal:** the must-know rules that prevent the most common bugs and code-review nits. Loaded often, so it stays cheap to include in context.

**Length budget:** ~50–80 lines per major language/framework detected.

**Required sections:**
- **Top 10 anti-patterns** for the stack (one line each, with the right alternative)
- **Critical rules** (~5–8): things that will silently break or leak in production
- **Common pitfalls** (~5): subtle gotchas that are hard to debug after the fact

**Excluded:** rationale, advanced patterns, performance deep-dives, accessibility specifics, security beyond the basics.

**When to recommend:** most teams, established codebases, when token cost of always-loaded docs matters.

### 2. Standard

**Goal:** essentials plus the rationale and "when to break the rule" guidance. Useful for onboarding and mixed-experience teams.

**Length budget:** ~120–180 lines per major language/framework.

**Required sections:**
- Everything in Essentials
- **Why each rule exists** — one sentence per rule
- **Common patterns** — 5–10 idiomatic patterns for the stack with short examples
- **When to break the rule** — explicit exceptions

**Excluded:** performance optimization, accessibility audits, security beyond auth basics, framework internals.

**When to recommend:** teams with rotating contributors, projects where Claude is expected to onboard new patterns.

### 3. Comprehensive

**Goal:** essentials + standard + advanced. Doubles as a learning reference.

**Length budget:** ~300–500 lines per major language/framework. Use sub-headings aggressively so Claude can grep to the right section.

**Mandatory at Comprehensive:** A **table of contents** at the top of `best-practices.md` listing every `##` and `###` heading with anchor links. This is non-negotiable at Comprehensive depth — the doc is too long for Claude to grep linearly. The TOC is also mandatory whenever multiple stacks are detected (per the multi-stack rule below), regardless of depth.

**Required sections:**
- Everything in Standard
- **Performance** — bundle size, render perf (frontend); query perf, hot paths (backend)
- **Accessibility** — applicable WCAG rules and framework-specific patterns (frontend)
- **Security** — auth, input validation, dependency hygiene, OWASP-relevant items for the stack
- **Advanced patterns** — things like Suspense/Server Components, async iterators, generic constraints, etc., scoped to the framework
- **Framework internals** — only what affects practical decisions (e.g. React reconciler basics, Next.js cache layers)

**When to recommend:** new codebases where conventions are still being set, solo devs, when the doc is also expected to teach.

## Generation rules (apply at all depths)

1. **Stack-specific.** Generic "use meaningful names" content is forbidden. Every rule must be defensibly true *for this stack*. If it would apply equally to all languages, drop it.
2. **Copy-pasteable examples.** Each rule that benefits from a code example gets a 3–10 line snippet. Always prefer the right way; only show the wrong way when the contrast is essential.
3. **Cite specifics.** "React 18+ batches updates" is fine; "React batches updates" is too vague to act on. Pin to detected versions where possible.
4. **No external links.** This doc must work offline — no "see the React docs for more". Inline what's needed.
5. **No project specifics.** Best-practices is the *evergreen* doc. Anything project-specific belongs in `conventions.md` or pattern docs.
6. **One file, one stack at a time.** If the project has multiple stacks (frontend + backend), generate one section per stack with a top-of-file table of contents. Don't generate separate files.
7. **Avoid security-hook trip-wire literals.** Some users have pre-write hooks that string-match risky API names — `eval`, the dynamic-function-body constructor, the React raw-HTML escape hatch, the DOM HTML-property setter, etc. — and block writes containing those literals, even when the surrounding context is *advice not to use them*. To stay portable, phrase security guidance descriptively rather than quoting the API name in code-fence form. Examples:

   - Instead of saying "do not use eval or the dynamic function constructor" → write "do not dynamically construct function bodies from strings; the JavaScript built-ins for this should be avoided."
   - Instead of "avoid setting innerHTML to user input" → write "avoid assigning unsanitized user input to DOM HTML-property setters."
   - Instead of naming React's raw-HTML prop verbatim → describe it as "React's escape hatch for raw HTML injection."

   The rule remains actionable — Claude can still apply it during code review — and it sidesteps hooks that don't understand prose context. If a project's hook is unusually aggressive, surface this in `CLAUDEBOOK.md` Notes.

## Output structure

```markdown
# Best Practices

## <Stack 1, e.g. TypeScript + React 18>
### Critical rules
### Common pitfalls
### Anti-patterns
[depth-dependent additional sections]

## <Stack 2, e.g. Python 3.12 + FastAPI>
### Critical rules
[...]
```

Top of the file lists which depth was chosen and the date generated, so `/claudebook:revise` can decide whether to refresh.

## Stack-specific section: browser extensions (MV2/MV3)

When the detected stack is a browser extension (per `lib/stack-detection.md` — `manifest.json` with `manifest_version`), the generated `best-practices.md` must include a stack section with extension-specific rules. The generic JS/TS rules apply on top, but they aren't enough — extension code has platform constraints that other JS code doesn't.

**Required at all depths:**

- **Manifest version pinning.** State whether the project is MV2 or MV3 and what that implies (MV3: service-worker model, no remote code, stricter CSP; MV2: deprecated by Chrome — flag for migration if detected).
- **Service-worker lifetime (MV3).** State that module-level globals do not persist across worker idle/restart. Persist via `chrome.storage`. Don't rely on top-of-file `let` to retain state.
- **Context isolation.** Content scripts share the DOM with the page but not the JavaScript heap. Page-set globals are invisible to the content script and vice versa. To bridge, inject a web-accessible script and message via `window.postMessage`.
- **No remote code (MV3 CSP).** All executable JS must ship in the package. No CDN imports, no `import()` of remote URLs.
- **Permission minimization.** `host_permissions` and broad permissions (`<all_urls>`, `tabs`) trigger Chrome Web Store review and user warnings — flag them as anti-patterns unless justified.

**Standard depth adds:**

- **Cross-context messaging idioms.** When to use `chrome.runtime.sendMessage` vs `chrome.tabs.sendMessage` vs `window.postMessage`. The Promise vs callback shape difference between MV2 and MV3.
- **Storage choice rationale.** `chrome.storage.local` vs `.sync` vs `.session` trade-offs. Why `localStorage` is fine in popup/options but never in the service worker.
- **`web_accessible_resources` minimization.** Only expose what page JS actually needs.

**Comprehensive depth adds:**

- **CSP construction.** Default extension CSP, what `extension_pages` vs `sandbox` allows, when a custom CSP is justified.
- **Update flow.** What happens to in-flight messages and storage during extension update. Migration patterns for `chrome.storage` schema changes.
- **Performance.** Service-worker startup cost; deferring heavy work to first message; avoiding unnecessary `chrome.tabs.query` calls; debouncing event listeners.
- **Security.** Origin checks on `window.postMessage`; treating page-side content as untrusted in content scripts; `externally_connectable` allowlists.

This section is in addition to (not a replacement for) the JS/TS section. Extensions almost always have JS rules from React/Vue/etc. on top of these platform rules.

## Future stack sections

The same approach applies to other narrow-platform stacks when the plugin learns to detect them: VS Code extensions, mobile (React Native, Flutter), Electron, etc. Add a stack-specific section here when adding detection for that stack to `lib/stack-detection.md`.

## When `/claudebook:revise` should refresh this doc

- A major version bump in a detected framework (`react ^17` → `^18`)
- A new framework added (e.g. project gains a backend)
- The user explicitly asks

Do not refresh just because some best-practices guidance has drifted in the broader ecosystem — the doc is meant to be stable across many revise runs.
