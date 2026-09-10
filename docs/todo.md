# todo - mbt-sdl-ios

Current state: **Milestone 2 (MoonBit `wasm` → WasmKit → iOS simulator round trip) succeeded.** Milestone 1 (MoonBit native → iOS FFI round trip) was verified infeasible on the current toolchain (moon 0.1.20260904 / moonc v0.10.12, 2026-09); its root cause is documented below, and Milestone 2 is the alternative route it motivated.

---

## Milestone 0: Project scaffold

- [x] `moon new` scaffold, renamed to `connect0459/mbt_sdl_ios`
- [x] Ported `AGENTS.md`/`CLAUDE.md`, `.markdownlint.json`, `.pre-commit-config.yaml`, `apm.yml` (moonbitlang/skills), `.github/` (CI, publish, issue/PR templates), `justfile` from `starlark-mbt`/`urllib-mbt`
- [x] Committed as separate concern-based commits

## Milestone 1: Minimal FFI round trip (MoonBit native → Xcode link → iOS call)

Goal: verify whether a MoonBit `extern "C"` function can be built for native and linked into an iOS Xcode target, before attempting the SDL3 game-loop experiment.

- [x] Confirm local toolchain availability — `moon 0.1.20260904`, `Xcode 26.6`, `iPhoneOS26.5` SDK all present
- [x] Confirm MoonBit native backend's official platform support — macOS (Apple Silicon) / Linux / Windows (nightly only) per `v0.10.0`/`v0.10.9` release notes; iOS not listed
- [x] Inspect the actual `moon build --target native` command pipeline via `--dry-run` — `moonc link-core` emits an object file directly for one of **4 hardcoded triples** (`aarch64-apple-darwin`, `aarch64-unknown-linux-gnu`, `x86_64-unknown-linux-gnu`, `x86_64-pc-windows-msvc`); **no intermediate `.c` file is produced**
- [x] Confirm via `moonc link-core -S` (textual output) that the native backend emits raw AArch64 assembly, not C — contradicts the "last IR layer is a subset of C" premise carried over from `tmp.md`
- [x] Confirm `#export_name` (the mechanism to make a MoonBit function C-callable) is wasm/wasm-gc/js only — **not supported on native**, regardless of the C-source question
- [x] Try `--target llvm` on the stable toolchain — fails: LLVM backend requires nightly, and `moonbitlang/core` has no LLVM-target bundle prebuilt
- [x] Install `moonup`, pin `nightly` to this project only via `moonup pin nightly` (`moonbit-version` file) — confirmed sibling projects (`urllib-mbt`) remain on the stable toolchain
- [x] Bundle `moonbitlang/core` for the llvm target — `moon bundle --target llvm --release`, run inside the toolchain's `lib/core` directory (undocumented; found via `strings` on the `moon` binary, no `--help` entry)
- [x] Build `cmd/main --target llvm` on nightly for the host triple — succeeds
- [x] Try `-llvm-target arm64-apple-ios` via a direct `moonc link-core` invocation — accepted without error, but the resulting `.o` has **no `LC_BUILD_VERSION` load command** (verified with `otool -l`, diffed against a real `clang -target arm64-apple-ios15.0` object) — the flag is accepted but does not produce a valid iOS object
- [x] Inspect `libmoonbitrun.o` (the runtime entry point statically linked into every native/llvm executable) — **prebuilt macOS-only binary** (`platform 1`, minos 11.0), no source distributed with the toolchain; even a working iOS codegen path would dead-end at link time on this file alone
- [x] Cross-check against `tonyfettes/tonyfettes-create-moonbit-raylib-android-app` (the actual scaffold behind the dev.to "Build a Mobile Game with MoonBit" article referenced in `tmp.md`) — its `CMakeLists.txt` expects `moon build --target native` to emit `_build/native/debug/build/<pkg>.c` and hands that file to the Android NDK's C compiler; **this C-emission path no longer exists** in the current toolchain, so this scaffold is almost certainly broken on current MoonBit
- [x] Read `moonbitlang.com/blog/llvm-backend` (2025-03-11) — confirms MoonBit deliberately moved away from "compile to C, then shell out to a C compiler" toward direct LLVM-based codegen; this is the documented root cause of the above, not a regression or misconfiguration on our side
- [x] **Conclusion**: no supported path currently exists from MoonBit native/llvm to an iOS binary.
  - Compiler-level: native backend's 4 triples don't include iOS; llvm backend accepts an iOS triple but doesn't emit a correctly tagged object
  - Distribution-level: `libmoonbitrun.o` is a source-unavailable macOS-only prebuilt, which would block even a correct codegen path
  - Historical: the Android game demo this project's premise (`tmp.md`) leaned on relied on a C-emission path that MoonBit has since removed (2025-03 LLVM migration)

