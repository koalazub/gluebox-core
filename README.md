# gluebox-core

Shared infrastructure crate for gluebox-family daemons. Holds the primitives both `gluebox` (trading / autoposting) and `unibox` (study orchestration) want — no domain-specific business logic.

## Contents

| Module       | What it provides                                                                                   |
|--------------|----------------------------------------------------------------------------------------------------|
| `connector`  | `Connector` trait (object-safe async lifecycle: start / stop / suspend / resume / health_check / reconfigure) + `ConnectorStatus` enum. |
| `registry`   | `ConnectorRegistry` — `Arc<dyn Connector>` collection with `register`, `deregister`, `toggle`, `suspend_all`, `resume_all`, `stop_all`, `list`. |
| `power`      | `PowerManager` — leaky integrate-and-fire neuron model. `spike(weight)` raises membrane potential, `tick()` decays it. Transitions `Resting ↔ Active` based on `threshold` + `hold_period` hysteresis so daemons can suspend idle connectors without flapping. |

5 tests (`cargo test`) cover PowerManager's spike / decay / hold-period invariants.

## Status

Early bootstrap. The two consumers:

- `~/projects/gluebox` — still carries its own copies of `connector.rs` / `registry.rs` / `power.rs`. Migration to consume `gluebox-core` is deferred until there's something a second consumer forces into the shared surface. This is deliberate: extracting abstractions before you've seen the second use case tends to bake in the wrong shape.
- `~/projects/unibox` — depends on `gluebox-core` via `path` dep. Doesn't use the types yet (Phase 3 MVP talks to samaya via subprocesses, not connectors), but the dep is wired so Phase 4's socket daemon can adopt them without a dependency rearrangement.

## Architectural intent

Both daemons sit in the same shape: a long-running Tokio process that hosts a collection of async connectors, gates them behind a power-saving activity model, and exposes a socket or IPC surface to operators. This crate is the exactly-as-much-as-shared substrate for that shape — nothing about calendars, recording, trading signals, or posting schedules lives here.

Downstream additions when they earn their keep:

- Socket + Cap'n Proto protocol (proto schema + codegen hooks)
- Config hot-reload primitives
- MatrixConnector (reusable Matrix bot implementing `Connector`)

Each of those moves out of the parent daemon once a second consumer pulls on it.

## Development

```
cd ~/projects/gluebox-core
cargo build
cargo test
```

Path deps: none — this crate is the leaf of the dependency tree in its domain. Consumers reference it via `{ path = "../gluebox-core" }`.

## License

Apache-2.0.
