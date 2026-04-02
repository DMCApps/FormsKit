// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "FormsKit",
    platforms: [
        .iOS(.v17),
        .tvOS(.v17),
        .visionOS(.v1),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "FormsKit",
            type: .static,
            targets: ["FormsKit"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "FormsKit",
            dependencies: []
        ),
        .testTarget(
            name: "FormsKitTests",
            dependencies: ["FormsKit"]
        )
    ]
)
