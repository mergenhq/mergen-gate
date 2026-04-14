# MERGEN

A strategy should not go live unless its execution is provably valid.

MERGEN enforces a simple rule:

No valid trace -> no activation

---

## Quick demo

Run:

./demo.sh

You will see:

- valid state -> activation allowed
- corrupted state -> activation blocked

---

## What it does

MERGEN is a pre-activation authority gate for trading systems.

It verifies that a strategy:

- has a valid deterministic execution trace
- is replay-consistent
- is not corrupted or tampered

If verification fails:

activation is blocked

---

## Why this matters

Without a gate:

- corrupted execution state can reach live systems
- replay mismatch goes unnoticed
- debugging becomes slow and unreliable
- broken strategies can be promoted silently

With MERGEN:

- invalid state is stopped before activation
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

---

## Security boundary

MERGEN enforces authority only if it is part of the activation path.

If a system bypasses MERGEN and activates strategies directly,
MERGEN cannot prevent that behavior.

---

## One-line truth

Activation is the last safe checkpoint.

MERGEN is the authority at that checkpoint.
