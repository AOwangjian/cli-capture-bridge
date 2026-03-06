// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CLICaptureBridgeMac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "CLICaptureBridgeMac",
            targets: ["CLICaptureBridgeMac"]
        )
    ],
    targets: [
        .executableTarget(
            name: "CLICaptureBridgeMac",
            path: "Sources"
        )
    ]
)
