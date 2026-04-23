# Architecture Decision Records

Numbered, immutable records of domain and architectural decisions. Format is based on [Michael Nygard's template](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions).

## Index

<!-- Append new ADRs here, never remove or reorder. -->

- *(none yet — first ADR added with the first domain decision.)*

## When to write one

Write an ADR whenever a choice is made about:

- Timezone handling
- Trading calendar / session definitions
- Spread / commission / slippage modelling
- PnL convention (gross vs net, inclusive of fees, mark-to-market timing)
- Broker execution semantics (partial fills, requotes, slippage model)
- Any other modelling choice that downstream code silently depends on

## How to write one

1. Copy `0001-template.md` → `NNNN-short-kebab-name.md` (next number in sequence).
2. Fill it in.
3. Add an entry to the index in this README.
4. Commit as part of the PR that introduces the decision.
