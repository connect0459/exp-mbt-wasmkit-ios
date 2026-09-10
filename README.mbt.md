# connect0459/mbt_sdl_ios

[![CI](https://github.com/connect0459/mbt-sdl-ios/actions/workflows/ci.yml/badge.svg)](https://github.com/connect0459/mbt-sdl-ios/actions/workflows/ci.yml)
[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](https://github.com/connect0459/mbt-sdl-ios/blob/main/LICENSE)

An experimental project verifying whether [MoonBit](https://moonbitlang.com)'s
`native` backend can be embedded into an iOS app via C FFI, using SDL3 for
rendering, input, and lifecycle bootstrap (`SDL_main` provides the
`UIApplicationDelegate`, playing the role Android's `NativeActivity` plays in
MoonBit's existing Android game demo).

This is not a general-purpose library. It exists to answer one question:
given MoonBit native has no official iOS target, can MoonBit-generated C
still be cross-compiled and linked into an iOS binary in practice?

## Status

Milestone 1 (minimal FFI round trip: MoonBit `extern "C"` function → native
build → linked and called from an iOS Xcode target) is in progress.
