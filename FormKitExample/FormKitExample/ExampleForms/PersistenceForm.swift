import FormKit

// MARK: - PersistenceForm

/// Demonstrates the three FormPersistence backends:
/// in-memory, UserDefaults, and file-based.
enum PersistenceForm {
    static let definition = FormDefinition(
        id: "persistence",
        title: "Persistence",
        saveBehaviour: .none
    ) {
        InfoRow(id: "intro", title: "How to use") {
            "Each row below opens a sub-form backed by a different persistence strategy."
        }

        FormSection(id: "backendsSection", title: "Backends") {
            // MARK: In-memory

            NavigationRow(
                id: "memoryExample",
                title: "FormPersistenceMemory",
                subtitle: "Transient — values are lost when you leave the form",
                destination: FormDefinition(
                    id: "persistence.memory",
                    title: "In-Memory",
                    persistence: FormPersistenceMemory(),
                    saveBehaviour: .buttonNavigationBar()
                ) {
                    InfoRow(id: "hint", title: "Backend") { "FormPersistenceMemory" }
                    InfoRow(id: "hint2", title: "Behaviour") { "Values survive the session but are cleared when the app restarts or the form is re-created" }

                    TextInputRow(id: "name", title: "Name", placeholder: "Enter your name")
                    TextInputRow(id: "notes", title: "Notes", placeholder: "Optional notes")
                    BooleanSwitchRow(id: "enabled", title: "Feature enabled")
                }
            )

            // MARK: UserDefaults

            NavigationRow(
                id: "userDefaultsExample",
                title: "FormPersistenceUserDefaults",
                subtitle: "Persisted — values survive app restarts via UserDefaults",
                destination: FormDefinition(
                    id: "persistence.userDefaults",
                    title: "UserDefaults",
                    persistence: FormPersistenceUserDefaults(keyPrefix: "FormKitExample"),
                    saveBehaviour: .buttonNavigationBar()
                ) {
                    InfoRow(id: "hint", title: "Backend") { "FormPersistenceUserDefaults" }
                    InfoRow(id: "hint2", title: "Behaviour") { "Values are JSON-encoded and stored in UserDefaults. They survive app restarts." }

                    TextInputRow(id: "username", title: "Username", placeholder: "Enter a username")
                    TextInputRow(id: "serverUrl", title: "Server URL", placeholder: "https://api.example.com", keyboardType: .url)
                    BooleanSwitchRow(id: "analyticsEnabled", title: "Analytics enabled", defaultValue: true)
                    SingleValueRow<LogLevel>(id: "logLevel", title: "Log level", defaultValue: .warning)
                }
            )

            // MARK: File-based

            NavigationRow(
                id: "fileExample",
                title: "FormPersistenceFile",
                subtitle: "Persisted — values are written to a JSON file on disk",
                destination: FormDefinition(
                    id: "persistence.file",
                    title: "File",
                    persistence: FormPersistenceFile(keyPrefix: "FormKitExample"),
                    saveBehaviour: .buttonNavigationBar()
                ) {
                    InfoRow(id: "hint", title: "Backend") { "FormPersistenceFile" }
                    InfoRow(id: "hint2", title: "Location") { "<Application Support>/FormKit/" }
                    InfoRow(id: "hint3", title: "Behaviour") { "Values are JSON-encoded and written to a file. They survive app restarts." }

                    TextInputRow(id: "token", title: "API Token", placeholder: "Enter a token", isSecure: true)
                    TextInputRow(id: "environment", title: "Environment", placeholder: "e.g. staging")
                    NumberInputRow(id: "timeout", title: "Timeout (s)", placeholder: "30", kind: .int(defaultValue: 30))
                    BooleanSwitchRow(id: "verbose", title: "Verbose logging")
                }
            )
        }

        // MARK: Auto-save variant

        FormSection(id: "autoSaveSection", title: "Auto-save with UserDefaults") {
            NavigationRow(
                id: "autoSaveUserDefaults",
                title: "onChange + UserDefaults",
                subtitle: "Every change is immediately persisted — no Save button",
                destination: FormDefinition(
                    id: "persistence.autoSaveUD",
                    title: "Auto-save",
                    persistence: FormPersistenceUserDefaults(keyPrefix: "FormKitAutoSave"),
                    saveBehaviour: .onChange
                ) {
                    InfoRow(id: "hint", title: "Save trigger") { "Every value change" }
                    TextInputRow(id: "quickNote", title: "Quick note", placeholder: "Saved instantly as you type…")
                    BooleanSwitchRow(id: "quickToggle", title: "A toggle (auto-saved)")
                }
            )
        }
    }
}

// MARK: - Support types

private enum LogLevel: String, CaseIterable, CustomStringConvertible, Hashable, Sendable, Codable {
    case verbose, debug, info, warning, error
    var description: String { rawValue.capitalized }
}
