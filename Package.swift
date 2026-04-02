// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TrueAuth",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "TrueAuthKit",
            targets: ["TrueAuthKit"]
        )
    ],
    targets: [
        .target(
            name: "TrueAuthKit",
            path: "Sources/TrueAuthKit"
        ),
        .executableTarget(
            name: "TrueAuth",
            dependencies: ["TrueAuthKit"],
            path: "Sources/TrueAuth"
        )
    ]
)
