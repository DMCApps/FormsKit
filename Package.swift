// swift-tools-version:6.0

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
            dependencies: [],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "FormsKitTests",
            dependencies: ["FormsKit"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
