import ProjectDescription

let project = Project(
  name: "MbtSdlIosHost",
  organizationName: "dev.connect0459",
  settings: .settings(base: ["SWIFT_SUPPRESS_WARNINGS": "NO"]),
  targets: [
    .target(
      name: "MbtSdlIosHost",
      destinations: .iOS,
      product: .app,
      bundleId: "dev.connect0459.MbtSdlIosHost",
      deploymentTargets: .iOS("18.0"),
      infoPlist: .extendingDefault(
        with: [
          "UILaunchScreen": [:],
          "UIApplicationSceneManifest": [
            "UIApplicationSupportsMultipleScenes": false
          ],
        ]
      ),
      sources: ["Sources/**"],
      resources: ["Resources/**"],
      scripts: [
        .pre(
          script: """
            set -e
            MOON_BIN="$HOME/.moon/bin/moon"
            if [ ! -x "$MOON_BIN" ]; then
              echo "error: moon not found at $MOON_BIN -- install the MoonBit toolchain first (https://www.moonbitlang.com/download)" >&2
              exit 1
            fi
            PROJECT_ROOT="$(cd "$SRCROOT/.." && pwd)"
            (cd "$PROJECT_ROOT" && "$MOON_BIN" build guest --target wasm --release)
            cp "$PROJECT_ROOT/_build/wasm/release/build/guest/guest.wasm" "$SRCROOT/Resources/guest.wasm"
            """,
          name: "Build MoonBit guest.wasm",
          outputPaths: ["$(SRCROOT)/Resources/guest.wasm"],
          basedOnDependencyAnalysis: false
        )
      ],
      dependencies: [
        .external(name: "WasmKit")
      ],
      settings: .settings(base: ["SWIFT_SUPPRESS_WARNINGS": "NO"])
    )
  ]
)
