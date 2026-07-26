# QA architecture

## Contract boundary

Describe the approved input artifacts, source-of-truth order, and invalidation
rule when product requirements change.

## Runner boundary

Describe the local command, structured result format, blocking exit behavior,
and which operations remain model-independent.

## Adapter boundary

Describe optional Claude Code, Codex, or OpenCode calls. Adapters may prepare
context or semantic evidence but must not own the final deterministic verdict.

## Audit boundary

Describe mutation sources, coverage mapping, report output, and the rule for
turning a real defect into a regression case.
