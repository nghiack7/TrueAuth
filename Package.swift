// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TrueAuth",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "TrueAuth",
            path: "Sources"
        )
    ]
)
