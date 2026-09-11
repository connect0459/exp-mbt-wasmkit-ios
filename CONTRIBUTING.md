# Contributing

## Prerequisites

- [MoonBit toolchain](https://www.moonbitlang.com/download/) — `moon` CLI
- [just](https://just.systems/) — task runner
- [pre-commit](https://pre-commit.com/) — hook runner
- [Xcode](https://developer.apple.com/xcode/) — for the `ios/` host app
- [Tuist](https://tuist.dev/) — generates the Xcode project from `ios/Project.swift`

## Setup

```sh
git clone https://github.com/connect0459/exp-mbt-wasmkit-ios
cd exp-mbt-wasmkit-ios
just setup
```

`just setup` runs `moon update` to fetch package dependencies and installs the pre-commit hooks (`pre-commit install`).

To also build and run the iOS host app:

```sh
just ios-generate
```

This builds `guest.wasm` and seeds `ios/Resources/` with it (Tuist resolves `resources:` globs by scanning disk at generate time, so this must happen once before the first `tuist generate`), then runs `tuist install && tuist generate`. Open `ios/MbtWasmkitIosHost.xcworkspace` in Xcode, or build from the command line — see `docs/todo.md` for a worked `xcodebuild`/`simctl` example. After this one-time seed, the app target's own pre-build script keeps `guest.wasm` up to date on every subsequent build.

### pre-commit hooks

To run all hooks manually:

```sh
pre-commit run --all-files
```

## Project structure

- `guest.mbt` (repository root) — the MoonBit code actually under test: functions exported via `#export_name` for the `wasm` target, loaded by the iOS host. The module root *is* the guest package; there is no separate library/CLI scaffold.
- `ios/` — the Tuist-managed SwiftUI app embedding [WasmKit](https://github.com/swiftwasm/WasmKit) to run `guest.wasm`
- `docs/todo.md` — the log of what's been verified, what broke, and why; read it before changing the guest/`ios` boundary

## Development workflow

| Command | Purpose |
| :--- | :--- |
| `moon test` | Run all tests |
| `moon test --target wasm` | Run tests on a specific backend |
| `moon fmt` | Format all source files |
| `moon check` | Type-check without building |
| `moon info` | Regenerate `.mbti` interface files |
| `just verify` | Run the full CI-equivalent check locally |
| `just build-guest-wasm` | Rebuild `guest.wasm` and copy it into `ios/Resources/` |
| `just ios-generate` | `build-guest-wasm`, then `tuist install && tuist generate` |

Before opening a pull request, run the full verification suite:

```sh
just verify
```

This mirrors the CI matrix: it checks all four backends (`js`, `wasm`, `wasm-gc`, `native`).

## Testing guidelines

This project follows **Red → Green → Refactor** (Detroit-school TDD) for MoonBit code:

- Write a failing test first, then implement.
- Use real objects; mocks are only permitted at external boundaries.
- Test names describe **what business rule** is verified, not how.
- Exception: exploratory spikes (verifying a toolchain capability, e.g. whether a given call shape works across the Wasm boundary at all) may skip test-first with explicit agreement — discard or rewrite as a proper implementation afterward. This has been the norm so far, since most of this project's work has been exactly that kind of spike.

Swift code under `ios/` sits at an external boundary (WasmKit, SwiftUI) and isn't held to the same test-first rule; verify it by building and running on a simulator (see `docs/todo.md` for the pattern used throughout).

## Commit format

```text
<type>(<scope>): <subject>
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `tidy`, `test`, `chore`, `ci`, `perf`

**Scope**: package or area name when the change targets one specific thing (`guest`, `ios`); omit for project-wide changes.

**Subject**: imperative mood, 72 characters max, no trailing period.

Examples:

```text
feat(guest): add move_point export for the linear-memory spike
fix(ios): guard against a nil memory export before reading a pointer
docs: record Milestone 2 benchmark results
```

## Pull request process

1. Fork the repository and create a branch: `feat/xxx`, `fix/xxx`, `docs/xxx`.
2. Follow the Red → Green → Refactor cycle for guest changes.
3. Run `just verify` and commit any resulting diffs.
4. If the change touches the guest package's exported API, run `moon info` and verify the `.mbti` diff is expected.
5. If the change affects the iOS host, rebuild via `just ios-generate` (or a plain `xcodebuild` if `Resources/guest.wasm` already exists) and confirm it still runs on a simulator.
6. Update `docs/todo.md` if the change resolves an open question or surfaces a new one — this file is the project's primary record, more so than commit messages alone.
7. Open a pull request — the CI matrix tests `js`, `wasm`, `wasm-gc`, and `native` for the MoonBit side; there is no iOS CI yet (see `docs/todo.md`, Milestone 1 conclusion, for why that's deliberate rather than an oversight).

## Code style

- No code comments unless the **why** is genuinely non-obvious.
- Prefer immutability; avoid mutable state unless necessary.
- Keep the guest package's exported surface minimal and purpose-built for whatever is currently being verified — this is not a general-purpose FFI library.
- All user-facing strings (test names, error messages, doc comments) must be in **English**.
