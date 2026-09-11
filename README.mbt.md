# mbt-wasmkit-ios

[![CI](https://github.com/connect0459/mbt-wasmkit-ios/actions/workflows/ci.yml/badge.svg)](https://github.com/connect0459/mbt-wasmkit-ios/actions/workflows/ci.yml)
[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](https://github.com/connect0459/mbt-wasmkit-ios/blob/main/LICENSE)

An experimental project verifying whether [MoonBit](https://moonbitlang.com)
logic can run inside an iOS app. The original premise — embedding MoonBit's
`native`/`llvm` backend via C FFI, using SDL3 for rendering and lifecycle
bootstrap — turned out to be technically infeasible on the current toolchain
(see `docs/todo.md` Milestone 1). The project now verifies the alternative
route: compiling MoonBit to core `wasm` and running it inside an iOS app via
[WasmKit](https://github.com/swiftwasm/WasmKit), a pure-Swift Wasm
interpreter.

This is not a general-purpose library. It exists to answer one question:
can MoonBit logic run inside an iOS app at all, and if so, is the call
overhead acceptable for something like a real-time game loop?

## Status

Milestone 2 (MoonBit `wasm` → WasmKit → iOS call) succeeded and its
call-overhead concern is de-risked (see `docs/todo.md` for benchmark
numbers and caveats — measurements are simulator-only so far). `guest.wasm`'s
build is now automated via a Tuist pre-build script; see `justfile` for the
one-time `ios-generate` seeding step needed on a fresh clone.
