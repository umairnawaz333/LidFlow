// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "LidFlow",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "LidFlow", targets: ["LidFlow"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "LidFlow",
            dependencies: [],
            path: "Sources/LidFlow"
        )
    ]
)
