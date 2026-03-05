import ProjectDescription

let project = Project(
    name: "FormKitExample",
    packages: [
        .package(path: "..")
    ],
    targets: [
        .target(
            name: "FormKitExample",
            destinations: .iOS,
            product: .app,
            bundleId: "com.example.FormKitExample",
            deploymentTargets: .iOS("17.0"),
            sources: ["FormKitExample/**/*.swift"],
            dependencies: [
                .package(product: "FormKit", type: .runtime)
            ]
        )
    ]
)
