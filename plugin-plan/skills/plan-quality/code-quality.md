# Code Quality Criteria

Principles are listed in **decreasing priority**: when two conflict on the same decision, the higher one wins.

---

### 1. Readability

Target reader: a senior developer familiar with the language/framework who has **not** seen this file before. If that reader needs to pause, re-read, or open unrelated files to understand what a block does, the block is unclear.

Signals of failure: deeply nested conditionals, overloaded names, unexplained shortcuts, template expressions that pack multiple unrelated checks into one branch.

### 2. Essentiality

Prefer code where removing anything breaks real behaviour. Candidates for removal: defensive additions that catch nothing in practice, validators wrapping already-typed data, try/catch around calls that cannot reasonably fail, intermediate abstractions with a single caller.

**Boundary exception:** input validation at trust boundaries (user input parsing, auth checks, external API responses) is essential — removing it would accept invalid data silently. "Essential" means nothing that doesn't earn its keep, not minimal in the cosmetic sense.

### 3. Cognitive Load

The metric is not "fewer lines" but "fewer things the reader must hold in working memory." Indicators: nested ternaries (> 1 level), boolean expressions with > 3 terms inline, handler bodies whose core logic sits at indent >= 3 because guard conditions are inverted, single files mixing I/O + business rules + presentation.

### 4. Naming as Abstraction

A complex expression, predicate, or calculation should carry a name that describes its intent.

- Inline boolean like `isLoading && results.length === 0 && query.length >= MIN` → extract as `const showLoadingState = …` at the top of the block.
- Inline predicate reused in >= 2 sites → extract as a named helper in the appropriate domain module.
- **DRY, narrow form:** duplicated *knowledge* — same business rule, mapping, or behavioural contract expressed in two places — must converge on one name. Duplicated *code that happens to look similar* but serves different purposes is not a target.

### 5. Tell, Don't Ask

When a block interrogates an object's fields to decide *about that object*, the decision belongs near the data. Preferred shapes:

- a) Named function in a domain module: `canUserBuy(customer)`. This is the default and should be proposed first.
- b) Class or module wrapping the data when >= 3-4 correlated predicates on the same object earn a single home.

Prefer (a) unless (b) earns its keep on principles 2-3.

### 6. Fail Fast, Fail Loud

A silent failure is technical debt. Patterns that swallow errors without a stated reason (empty catch, catch-and-return-default, catch-and-log-only) are smells.

If the swallow is deliberate (graceful degradation, optional enrichment), the code must carry a one-line comment stating *why* the error is acceptable and *what* the caller sees. Otherwise: propagate the error or return for example `{ data, error }` result.

### 7. Command-Query Separation

A function returns data (query) *or* mutates state (command), not both. When a query unavoidably triggers a side effect (e.g., token rotation, cache warm-up), the mutation contract must be visible at the call site — via naming, return type, or a site-level comment.

If the same mutation ceremony recurs across >= 5 call sites with identical intent, the remediation escalates from per-site documentation to architectural: move the ceremony into the abstraction (middleware, wrapper client, lifecycle hook) rather than documenting it N times.

### 8. Least Surprise

A name should predict the behaviour. `getCart` that rotates a token is surprising; `createOrder` that silently reads from local state is surprising; a function that returns `null` on a transient error is surprising.

Preferred remediation order: rename > split > document-at-site. Documenting is the fallback, not the default.

### 9. Comments Only for Non-Obvious Why

A comment that restates the code is noise. A comment that records intent a reader cannot recover from the code — a framework quirk, a deliberate error swallow, a guard that looks redundant but prevents a known race — is evidence.

**Trigger test:** if removing the comment leaves an experienced reader uncertain *why* the code chose this shape, keep it. If it only explains *what*, drop it.

---

## Explicitly Not Used as Drivers

These are not invalid principles, but they are not primary drivers in this criteria set. Proposals must not cite them as sole justification:

- **DRY as generic "reduce duplication"** — only duplicated *knowledge* counts (absorbed into principle 4)
- **SOLID as abstract adherence** — can justify speculative abstraction conflicting with principles 2-4
- **Inheritance-based designs** — class is allowed (5b) but hierarchy is not a goal
- **"Make illegal states unrepresentable"** as standalone driver — legitimate cases (trust boundary validation) are covered by principle 2; pushing further risks type gymnastics
- **Extract pure functions for testability alone** — extraction must earn its keep on principles 3-5
- **Cosmetic consistency with low payoff**
- **Locality of Behavior** — can force arrangements that hurt readability more than they help
- **Explicit over Implicit** — risks promoting verbosity; the relevant sub-concern (hidden magic) is caught by principle 8