## Open questions / next steps

- [ ] Decide project direction: park here and keep this as a documented negative result / re-scope to wasm-gc + an iOS-side WASM runtime (e.g. WasmKit) / wait for the LLVM backend to reach stable with a source-available or iOS-built runtime entry object
- [ ] If revisiting later: check `moonbitlang/moonbit-compiler` and `moonbitlang/moon` issue trackers for iOS-target or `libmoonbitrun` source-availability discussion before re-attempting
- [ ] If revisiting later: check whether `tonyfettes/tonyfettes-create-moonbit-raylib-android-app` (and the Android path generally) still works on current MoonBit, since its CMake template assumes the now-removed C-emission path

### Prior art: `Nanaloveyuki/wasee-moon` (Android WASI host bridge)

- [x] Surveyed `github.com/Nanaloveyuki/wasee-moon` — an existing, working instance of the "wasm + host-side WASM runtime" escape route (this doc's first open-question bullet), on Android rather than iOS
  - `guest/main.mbt` compiles to core Wasm via `--target wasm` (`.moon-version` pinned to `0.10.9+6e6c44045` — unaffected by the native/llvm C-emission removal documented above, since `wasm` was never on that path)
  - Android host embeds **Chicory** (`com.dylibso.chicory`), a pure-JVM WASI Preview 1 runtime — explicitly chosen because it needs no NDK or architecture-specific JNI libraries
  - `bridge/bridge.mbt` exposes a bounded core-Wasm ABI (deliberately not a Component Model binding) over which the guest negotiates USB/AOA access; the host never hands the guest a `UsbDeviceConnection`, a JVM object, a raw pointer, or unbounded filesystem/network access — capability-scoped by an explicit allowlist
- [x] Assessed relevance to this project: the same shape (MoonBit → `wasm` guest, SDL3 surface wrapped as host-side import functions, called from a Swift-side WASM runtime such as **WasmKit**) would sidestep every blocker recorded in Milestone 1, since it never touches the native/llvm backend at all
- [ ] Open concern (not yet checked): `wasee-moon`'s guest/host boundary is for discrete, low-frequency I/O (USB control/bulk transfers). SDL3's game-loop shape (per-frame draw calls + input polling) is a different load profile across a Wasm import boundary — whether WasmKit's call overhead is acceptable for real-time rendering is unverified and would need its own spike before committing to this direction

## Milestone 2: Minimal FFI round trip via `wasm` + WasmKit (MoonBit wasm → iOS simulator call) — SUCCEEDED

Goal: verify the alternative route surfaced by the `wasee-moon` survey — a MoonBit function compiled to core `wasm`, loaded and called from Swift via WasmKit on an iOS simulator — before committing to it as Milestone 1's replacement.

- [x] Added `guest/` package (`pkgtype(kind: "foreign_library")`), TDD: wrote `guest_test.mbt` first (Red), then implemented `increment(value : Int) -> Int` with `#export_name("increment")` (Green) — `moon test guest --target wasm` passes
- [x] Built `moon build guest --target wasm --release` — output is a 217-byte `guest.wasm`; dumped with `wasm2wat` and confirmed it's just `(func (param i32) (result i32) local.get 0 i32.const 1 i32.add)` with no MoonBit GC/runtime overhead (this function never allocates)
- [x] Corrected an earlier claim: WasmKit does **not** support iOS 12+. Its own `Package.swift` (not the `Examples/Package.swift`, which is stale) declares `platforms: [.macOS(.v15), .iOS(.v18)]` — confirmed by an actual build failure (`compiling for iOS 16.0, but module 'WasmKit' has a minimum deployment target of iOS 18.0`) before raising the deployment target
- [x] Confirmed WasmKit 0.3.1 does not implement the Wasm GC proposal (`"[Garbage Collection] ❌ Not implemented"` in its own docs) — MoonBit must target `wasm`, not `wasm-gc`, to run on WasmKit; matches `wasee-moon`'s choice
- [x] Learned the WasmKit embedding API from `Examples/Sources/Factorial` and `Examples/Sources/PrintAdd` in the WasmKit repo (no public doc site access): `parseWasm(bytes:)` → `Engine()` / `Store(engine:)` → `module.instantiate(store:imports:)` → `instance.exports[function: "name"]!` → `try fn([.i32(value)])` → `result[0].i32`. Note `Value.i32`/`.i64` etc. are **unsigned** (`UInt32`/`UInt64`), not signed — had to change the Swift bridge signature from `Int32` to `UInt32` to compile
- [x] Scaffolded the iOS host app (`ios/`) — first with `xcodegen`, later replaced with **Tuist** (see below) at the user's request
- [x] Hit and fixed a build error common to both generators: Xcode 16+ defaults new projects to `SWIFT_SUPPRESS_WARNINGS = YES`, which conflicts with WasmKit's own `Package.swift` (`.treatAllWarnings(as: .error, ...)` on every target) — `error: conflicting options '-warnings-as-errors' and '-suppress-warnings'`. Project-level `SWIFT_SUPPRESS_WARNINGS: NO` was not enough (Tuist's `.external` targets and xcodegen's SPM package targets don't inherit it); had to pass `SWIFT_SUPPRESS_WARNINGS=NO` as an explicit `xcodebuild` command-line override
- [x] Hit and fixed a resources bug specific to xcodegen: a target-level `resources:` key silently produced an app bundle with no `guest.wasm` inside (`Bundle.main.url(forResource:withExtension:)` returned nil at runtime, no build-time warning). Fix: declare it under `sources:` with `buildPhase: resources` instead — xcodegen has no dedicated top-level `resources` field despite accepting the key
- [x] Ran on `iPhone 17` / iOS 26.5 simulator via `simctl install` + `simctl launch` + `simctl io screenshot` — **screen shows `increment(41) = 42`**, confirming the full round trip: MoonBit `wasm` guest → WasmKit interpreter → SwiftUI
- [x] **Switched project generator from xcodegen to Tuist** (user request): replaced `ios/project.yml` with `ios/Tuist/Package.swift` (external SPM dependency: `.package(url: "https://github.com/swiftwasm/WasmKit.git", exact: "0.3.1")`) and `ios/Project.swift` (`.external(name: "WasmKit")` dependency, same `SWIFT_SUPPRESS_WARNINGS` + iOS 18.0 deployment target settings). `tuist install && tuist generate` resolves the same transitive dependency set (swift-nio, swift-atomics, swift-collections, swift-log, swift-argument-parser, swift-system) that SPM resolved under xcodegen
- [x] Re-verified after the Tuist switch: same `SWIFT_SUPPRESS_WARNINGS=NO` override needed, same `guest.wasm` bundling worked via Tuist's `resources: ["Resources/**"]` (Tuist's field name matches what xcodegen's docs claimed but xcodegen itself didn't honor), rebuilt, reinstalled, relaunched — **`increment(41) = 42` reproduced identically** on the same simulator
- [x] `.gitignore`: added Tuist-generated artifacts (`ios/*.xcodeproj/`, `ios/*.xcworkspace/`, `ios/Derived/`, `ios/Tuist/.build/`) plus general Xcode/Swift entries (`xcuserdata/`, `*.hmap`, `*.dSYM`), cross-checked against `~/workspaces/digitalio/ecnavi-enquete-app/.gitignore` (a real Tuist-based iOS project) for parity; `Tuist/Package.resolved` is **not** ignored (kept for reproducible dependency versions, matching that project's convention). `ios/Resources/*.wasm` is ignored — it's a `moon build` artifact, not source
- [ ] **Not yet solved**: `guest.wasm` is currently copied into `ios/Resources/` by hand after `moon build guest --target wasm --release`. No build-time automation (Tuist target script / justfile task) wires this up yet — a fresh clone cannot build a working app without manually running and copying the MoonBit build output first
- [ ] **Not yet verified**: the real question this milestone was a prerequisite for — whether WasmKit's per-call interpreter overhead is acceptable for SDL3's per-frame draw-call/input-polling load, not just this single discrete call
