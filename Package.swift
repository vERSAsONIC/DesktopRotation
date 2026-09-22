// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DesktopRotation",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "DesktopRotation",
            path: "Sources/DesktopRotation",
            swiftSettings: [.unsafeFlags(["-swift-version", "5"])]
        )
    ]
)
