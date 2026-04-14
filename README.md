# MERGEN

A strategy should not go live unless its execution is provably valid.

MERGEN enforces a simple rule:

No valid trace -> no activation

---

## What this is

MERGEN is a pre-activation authority gate for trading systems.

It does not decide whether a strategy is profitable.

It decides whether a strategy is safe to become active.

---

## Public demo

Run:

./demo.sh

This is a public walkthrough of the gate behavior.

It demonstrates the decision surface without exposing the private runtime core.

The walkthrough shows two outcomes:

- valid execution state -> activation allowed
- corrupted execution state -> activation blocked

---

## What it checks

Before activation, MERGEN verifies whether execution state is still trustworthy.

That includes:

- deterministic execution trace validity
- replay consistency
- state integrity before activation

If verification fails:

activation is blocked

---

## Why this matters

A strategy can pass backtest and still be unsafe to activate.

Without an activation gate:

- corrupted execution state can reach live systems
- replay mismatch can go unnoticed
- broken strategies can become active silently
- debugging becomes slow and unreliable

With MERGEN:

- invalid execution state is stopped before activation
- activation becomes a controlled boundary
- broken strategies do not enter the active set

---

## What MERGEN is

- activation authority layer
- deterministic verification gate
- pre-execution control point

---

## What MERGEN is NOT

- not a trading engine
- not an order router
- not a backtesting tool
- not a portfolio manager
- not a risk model

---

## Security boundary

MERGEN enforces authority only if it is part of the activation path.

If a system bypasses MERGEN and activates strategies directly,
MERGEN cannot prevent that behavior.

This public repository does not expose the private runtime core.

It exposes the product surface and a public walkthrough only.

---

## Public truth

Activation is the last safe checkpoint.

MERGEN is the authority at that checkpoint.
