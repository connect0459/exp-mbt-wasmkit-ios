# Security Policy

This is an experimental spike, not a published library or a shipped
application — there is no release users install, and `guest.wasm` is always
built from this repository's own source, never loaded from an untrusted or
third-party origin. The scope below is narrower than a typical library's
because of that.

## Supported Versions

Only the `main` branch is maintained. There are no tagged releases.

| Version | Supported |
| :------ | :-------- |
| `main`  | ✓         |

## Reporting a Vulnerability

**Please do not open a public GitHub issue for security vulnerabilities.**

Use GitHub's [private vulnerability reporting][private-report] feature to disclose issues confidentially. You will receive an acknowledgment within **5 business days** and a resolution timeline once the report has been triaged.

[private-report]: https://github.com/connect0459/mbt-wasmkit-ios/security/advisories/new

## Scope

The following vulnerability classes are in scope for this project:

- **Sandbox escapes at the guest/host boundary** — any way for code running inside `guest.wasm` (via WasmKit, on the iOS host) to read or write memory, call functions, or otherwise affect the host process outside the linear memory and exported functions WasmKit explicitly grants it.
- **Memory-safety bugs in the Swift host bridge** — `ios/Sources/GuestBridge.swift`'s use of `memory.withUnsafeMutableBufferPointer` (reading a guest-heap-boxed tuple by pointer) is the one place this project currently does unsafe pointer arithmetic against guest-controlled data; an out-of-bounds read/write there is in scope.
- **Supply-chain issues in pinned dependencies** — `ios/Tuist/Package.swift` pins WasmKit and its transitive dependencies to exact versions; a compromised release of any of them is in scope for a coordinated response, even though the fix (bump the pin) lives upstream.

The following are **out of scope**:

- Anything that requires the attacker to already control the content of `guest/` in this repository — that's a source-code change, not a vulnerability.
- Issues in third-party dependencies themselves (report those upstream; this project will track and apply the fix).
- Theoretical issues without a reproducible proof-of-concept.
- Performance characteristics (see `docs/todo.md` for known, intentionally-recorded call-overhead numbers) — not a security concern by itself.

## Disclosure Policy

Once a fix is ready, a GitHub Security Advisory will be published with full details. The typical timeline from report to public disclosure is **30 days**, though this may be extended by mutual agreement when a fix requires significant changes.
