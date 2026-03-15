// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MeowAlert",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MeowAlert", targets: ["MeowAlert"])
    ],
    targets: [
        .executableTarget(
            name: "MeowAlert",
            path: "Sources/MeowAlert",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
