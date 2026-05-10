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

## When `/claudebook:revise` should refresh this doc

- A major version bump in a detected framework (`react ^17` → `^18`)
- A new framework added (e.g. project gains a backend)
- The user explicitly asks

Do not refresh just because some best-practices guidance has drifted in the broader ecosystem — the doc is meant to be stable across many revise runs.
