// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "FormKit",
    platforms: [
        .iOS(.v16),
        .tvOS(.v16),
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
            dependencies: ["FormKit"],
            swiftSettings: [
                // FormKit requires iOS 17 / tvOS 17 (for @Observable), but the library
                // minimum is set to iOS 16 to match the host app. Tests run on macOS 14+
                // where @Observable is available, so we suppress availability checking
                // in the test target only.
                .unsafeFlags(["-disable-availability-checking"])
            ]
        )
    ]
)
