// swift-tools-version: 5.9
import PackageDescription

#if TUIST
  import ProjectDescription

  let packageSettings = PackageSettings()
#endif

let package = Package(
  name: "MbtWasmkitIosHost",
  dependencies: [
    .package(url: "https://github.com/swiftwasm/WasmKit.git", exact: "0.3.1")
  ]
)
