# Hygiene lane

Not a review. It produces no opinions: it takes the findings already labelled
`auto-fixable` and materialises them as local commits, so that deterministic
corrections stop being a conversation.

## Allowed

Typos, evidently obsolete comments, docstrings, lint, formatting, imports, local
non-public naming.

## Forbidden, always

Business logic, public APIs, schemas, dependencies, configuration, speculative
optimisation, and the configuration of lint and CI. If the lane could relax a
lint rule, "lint is clean" would mean nothing.

## Test files are outside the perimeter, without exception

The suite is the instrument that verifies this lane, so the lane does not touch
it. Not "touches it carefully" — does not touch it. A typo in a test comment is
a `needs-human` finding.

This is what makes the check mechanical: `rc-guard.sh` intersects the files you
changed with the test patterns and exits 1 if the intersection is not empty. No
parser, no language, no runner.

## Protocol

1. `rc-suites.sh discover` — the authoritative command comes from CI. If it is
   not yet known, extract it from the CI files and store it once with
   `rc-registry.sh set-test-command`.
2. `rc-suites.sh enumerate` — CI is not a census. Note which suites CI does not
   cover; they must not break either.
3. Run every suite once, before touching anything. A suite that is green enters
   the gate. A suite that is already red, or cannot run here, stays out of the
   gate and is **declared** in `hygiene.md` with the reason — a stated blind spot
   is a better defence than a restriction nobody will lift.
4. If the authoritative suite is red, stop. The lane does not start.
5. Apply every fix, then run the gate suites **once**. Not once per commit: the
   suite runs dominate the cost of a pass.
6. Green: commit by category — one themed commit per group, clear message,
   reversible, never mixed with logic.
   Red: bisect by category, drop the offending group, reclassify those fixes as
   `needs-human`, and re-run.
7. `rc-guard.sh` before committing. If it exits 1, revert those files.
8. Where a collect command is known, compare the collected test set before and
   after — an additional check that catches indirect changes to collection, such
   as an import removed from a source file that was what registered a test.
   Where it is not known, declare that in `hygiene.md` and continue.
9. Never `git push`. Never open a pull request. The outward gesture is the user's.

The guarantee holds on the branch's final state, not on every intermediate
commit taken alone. That is the price of running the suite once instead of once
per commit, and it is accepted deliberately.

## `hygiene.md` must state

Files touched, categories applied, which suites entered the gate and which did
not with the reason, suite result before and after, commits produced, and the
list of what was deliberately left open.

If there was nothing to fix, say that. A pass with no fixes is a valid outcome,
not a failure.
