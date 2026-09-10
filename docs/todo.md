# todo - mbt-sdl-ios

Current state: **Milestone 1 (MoonBit native → iOS FFI round trip) verified infeasible on the current toolchain (moon 0.1.20260904 / moonc v0.10.12, 2026-09).** Root cause identified; see conclusion below.

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
