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
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": .dictionary([:])
            ]),
            sources: ["FormKitExample/**/*.swift"],
            dependencies: [
                .package(product: "FormKit", type: .runtime)
            ]
        ),
        .target(
            name: "FormKitExampleUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "com.example.FormKitExample.UITests",
            deploymentTargets: .iOS("17.0"),
            sources: ["FormKitExampleUITests/**/*.swift"],
            dependencies: [
                .target(name: "FormKitExample")
            ]
        )
    ]
)
