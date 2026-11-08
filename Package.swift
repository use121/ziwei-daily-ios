// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ZiWeiDaily",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ZiWeiCore", targets: ["ZiWeiCore"])
    ],
    targets: [
        .target(name: "ZiWeiCore", path: "Sources/ZiWeiCore"),
        .testTarget(
            name: "ZiWeiCoreTests",
            dependencies: ["ZiWeiCore"],
            path: "Tests/ZiWeiCoreTests"
        )
    ]
)
