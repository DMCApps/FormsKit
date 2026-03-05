// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "FormKit",
    platforms: [
        .iOS(.v17),
        .tvOS(.v17),
        .visionOS(.v1),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "FormKit",
            type: .static,
            targets: ["FormKit"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "FormKit",
            dependencies: []
        ),
        .testTarget(
            name: "FormKitTests",
            dependencies: ["FormKit"]
        )
    ]
)
