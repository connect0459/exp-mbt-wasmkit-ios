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
      dependencies: [
        .external(name: "WasmKit")
      ],
      settings: .settings(base: ["SWIFT_SUPPRESS_WARNINGS": "NO"])
    )
  ]
)
