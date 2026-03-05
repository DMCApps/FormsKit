import Foundation

// MARK: - TypedFormDefinition

/// A thin wrapper around `FormDefinition` that binds a specific `RowID` enum,
/// making the `@FormRowBuilder` DSL strongly typed at the call site.
///
/// Define your row IDs as a `String`-backed enum, then build the form using
/// enum cases instead of raw strings:
///
/// ```swift
/// enum SettingsRowID: String {
///     case username, email, notifications, theme
/// }
///
/// let form = TypedFormDefinition<SettingsRowID>(id: "settings", title: "Settings") {
///     TextInputRow(id: .username, title: "Username")
///     EmailInputRow(id: .email, title: "Email")
///     BooleanSwitchRow(id: .notifications, title: "Enable Notifications")
/// }
///
/// // Use with DynamicFormView:
/// DynamicFormView(formDefinition: form.definition, viewModel: myViewModel)
/// ```
///
/// The underlying `FormDefinition` is accessible via `.definition` for use anywhere
/// the untyped API is needed (e.g. `NavigationRow.destination`).
public struct TypedFormDefinition<RowID: RawRepresentable & Sendable>
where RowID.RawValue == String {
    /// The underlying untyped form definition.
    public let definition: FormDefinition

    // MARK: - Initialisers

    /// Create a typed form using the `@FormRowBuilder` DSL.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for this form. Used as the persistence key.
    ///   - title: Display title shown in the navigation bar.
    ///   - persistence: Optional persistence backend.
    ///   - showsSaveButton: Whether to render a Save button. Defaults to `true`.
    ///   - saveButtonTitle: Label for the Save button. Defaults to `"Save"`.
    ///   - rows: Row builder closure — use `RowID` enum cases for the `id:` parameter.
    public init(id: String,
                title: String,
                persistence: (any FormPersistence)? = nil,
                showsSaveButton: Bool = true,
                saveButtonTitle: String = "Save",
                @FormRowBuilder rows: () -> [AnyFormRow]) {
        definition = FormDefinition(
            id: id,
            title: title,
            persistence: persistence,
            showsSaveButton: showsSaveButton,
            saveButtonTitle: saveButtonTitle,
            rows: rows
        )
    }

    /// Create a typed form from a pre-built array of rows.
    public init(id: String,
                title: String,
                rows: [AnyFormRow],
                persistence: (any FormPersistence)? = nil,
                showsSaveButton: Bool = true,
                saveButtonTitle: String = "Save") {
        definition = FormDefinition(
            id: id,
            title: title,
            rows: rows,
            persistence: persistence,
            showsSaveButton: showsSaveButton,
            saveButtonTitle: saveButtonTitle
        )
    }
}

// MARK: - TypedFormViewModel

/// A strongly typed companion to `FormViewModel` that constrains all row ID
/// parameters to a specific `RowID` enum.
///
/// Create one from a `TypedFormDefinition` and use enum cases everywhere instead of
/// raw strings:
///
/// ```swift
/// @State private var form = TypedFormViewModel<SettingsRowID>(form: settingsForm)
///
/// // Read values:
/// let name: String? = form.value(for: .username)
///
/// // Write values:
/// form.setBool(true, for: .notifications)
///
/// // Pass to DynamicFormView — use form.viewModel for observable state in SwiftUI:
/// DynamicFormView(formDefinition: settingsForm.definition, viewModel: form.viewModel)
///
/// // Observe state directly on viewModel in SwiftUI bodies:
/// form.viewModel.isDirty
/// form.viewModel.isSaving
/// form.viewModel.isValid
/// ```
///
/// - Note: `TypedFormViewModel` is not itself `@Observable`. Observable state lives on
///   `viewModel` (which is `@Observable`). Access `form.viewModel.xyz` in SwiftUI views
///   to get automatic updates. Use `TypedFormViewModel` methods for all mutations.
public final class TypedFormViewModel<RowID: RawRepresentable & Sendable>
where RowID.RawValue == String {
    // MARK: - Underlying ViewModel

    /// The observable view model. Use this for SwiftUI state observation and with `DynamicFormView`.
    public let viewModel: FormViewModel

    // MARK: - Initialisers

    /// Create a typed view model from a `TypedFormDefinition`.
    public init(form: TypedFormDefinition<RowID>,
                initialValues: FormValueStore? = nil,
                persistence: (any FormPersistence)? = nil) {
        viewModel = FormViewModel(
            formDefinition: form.definition,
            initialValues: initialValues,
            persistence: persistence
        )
    }

    /// Create a typed view model directly from a plain `FormDefinition`.
    public init(formDefinition: FormDefinition,
                initialValues: FormValueStore? = nil,
                persistence: (any FormPersistence)? = nil) {
        viewModel = FormViewModel(
            formDefinition: formDefinition,
            initialValues: initialValues,
            persistence: persistence
        )
    }

    // MARK: - Value Reading

    /// Returns a typed value for the given row ID.
    public func value<T>(for rowId: RowID) -> T? {
        viewModel.value(for: rowId.rawValue)
    }

    /// Returns the raw `AnyCodableValue` for the given row ID.
    public func rawValue(for rowId: RowID) -> AnyCodableValue? {
        viewModel.rawValue(for: rowId.rawValue)
    }

    // MARK: - Value Writing

    /// Set a raw `AnyCodableValue` for a row.
    public func setValue(_ value: AnyCodableValue?, for rowId: RowID) {
        viewModel.setValue(value, for: rowId.rawValue)
    }

    /// Convenience: set a `Bool` value.
    public func setBool(_ value: Bool, for rowId: RowID) {
        viewModel.setBool(value, for: rowId.rawValue)
    }

    /// Convenience: set a `String` value.
    public func setString(_ value: String, for rowId: RowID) {
        viewModel.setString(value, for: rowId.rawValue)
    }

    /// Convenience: set an `Int` value.
    public func setInt(_ value: Int, for rowId: RowID) {
        viewModel.setInt(value, for: rowId.rawValue)
    }

    /// Convenience: set a `Double` value.
    public func setDouble(_ value: Double, for rowId: RowID) {
        viewModel.setDouble(value, for: rowId.rawValue)
    }

    /// Toggle an element in a multi-value array row.
    public func toggleArrayValue(_ value: AnyCodableValue, for rowId: RowID) {
        viewModel.toggleArrayValue(value, for: rowId.rawValue)
    }

    // MARK: - Validation

    /// Runs all `.onSave` validators and required-field checks.
    /// - Returns: `true` if no errors were found.
    @discardableResult
    public func validateAll() -> Bool {
        viewModel.validateAll()
    }

    /// Returns the validation errors for a specific row.
    public func errorsForRow(_ rowId: RowID) -> [String] {
        viewModel.errorsForRow(rowId.rawValue)
    }

    /// True if the row currently has validation errors.
    public func rowHasError(_ rowId: RowID) -> Bool {
        viewModel.rowHasError(rowId.rawValue)
    }

    // MARK: - Persistence

    /// Validate and persist the current values.
    /// - Returns: `true` if validation passed and persistence succeeded (or no persistence).
    @discardableResult
    public func save() async -> Bool {
        await viewModel.save()
    }

    /// Load persisted values, merging over row defaults.
    public func loadFromPersistence() async {
        await viewModel.loadFromPersistence()
    }

    /// Clear persisted data for this form.
    public func clearPersistence() async {
        await viewModel.clearPersistence()
    }

    // MARK: - Reset

    /// Reset all values to their row defaults and clear all errors.
    public func reset() {
        viewModel.reset()
    }
}
