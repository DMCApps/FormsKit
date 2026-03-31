import FormsKit

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
            defaultValue: .system,
            onChange: [
                .showRow(id: "fontSize", when: [.notEquals(rowId: "theme", value: .string(AppTheme.system.description))])
            ]
        )

        // Free text for display name with required + minLength validators.
        TextInputRow(
            id: "displayName",
            title: "Display Name",
            placeholder: "Enter your name",
            validators: [
                .required(),
                .minLength(2),
                .maxLength(50)
            ],
            onChange: [
                .showRow(id: "pin", when: [.isNotEmpty(rowId: "displayName")])
            ]
        )

        // Email input with explicit email-format validator.
        TextInputRow(
            id: "contactEmail",
            title: "Contact Email",
            keyboardType: .emailAddress,
            placeholder: "email@example.com",
            validators: [.email(trigger: .onChangeDebounced(seconds: 0.8))]
        )

        // Boolean toggle for notifications.
        BooleanSwitchRow(
            id: "notifications",
            title: "Enable Notifications",
            defaultValue: true,
            onChange: [
                .showRow(id: "notificationCategories", when: [.isTrue(rowId: "notifications")])
            ]
        )

        // Multi-value selection — only visible when notifications are enabled.
        MultiValueRow<NotificationCategory>(
            id: "notificationCategories",
            title: "Notification Categories",
            subtitle: "Select which categories to receive"
        )

        // Number input for font size — only visible when theme is NOT system default.
        NumberInputRow(
            id: "fontSize",
            title: "Font Size",
            placeholder: "16",
            kind: .int(defaultValue: 16),
            validators: [.range(10 ... 32)]
        )

        // Secure password input — visible when display name is not empty.
        TextInputRow(
            id: "pin",
            title: "Account PIN",
            isSecure: true,
            placeholder: "4-digit PIN",
            validators: [
                .regex("^[0-9]{4}$", message: "PIN must be exactly 4 digits", trigger: .onSave)
            ]
        )
    }
}
