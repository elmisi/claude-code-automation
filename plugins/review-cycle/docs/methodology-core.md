# review-cycle — core methodology

Shared by every skill in this plugin. It defines what an outcome is, what makes
one admissible, and the shape of `review.md`. Nothing lens-specific belongs here.

## The unit of work is a change, not a file

You are verifying a change: what it does, whether it does what it was meant to,
whether it belongs where it was put, and what it costs if it is wrong. You are
not auditing a diff line by line.

## Two kinds of outcome, not one

**Finding** — a defect. It has a severity and a classification.

**Open question** — a decision to be taken, not an error. It has no severity and
does not get "resolved": someone decides. It is admissible **only** if it names
at least one concrete alternative and that alternative's cost. Without those it
is an opinion, and an opinion is the noise this plugin exists to remove.

Do not deform a legitimate trade-off into a defect. "This choice costs X and the
alternative costs Y" is an open question; forcing it into a finding either buries
it at low severity or misrepresents it as a mistake.

## Every outcome declares what happens if it is ignored

An outcome without a stated consequence does not go in the list. This is the
filter, and it is enforced mechanically by `rc-validate.sh`, which exits 1 and
names the line.

Apply it honestly: most nits die at this test. "If I did not say this, what would
happen?" — nothing. Then it is not an outcome. There is no cap on how many
outcomes you may produce, because the selection already happened here.

## Triage: every finding gets exactly one label

**`auto-fixable`** — deterministic, non-behavioural, inside the perimeter of the
change. It does not become a comment: it goes to the hygiene lane.

**`needs-human`** — judgement is required. It is never resolved automatically.

**When in doubt, `needs-human`.** And the boundary rule: if you have to argue why
a change "does not alter behaviour", it is not a nit.

Never label `auto-fixable` anything touching business logic, public APIs,
schemas, dependencies, configuration, or speculative optimisation. Test files are
outside the hygiene lane's perimeter entirely — a typo in a test comment is a
`needs-human` finding, not an automatic fix.

## Perimeter

Only what the change touches, plus the minimum context needed to understand it.
No cleanup outside the change. If something outside the perimeter matters, say so
as an outcome; do not act on it.

## Say what you left out

Every lens ends by stating explicitly what it did not look at and why. An absent
judgement and an unexamined area look identical in a report unless you separate
them.

## Shape of `review.md`

`rc-validate.sh` enforces this shape. Findings and open questions live under their
own `##` headings; each outcome is a `###` block of `- Key: value` lines.

```markdown
## Findings

### F1 — <one-line title>
- Lens: drift | architecture | risk
- Severity: low | medium | high
- Classification: auto-fixable | needs-human
- Evidence: path/to/file.ext:120
- Consequence: <what happens if this is ignored>
- Question: <the open question, for needs-human findings>

## Open questions

### Q1 — <one-line title>
- Lens: drift | architecture | risk
- Evidence: path/to/file.ext:12
- Consequence: <what happens if this is ignored>
- Alternative: <a concrete alternative>
- Cost: <what that alternative costs>
```

`Evidence` must be `path:line`. An open question must not carry `Severity`.

## What you never do

- Never modify code. Only `review-cycle-hygiene` writes, and only within its own
  rules.
- Never run `git push`, open a pull request, or post a comment.
- Never read the pull request description or the ticket while reconstructing what
  the change does. That order is the whole point of the change brief.
