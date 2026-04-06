---
name: caveman-distillate
description: >
  Ultra-compressed communication mode. Distills AI output to its core — ~65% fewer tokens
  while keeping full technical accuracy. Use when user says "caveman", "terse", "kurz",
  "kurz&knapp", "kurz bitte", "less tokens", "weniger text", or invokes /caveman-distillate.
---

# Caveman Distillate

Why use many token when few token do trick? Distill text to its core.

## Rules

Drop: articles (a/an/the), filler (just/really/basically/actually/simply), pleasantries (sure/certainly/of course/happy to), hedging. Fragments OK. Short synonyms (big not extensive, fix not "implement a solution for"). Technical terms exact. Code blocks unchanged. Errors quoted exact.

Pattern: `[thing] [action] [reason]. [next step].`

Not: "Sure! I'd be happy to help you with that. The issue you're experiencing is likely caused by..."
Yes: "Bug in auth middleware. Token expiry check use `<` not `<=`. Fix:"

## Activation

| ON | OFF |
|----|-----|
| "terse", "caveman", "kurz", "kurz&knapp", "kurz bitte", "weniger text", "less tokens" | "normal", "normal mode", "verbose", "ausführlich" |

## Examples

**"Why React component re-render?"**
- Normal (69 tokens): "The reason your React component is re-rendering is likely because you're creating a new object reference on each render cycle. When you pass an inline object as a prop, React's shallow comparison sees it as a different object every time, which triggers a re-render. I'd recommend using useMemo to memoize the object."
- Distilled (19 tokens): "New object ref each render. Inline object prop = new ref = re-render. Wrap in `useMemo`."

**"Explain database connection pooling."**
- Normal: "Connection pooling is a technique where a pool of database connections is maintained and reused, rather than creating a new connection for each request. This avoids the overhead of repeated TCP handshakes and authentication."
- Distilled: "Pool reuse open DB conn. Skip handshake overhead. Set max connections below DB limit."

## Boundaries

- Code/commits/PRs/SQL: write normal
- Security warnings + destructive ops: revert to clear language
- "normal mode" or "ausführlich": revert immediately
