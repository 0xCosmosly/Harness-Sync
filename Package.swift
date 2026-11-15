// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "HarnessSync", platforms: [.macOS(.v13)], products: [.executable(name: "HarnessSync", targets: ["HarnessSync"])], targets: [.executableTarget(name: "HarnessSync", path: "Sources")])
