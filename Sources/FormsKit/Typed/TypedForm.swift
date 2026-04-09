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
///     TextInputRow(id: .email, title: "Email")
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
    ///   - saveBehaviour: Controls when and how form values are saved. Defaults to `.buttonBottomForm()`.
    ///   - onSave: Actions that fire after the form is successfully saved.
    ///   - loadingStyle: Controls what is displayed while values are loading. Defaults to `.activityIndicator`.
    ///   - theme: Optional theme to apply to this form.
    ///   - rows: Row builder closure — use `RowID` enum cases for the `id:` parameter.
    public init(id: String,
                title: String,
                persistence: (any FormPersistence)? = nil,
                saveBehaviour: FormSaveBehaviour = .buttonBottomForm(),
                onSave: [FormSaveAction] = [],
                loadingStyle: FormLoadingStyle = .activityIndicator,
                theme: FormTheme? = nil,
                @FormRowBuilder rows: () -> [AnyFormRow]) {
        definition = FormDefinition(
            id: id,
            title: title,
            persistence: persistence,
            saveBehaviour: saveBehaviour,
            onSave: onSave,
            loadingStyle: loadingStyle,
            theme: theme,
            rows: rows
        )
    }

    /// Create a typed form from a pre-built array of rows.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for this form. Used as the persistence key.
    ///   - title: Display title shown in the navigation bar.
    ///   - rows: Pre-built array of rows.
    ///   - persistence: Optional persistence backend.
    ///   - saveBehaviour: Controls when and how form values are saved. Defaults to `.buttonBottomForm()`.
    ///   - onSave: Actions that fire after the form is successfully saved.
    ///   - loadingStyle: Controls what is displayed while values are loading. Defaults to `.activityIndicator`.
    ///   - theme: Optional theme to apply to this form.
    public init(id: String,
                title: String,
                rows: [AnyFormRow],
                persistence: (any FormPersistence)? = nil,
                saveBehaviour: FormSaveBehaviour = .buttonBottomForm(),
                onSave: [FormSaveAction] = [],
                loadingStyle: FormLoadingStyle = .activityIndicator,
                theme: FormTheme? = nil) {
        definition = FormDefinition(
            id: id,
            title: title,
            rows: rows,
            persistence: persistence,
            saveBehaviour: saveBehaviour,
            onSave: onSave,
            loadingStyle: loadingStyle,
            theme: theme
        )
    }
}

// MARK: - TypedFormViewModel

/// A strongly typed companion to `FormViewModel` that constrains all row ID
/// parameters to a specific `RowID` enum.
///
/// ## Loading contract
///
/// When a persistence backend is configured, initialisation kicks off an async load
/// in the background. Always call `awaitReady()` before reading values
/// programmatically — values available before that point reflect row defaults only:
///
/// ```swift
/// let form = TypedFormViewModel<SettingsRowID>(form: settingsForm)
/// await form.awaitReady()
/// let name: String? = form.value(for: .username)  // guaranteed to be the persisted value
/// ```
///
/// When using `DynamicFormView` this is handled automatically.
///
/// ## Usage
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
    ///
    /// - Parameters:
    ///   - form: The typed form definition. Set `form.definition.persistence` to configure
    ///     the persistence backend.
    public init(form: TypedFormDefinition<RowID>) {
        viewModel = FormViewModel(formDefinition: form.definition)
    }

    /// Create a typed view model directly from a plain `FormDefinition`.
    ///
    /// - Parameters:
    ///   - formDefinition: The form definition. Set `formDefinition.persistence` to configure
    ///     the persistence backend.
    public init(formDefinition: FormDefinition) {
        viewModel = FormViewModel(formDefinition: formDefinition)
    }

    // MARK: - Value Reading

    /// Returns a typed value for the given row ID.
    public func value<T: Decodable>(for rowId: RowID) -> T? {
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

    /// Runs all `.onSave` validators for visible rows.
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

    /// Notify the view model that a field has lost focus.
    ///
    /// Runs all `.onBlur` validators for the given row and updates `errors`.
    public func rowDidBlur(_ rowId: RowID) {
        viewModel.rowDidBlur(rowId.rawValue)
    }

    /// Error messages that should be displayed at the top of the form, above all rows.
    public var formTopErrors: [String] { viewModel.formTopErrors }

    /// Error messages that should be displayed at the bottom of the form, above the save button.
    public var formBottomErrors: [String] { viewModel.formBottomErrors }

    /// Error messages that should be surfaced in a dismissible alert dialog.
    public var alertErrors: [String] { viewModel.alertErrors }

    // MARK: - Persistence

    /// Validate and persist the current values.
    /// - Returns: `true` if validation passed and persistence succeeded (or no persistence).
    @MainActor
    @discardableResult
    public func save() async -> Bool {
        await viewModel.save()
    }

    /// Load persisted values, merging over row defaults.
    @MainActor
    public func loadFromPersistence() async {
        await viewModel.loadFromPersistence()
    }

    /// Suspends until the form has finished loading from persistence (i.e. `status` is
    /// `.ready` or `.loadFailed`). Returns immediately if there is no persistence backend
    /// or if loading has already completed.
    ///
    /// If the in-flight load was cancelled (e.g. by a concurrent `reset()`), this will
    /// join the replacement task that `reset()` starts, ensuring the caller always waits
    /// for a complete load rather than returning with stale state.
    ///
    /// Use this when you need the final persisted values outside of a SwiftUI view
    /// — for example, reading configuration during app startup.
    @MainActor
    public func awaitReady() async {
        await viewModel.awaitReady()
    }

    /// Clear persisted data for this form.
    @MainActor
    public func clearPersistence() async {
        await viewModel.clearPersistence()
    }

    // MARK: - Reset

    /// Reset all values to their row defaults and clear all errors.
    ///
    /// Any unsaved changes are discarded. If a persistence backend is configured,
    /// a reload from storage is kicked off immediately and `save()` is blocked
    /// until it completes.
    public func reset() {
        viewModel.reset()
    }
}
