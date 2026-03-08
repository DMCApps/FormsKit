import FormKit

// MARK: - Debug Menu Enums

enum DebugEnvironment: String, CaseIterable, CustomStringConvertible, Hashable, Sendable, Codable {
    case dev, staging, prod
    var description: String { rawValue.capitalized }
}

private enum LogLevel: String, CaseIterable, CustomStringConvertible, Hashable, Sendable, Codable {
    case verbose, debug, info, warning, error
    var description: String { rawValue.capitalized }
}

// MARK: - DebugMenuForm

/// Demonstrates sub-form navigation (NavigationRow) and file-based persistence.
/// The Network Settings and Feature Flags sub-forms are nested inside.
enum DebugMenuForm {
    // MARK: - Sub-forms

    static let networkSettingsForm = FormDefinition(
        id: "debug.network",
        title: "Network Settings",
        persistence: FormPersistenceFile(keyPrefix: "DebugMenu")
    ) {
        TextInputRow(
            id: "baseURL",
            title: "API Base URL",
            defaultValue: "https://api.dev.example.com",
            placeholder: "https://api.example.com",
            validators: [
                .regex("^https?://", message: "Must start with http:// or https://", trigger: .onSave)
            ]
        )

        NumberInputRow(
            id: "timeout",
            title: "Request Timeout (seconds)",
            placeholder: "30",
            kind: .int(defaultValue: 30),
            validators: [.range(1 ... 300)]
        )

        BooleanSwitchRow(
            id: "sslPinning",
            title: "SSL Certificate Pinning",
            defaultValue: true
        )

        BooleanSwitchRow(
            id: "responseLogging",
            title: "Log All Responses",
            subtitle: "Warning: may expose sensitive data",
            defaultValue: false
        )
    }

    static let featureFlagsForm = FormDefinition(
        id: "debug.featureFlags",
        title: "Feature Flags",
        persistence: FormPersistenceFile(keyPrefix: "DebugMenu")
    ) {
        BooleanSwitchRow(
            id: "newHomeScreen",
            title: "New Home Screen",
            subtitle: "Enables the redesigned home screen layout"
        )

        BooleanSwitchRow(
            id: "experimentalPlayer",
            title: "Experimental Player",
            subtitle: "Uses the new video playback engine"
        )

        BooleanSwitchRow(
            id: "mockAPI",
            title: "Use Mock API",
            defaultValue: false,
            onChange: [
                .showRow(id: "mockDelay", when: [.isTrue(rowId: "mockAPI")])
            ]
        )

        // Mock delay slider — only visible when mock API is enabled.
        NumberInputRow(
            id: "mockDelay",
            title: "Mock API Delay (ms)",
            placeholder: "200",
            kind: .int(defaultValue: 200),
            validators: [.range(0 ... 5000)]
        )
    }

    // MARK: - Root Debug Menu Form

    static let definition = FormDefinition(
        id: "debug.root",
        title: "Debug Menu",
        persistence: FormPersistenceFile(keyPrefix: "DebugMenu")
    ) {
        // Environment picker — drives conditional rows below.
        SingleValueRow<DebugEnvironment>(
            id: "environment",
            title: "Environment",
            defaultValue: .dev,
            onChange: [
                .showRow(id: "logLevel", when: [
                    .or([
                        .equals(rowId: "environment", string: DebugEnvironment.dev.description),
                        .equals(rowId: "environment", string: DebugEnvironment.staging.description)
                    ])
                ]),
                .showRow(id: "verboseLogging", when: [
                    .equals(rowId: "environment", string: DebugEnvironment.dev.description)
                ]),
                .showRow(id: "crashMessage", when: [
                    .notEquals(rowId: "environment", value: .string(DebugEnvironment.prod.description))
                ])
            ]
        )

        // Log level — only shown in dev/staging.
        SingleValueRow<LogLevel>(
            id: "logLevel",
            title: "Log Level",
            defaultValue: .debug
        )

        // Verbose logging toggle — only in dev.
        BooleanSwitchRow(
            id: "verboseLogging",
            title: "Verbose Logging",
            defaultValue: true
        )

        // Force-crash button stub (text input as crash message) — hidden in prod.
        TextInputRow(
            id: "crashMessage",
            title: "Force Crash Message",
            placeholder: "Test crash message"
        )

        // Sub-form navigation rows.
        NavigationRow(
            id: "networkSettings",
            title: "Network Settings",
            subtitle: "Configure API endpoints and timeouts",
            destination: networkSettingsForm
        )

        NavigationRow(
            id: "featureFlags",
            title: "Feature Flags",
            subtitle: "Toggle experimental features",
            destination: featureFlagsForm
        )
    }
}
