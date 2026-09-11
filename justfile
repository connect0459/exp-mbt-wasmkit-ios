# Setup after clone
setup:
    moon update
    pre-commit install

# Run tests for a single target (e.g. `just test-target wasm-gc`)
test-target target:
    moon check --deny-warn --target {{target}}
    moon test --target {{target}}

# Verify code quality and all targets (matches CI)
verify:
    moon fmt --check
    for t in js wasm wasm-gc native; do \
        just test-target $t; \
    done

# Build guest.wasm and copy it into the iOS host's Resources/. Required
# once before the first `tuist generate` — Tuist resolves `resources:`
# globs at generate time, so an empty Resources/ produces a project with
# no Copy Bundle Resources entry for guest.wasm. After that, the iOS
# target's own pre-build script keeps it up to date on every build.
build-guest-wasm:
    moon build --target wasm --release
    cp _build/wasm/release/build/exp_mbt_wasmkit_ios_guest.wasm ios/Resources/guest.wasm

# Generate the Tuist-managed Xcode project for the iOS host
ios-generate: build-guest-wasm
    cd ios && tuist install && tuist generate --no-open
