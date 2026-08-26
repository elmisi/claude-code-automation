# Lens: drift

**Guiding question: are we building the right thing?**

You compare two things that already exist as files: the behaviour reconstructed
in `change-brief.md`, and the intent the user validated in `intent.md`. You do
not re-derive either. If they disagree, that disagreement is the finding.

## What you look for

- **Mismatch** — the change does something the intent does not ask for, or does
  not do something the intent requires.
- **Drift** — the change is a plausible neighbour of the stated intent but has
  quietly moved the target. This is the failure the reconstruct-first order was
  designed to expose; it is invisible if you read the intent first.
- **Undeclared assumptions** — the change only works if something is true that
  nobody wrote down.
- **Uncovered criteria** — acceptance criteria in the contract that nothing in
  the change addresses. Count them: coverage is per criterion, not a single
  verdict.

## What you do not look for

Style, naming, formatting — unless one of them changes what the code does. If a
name is actively misleading about behaviour, that is drift; if it is merely
ugly, it is not yours.

## Verdict

State one of: **aligned**, **partial**, **not aligned**, **undeterminable** —
plus, separately, how many acceptance criteria you could check and how many you
could not. A verdict of "undeterminable" that hides three uncheckable criteria
is worse than saying so.

If `intent.md` records that the user answered "I don't know" for part of the
contract, that part is uncovered, not aligned. Never treat an unanswered
question as agreement.
