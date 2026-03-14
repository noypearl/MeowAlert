// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PikudAlert",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "PikudAlert", targets: ["PikudAlert"])
    ],
    targets: [
        .executableTarget(
            name: "PikudAlert",
            path: "Sources/PikudAlert",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
