import FormKit

// MARK: - Example Enums

enum AppTheme: String, CaseIterable, CustomStringConvertible, Hashable, Sendable, Codable {
    case light, dark, system
    var description: String { rawValue.capitalized }
}

enum NotificationCategory: String, CaseIterable, CustomStringConvertible, Hashable, Sendable, Codable {
    case news, sports, entertainment, breaking
    var description: String { rawValue.capitalized }
}

// MARK: - SettingsForm

/// Demonstrates all row types, conditional rendering, and validators.
/// Persisted via UserDefaults.
enum SettingsForm {
    static let definition = FormDefinition(
        id: "settings",
        title: "Settings",
        persistence: FormPersistenceUserDefaults(keyPrefix: "FormKitExample")
    ) {
        // Single-value picker for app theme.
        SingleValueRow<AppTheme>(
            id: "theme",
            title: "App Theme",
            subtitle: "Choose your preferred colour scheme",
            defaultValue: .system
        )

        // Free text for display name with required + minLength validators.
        TextInputRow(
            id: "displayName",
            title: "Display Name",
            placeholder: "Enter your name",
            isRequired: true,
            validators: [
                .required(),
                .minLength(2),
                .maxLength(50)
            ]
        )

        // Email input (auto email-format validator is injected by EmailInputRow).
        EmailInputRow(
            id: "contactEmail",
            title: "Contact Email",
            isRequired: false,
            validators: [.email(trigger: .onDebouncedInput(seconds: 0.8))]
        )

        // Boolean toggle for notifications.
        BooleanSwitchRow(
            id: "notifications",
            title: "Enable Notifications",
            defaultValue: true
        )

        // Multi-value selection — only visible when notifications are enabled.
        MultiValueRow<NotificationCategory>(
            id: "notificationCategories",
            title: "Notification Categories",
            subtitle: "Select which categories to receive",
            conditions: [.isTrue(rowId: "notifications")]
        )

        // Number input for font size — only visible when theme is NOT system default.
        NumberInputRow(
            id: "fontSize",
            title: "Font Size",
            placeholder: "16",
            kind: .integer,
            defaultValue: 16,
            conditions: [
                .notEquals(rowId: "theme", value: .string(AppTheme.system.description))
            ],
            validators: [.range(10 ... 32)]
        )

        // Secure password input — visible when display name is not empty.
        TextInputRow(
            id: "pin",
            title: "Account PIN",
            placeholder: "4-digit PIN",
            isSecure: true,
            conditions: [.isNotEmpty(rowId: "displayName")],
            validators: [
                .regex("^[0-9]{4}$", message: "PIN must be exactly 4 digits", trigger: .onSave)
            ]
        )
    }
}
