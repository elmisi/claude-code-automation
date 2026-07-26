---
name: qa-architect
description: Discover, negotiate, design, build, and audit a contract-driven QA system. Use when a user needs to define what quality means for a product before generating tests, release gates, fixtures, semantic evaluation, or a model-independent QA runner.
---

# QA Architect & Builder — beta

Create a QA system only after making its definition of quality explicit and
approved. Treat the QA Contract as the source of truth; do not substitute model
preference for a requirement.

## Operating modes

Determine the mode from the available artifacts and the user's request:

| Mode | Condition | Allowed outcome |
| --- | --- | --- |
| Discovery | No adequate product model or contract exists. | Decisions, risks, open questions, and interpretation only. |
| QA Design | Discovery is adequate but contract is not approved. | Proposed contract and evaluation architecture only. |
| QA Build | `qa-contract.yaml` says `status: approved`. | Deterministic tests, fixtures, runner integration, then semantic rubrics. |
| QA Audit | A QA system exists. | Contract coverage, mutation evidence, regression gaps, and report. |

Never enter QA Build from a proposed, implied, or chat-only approval. Ask for
explicit approval or write the proposed contract and stop.

## 1. Discovery: grill the quality model

Read existing product material and inspect the target repository before asking a
question that it already answers. If no real project is available, use
`assets/synthetic-markdown-editor-pilot.md` as a labelled synthetic pilot; do
not claim that it validates a production workflow.

Maintain `.qa/decisions.yaml`, `.qa/risks.yaml`, and `.qa/open-questions.md` in
the target project. For every material conclusion, record its source as user
statement, repository evidence, recommendation, or assumption.

Ask **one high-information question at a time**. Before it:

1. summarize the current interpretation;
2. name the consequence or contradiction it exposes;
3. ask the next question with concrete scenarios and alternatives.

Do not use a generic checklist. Challenge vague claims, incompatible goals,
unbounded costs, and subjective goals presented as deterministic gates. Classify
each requirement as an invariant, threshold, regression, heuristic, experiment,
or human decision.

Pause periodically to ask the user to correct the interpretation. Finish
Discovery when the remaining uncertainty no longer prevents a useful contract,
not when a fixed number of questions has been asked.

## 2. QA Design: propose, do not assume

Create the following in `.qa/`, using the templates in `references/`:

- `qa-contract.yaml` from `references/qa-contract-template.yaml`;
- `risk-register.yaml` from `references/risk-register-template.yaml`;
- `eval-matrix.md` from `references/eval-matrix-template.md`;
- `architecture.md` from `references/architecture-template.md`.

Set `status: proposed` in the contract. For every requirement state origin,
motivation, risk, verification type, evidence, severity, success condition,
false-positive risk, automation level, cost, and epistemic status. Separate
confirmed decisions from recommendations and assumptions.

Present the contract as a proposal and ask for one explicit decision: approve,
request changes, or defer. Do not write tests or runner code in this mode.

## 3. QA Build: compile the approved contract

First re-read the approved contract and reject contradictions with the current
repository state. Implement in this order:

1. deterministic checks and fixtures for every blocking invariant, threshold,
   and known regression;
2. a local, model-independent runner that writes structured results and returns
   a non-zero status only for contractual blocking failures;
3. semantic rubrics only where deterministic checks cannot cover the requirement;
4. adapter calls, if requested, that pass evidence to a semantic judge without
   making the runner depend on a particular model or provider.

Each real failure must become a fixture or regression case when it is stable and
within scope. Keep advisory results separate from release gates.

## 4. QA Audit: prove the QA is meaningful

Map every critical risk to at least one verification. Check that each test can
fail for the intended reason, that mocks do not hide the integration being
claimed, and that semantic judgements cite evidence.

Use controlled mutations derived from `references/mutation-catalog.md`. Record
the mutation, expected failure, observed result, and unresolved gap. A green
suite that does not detect a representative mutation is audit evidence of a QA
gap, not a passing result.

Write `.qa/reports/qa-audit.md` with blocking gaps, advisory gaps, evidence,
and next actions. Do not claim release readiness while an uncovered blocking
risk remains.

## Portable operation

The contract, risk register, fixtures, runner, and reports are agent-neutral.
Use platform capability only at the edge. Read
`references/platform-adapters.md` when installing or invoking the skill from
Claude Code, Codex, or OpenCode.

## Beta scope

This beta supplies the workflow, artifact templates, a mutation catalogue, and
a synthetic pilot. It does not promise a universal runner, automated contract
approval, or identical UI/command behavior across platforms.
