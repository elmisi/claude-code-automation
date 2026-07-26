# Synthetic pilot: Markdown editor

> This is a disposable beta scenario, not a product requirement.

## Product premise

A desktop Markdown editor opens an existing document, allows visual edits, and
saves it. The primary value is preserving user-authored content safely.

## Initial claims to grill

- Users are developers and technical writers.
- Content loss, file corruption and silent overwrite are unacceptable.
- Semantically equivalent Markdown serialization might be acceptable.
- HTML comments and original spacing might matter to some users.
- A file changed by another program needs an explicit fallback policy.

## Expected Discovery behaviour

Do not begin by writing tests. Ask whether an unmodified open/save must be
byte-identical or semantically equivalent, explain the consequence for comments
and formatting, then continue from the answer.

## Candidate mutation

Delete one non-empty line from a disposable saved fixture. The eventual QA suite
must fail a blocking preservation check; otherwise report a coverage gap.
