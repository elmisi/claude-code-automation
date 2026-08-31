# Review — evidence forms

## Findings

### F1 — Range and two references, both admissible
- Lens: drift
- Severity: high
- Classification: needs-human
- Evidence: change-brief.md:3-5; intent.md:10 (criterion 2)
- Consequence: A persistent outage surfaces only after three attempts with no ceiling, which contradicts the validated criterion.

### F2 — Prose evidence, not admissible
- Lens: risk
- Severity: medium
- Classification: needs-human
- Evidence: somewhere in the payment client
- Consequence: Without an anchor the reader cannot open what is being claimed.

## Perturbation

- Executed: drove the changed path against a local instance; the session lookup fired once per request.
- Mutated: not applicable — no check was added or changed by this diff.
- Not perturbed: the failure path behind the store timeout; reproducing it needs a fault injector this repo does not have.
