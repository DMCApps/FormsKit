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
                .package(product: "FormsKit", type: .runtime)
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
        ),
        .target(
            name: "FormsKitTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.example.FormKitExample.FormsKitTests",
            deploymentTargets: .iOS("17.0"),
            sources: ["../Tests/FormsKitTests/**/*.swift"],
            dependencies: [
                .package(product: "FormsKit", type: .runtime)
            ]
        )
    ]
)
