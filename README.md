# MERGEN

Unverified strategies should not go live.

MERGEN enforces a simple rule:

No valid trace -> no activation

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

## What problem this solves

Without a gate:

- corrupted execution state can reach live systems
- replay mismatch goes unnoticed
- debugging becomes slow and unreliable
- trust in deployment collapses

With MERGEN:

- invalid state is stopped before activation
- no silent promotion of broken strategies
- activation becomes a controlled boundary

---

## Try it

Run:

./demo.sh

You will see:

- valid state -> activation allowed
- corrupted state -> activation blocked

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
- not a risk model

---

## Security boundary

MERGEN enforces authority only if it is part of the activation path.

If a system bypasses MERGEN and activates strategies directly,
MERGEN cannot prevent that behavior.

MERGEN is designed to be:

- integrated into deployment pipelines
- used as a required activation step
- extended toward stronger enforcement layers

---

## Position

MERGEN does not control trading.

It controls whether a strategy is allowed to become active.

---

## One-line truth

Activation is the last safe checkpoint.

MERGEN is the authority at that checkpoint.
