# Mutation catalogue

Choose mutations from the approved risks; do not run destructive mutations on
user data or production environments.

| Risk class | Controlled mutation examples | Expected evidence |
| --- | --- | --- |
| Data loss | Remove a persisted record or field in a disposable fixture. | A blocking preservation check fails. |
| Corruption | Serialize an invalid or truncated fixture. | Parser/integrity check fails with a useful diagnosis. |
| Boundary error | Swap minimum and maximum, or cross a threshold by one unit. | Boundary gate fails. |
| Wrong identity | Replace an expected identifier with another valid one. | Fixture/result correspondence fails. |
| Stale or duplicate content | Reuse a prior fixture where freshness/uniqueness is contractual. | Freshness or duplicate check fails. |
| Recovery failure | Make a disposable dependency fail during recovery. | Fallback policy evidence is produced. |

Record a mutation as a gap if the suite passes, fails for an unrelated reason,
or cannot make the intended failure observable.
