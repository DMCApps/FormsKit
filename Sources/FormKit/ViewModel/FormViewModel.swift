import Foundation
import Observation

// MARK: - FormViewModel

/// The observable view model that drives all form state.
/// Pass an instance of this class into `DynamicFormView` to read form values
/// from outside the view hierarchy after the user interacts with the form.
///
/// Create and retain a `FormViewModel` externally to access values after save:
/// ```swift
/// @State private var viewModel = FormViewModel(formDefinition: myForm)
///
/// DynamicFormView(formDefinition: myForm, viewModel: viewModel)
///
/// // Later:
/// let name: String? = viewModel.value(for: "name")
/// ```
@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
@Observable
public final class FormViewModel {
    // MARK: - Observable State

    /// Current form values, keyed by row ID.
    public private(set) var values: FormValueStore

    /// Validation errors keyed by row ID.
    /// An empty array means the row has no current errors.
    public private(set) var errors: [String: [String]] = [:]

    /// True when there are no validation errors across all visible rows.
    public var isValid: Bool {
        errors.values.allSatisfy(\.isEmpty)
    }

    /// True while an async save is in progress.
    public private(set) var isSaving: Bool = false

    /// The most recent save error, if any.
    public private(set) var saveError: Error?

    /// True when any value has changed since the last successful save or load.
    public private(set) var isDirty: Bool = false

    // MARK: - Private State

    public let formDefinition: FormDefinition
    private let persistence: (any FormPersistence)?

    /// Called after a successful save with the final form values.
    /// Use this to react to the save event without subclassing the view model.
    public var onSave: ((FormValueStore) -> Void)?

    /// Cancellable debounce tasks keyed by row ID (for debounced validators).
    private var debounceTimers: [String: Task<Void, Never>] = [:]

    /// Cancellable debounce tasks for row actions, keyed by a composite key of rowId + actionIndex.
    private var actionDebounceTimers: [String: Task<Void, Never>] = [:]

    // MARK: - Initialisation

    /// - Parameters:
    ///   - formDefinition: The form to manage.
    ///   - persistence: Override persistence backend.
    ///     Falls back to `formDefinition.persistence` if nil.
    ///   - onSave: Optional closure called after a successful save with the final form values.
    public init(formDefinition: FormDefinition,
                persistence: (any FormPersistence)? = nil,
                onSave: ((FormValueStore) -> Void)? = nil) {
        self.formDefinition = formDefinition
        let resolvedPersistence = persistence ?? formDefinition.persistence
        self.persistence = resolvedPersistence

        // Load persisted values synchronously if the backend supports it.
        // This ensures that `value(for:)` calls made before the view appears
        // (e.g. from ViewModel computed properties) return the stored value,
        // not the row default.
        let persisted: FormValueStore = if let syncPersistence = resolvedPersistence as? any FormSynchronousPersistence {
            syncPersistence.loadSynchronously(formId: formDefinition.id)
        } else {
            FormValueStore()
        }

        // Seed the store with row defaults, then overlay persisted values so
        // stored values always win over defaults.
        var store = FormValueStore()
        for row in formDefinition.rows {
            if let defaultValue = row.defaultValue {
                store[row.id] = defaultValue
            }
        }
        store.merge(persisted)
        values = store
        self.onSave = onSave
    }

    // MARK: - Value Reading

    /// Returns a typed value for the given row ID.
    public func value<T>(for rowId: String) -> T? {
        values.value(for: rowId)
    }

    /// Returns the raw `AnyCodableValue` for the given row ID.
    public func rawValue(for rowId: String) -> AnyCodableValue? {
        values[rowId]
    }

    // MARK: - Value Writing

    /// Set a raw `AnyCodableValue` for a row, triggering applicable validators and actions.
    public func setValue(_ value: AnyCodableValue?, for rowId: String) {
        values[rowId] = value
        isDirty = true
        // Clear stale errors so the UI updates immediately.
        errors[rowId] = []
        // Fire onChange validators.
        runValidators(for: rowId, trigger: .onChange)
        // Schedule debounced validators.
        scheduleDebouncedValidation(for: rowId)
        // Dispatch row actions declared on the changed row.
        dispatchActions(for: rowId)
        // Auto-save when the form is configured to save on every change.
        if case .onChange = formDefinition.saveBehaviour {
            let capturedSelf = self
            Task { await capturedSelf.save() }
        }
    }

    /// Convenience: set a `Bool` value.
    public func setBool(_ value: Bool, for rowId: String) {
        setValue(.bool(value), for: rowId)
    }

    /// Convenience: set a `String` value.
    public func setString(_ value: String, for rowId: String) {
        setValue(.string(value), for: rowId)
    }

    /// Convenience: set an `Int` value.
    public func setInt(_ value: Int, for rowId: String) {
        setValue(.int(value), for: rowId)
    }

    /// Convenience: set a `Double` value.
    public func setDouble(_ value: Double, for rowId: String) {
        setValue(.double(value), for: rowId)
    }

    /// Toggle an element in a multi-value array row.
    /// Adds the element if absent, removes it if present.
    public func toggleArrayValue(_ value: AnyCodableValue, for rowId: String) {
        var current: [AnyCodableValue] = if case let .array(arr) = values[rowId] {
            arr
        } else {
            []
        }
        if let idx = current.firstIndex(of: value) {
            current.remove(at: idx)
        } else {
            current.append(value)
        }
        setValue(.array(current), for: rowId)
    }

    // MARK: - Visibility

    /// Returns true if the given row should be visible.
    ///
    /// Visibility is controlled by `.showRow` actions on *other* rows.
    /// If no row in the form has a `.showRow` action targeting this row's ID,
    /// the row is always visible. Otherwise it is visible when at least one
    /// `.showRow` action targeting it has all its conditions satisfied.
    public func isRowVisible(_ row: AnyFormRow) -> Bool {
        // Collect all .showRow actions across the form that target this row.
        let showActions = formDefinition.rows.flatMap { sourceRow in
            sourceRow.onChange.compactMap { action -> [FormCondition]? in
                if case let .showRow(targetId, conditions, _) = action, targetId == row.id {
                    return conditions
                }
                return nil
            }
        }

        // No .showRow actions point at this row → always visible.
        guard !showActions.isEmpty else { return true }

        // Visible if ANY showRow action has all its conditions satisfied.
        return showActions.contains { conditions in
            conditions.isEmpty || conditions.allSatisfy { $0.evaluate(with: values) }
        }
    }

    /// All rows from the form definition that are currently visible.
    public var visibleRows: [AnyFormRow] {
        formDefinition.rows.filter { isRowVisible($0) }
    }

    // MARK: - Validation

    /// Runs all `.onSave` validators for visible rows and checks required fields.
    /// - Returns: `true` if no errors were found; `false` otherwise.
    @discardableResult
    public func validateAll() -> Bool {
        var newErrors: [String: [String]] = [:]

        for row in formDefinition.rows where isRowVisible(row) {
            var rowErrors: [String] = []

            // User-supplied .onSave validators.
            let validatorErrors = row.validators
                .filter { $0.trigger == .onSave }
                .compactMap { $0.validate(values[row.id]) }
            rowErrors.append(contentsOf: validatorErrors)

            if !rowErrors.isEmpty {
                newErrors[row.id] = rowErrors
            }
        }

        errors = newErrors
        return newErrors.values.allSatisfy(\.isEmpty)
    }

    // MARK: - Save

    /// Validate and persist the current values.
    /// - Returns: `true` if validation passed and persistence succeeded (or no persistence).
    @discardableResult
    public func save() async -> Bool {
        guard validateAll() else { return false }

        guard let persistence else {
            isDirty = false
            onSave?(values)
            dispatchOnSaveActions()
            return true
        }

        isSaving = true
        saveError = nil

        do {
            try await persistence.save(values, formId: formDefinition.id)
            isDirty = false
            isSaving = false
            onSave?(values)
            dispatchOnSaveActions()
            return true
        } catch {
            saveError = error
            isSaving = false
            return false
        }
    }

    // MARK: - Load

    /// Load persisted values, merging over row defaults.
    /// No-op if no persistence backend is configured.
    public func loadFromPersistence() async {
        guard let persistence else { return }
        do {
            let loaded = try await persistence.load(formId: formDefinition.id)
            var store = FormValueStore()
            for row in formDefinition.rows {
                if let defaultValue = row.defaultValue {
                    store[row.id] = defaultValue
                }
            }
            store.merge(loaded)
            values = store
            isDirty = false
            errors = [:]
        } catch {
            saveError = error
        }
    }

    // MARK: - Reset

    /// Reset all values to their row defaults and clear all errors.
    public func reset() {
        var store = FormValueStore()
        for row in formDefinition.rows {
            if let defaultValue = row.defaultValue {
                store[row.id] = defaultValue
            }
        }
        values = store
        errors = [:]
        isDirty = false
        saveError = nil
        // Cancel all pending debounce timers.
        debounceTimers.values.forEach { $0.cancel() }
        debounceTimers = [:]
        actionDebounceTimers.values.forEach { $0.cancel() }
        actionDebounceTimers = [:]
    }

    /// Clears the most recent save error. Call this when dismissing a save-failure alert.
    public func clearSaveError() {
        saveError = nil
    }

    /// Clear persisted data for this form.
    public func clearPersistence() async {
        guard let persistence else { return }
        try? await persistence.clear(formId: formDefinition.id)
    }

    // MARK: - Error Helpers

    /// Returns the validation errors for a specific row.
    public func errorsForRow(_ rowId: String) -> [String] {
        errors[rowId] ?? []
    }

    /// True if the row currently has validation errors.
    public func rowHasError(_ rowId: String) -> Bool {
        !(errors[rowId]?.isEmpty ?? true)
    }

    // MARK: - RawRepresentable Row ID Overloads

    /// Returns a typed value for the given row ID (enum case overload).
    public func value<T, ID: RawRepresentable>(for rowId: ID) -> T? where ID.RawValue == String {
        value(for: rowId.rawValue)
    }

    /// Returns the raw `AnyCodableValue` for the given row ID (enum case overload).
    public func rawValue<ID: RawRepresentable>(for rowId: ID) -> AnyCodableValue? where ID.RawValue == String {
        rawValue(for: rowId.rawValue)
    }

    /// Set a raw `AnyCodableValue` for a row (enum case overload).
    public func setValue(_ value: AnyCodableValue?, for rowId: some RawRepresentable<String>) {
        setValue(value, for: rowId.rawValue)
    }

    /// Convenience: set a `Bool` value (enum case overload).
    public func setBool(_ value: Bool, for rowId: some RawRepresentable<String>) {
        setBool(value, for: rowId.rawValue)
    }

    /// Convenience: set a `String` value (enum case overload).
    public func setString(_ value: String, for rowId: some RawRepresentable<String>) {
        setString(value, for: rowId.rawValue)
    }

    /// Convenience: set an `Int` value (enum case overload).
    public func setInt(_ value: Int, for rowId: some RawRepresentable<String>) {
        setInt(value, for: rowId.rawValue)
    }

    /// Convenience: set a `Double` value (enum case overload).
    public func setDouble(_ value: Double, for rowId: some RawRepresentable<String>) {
        setDouble(value, for: rowId.rawValue)
    }

    /// Toggle an element in a multi-value array row (enum case overload).
    public func toggleArrayValue(_ value: AnyCodableValue, for rowId: some RawRepresentable<String>) {
        toggleArrayValue(value, for: rowId.rawValue)
    }

    /// Returns the validation errors for a specific row (enum case overload).
    public func errorsForRow(_ rowId: some RawRepresentable<String>) -> [String] {
        errorsForRow(rowId.rawValue)
    }

    /// True if the row currently has validation errors (enum case overload).
    public func rowHasError(_ rowId: some RawRepresentable<String>) -> Bool {
        rowHasError(rowId.rawValue)
    }

    // MARK: - Private Helpers

    /// Run all validators matching the given trigger for a specific row.
    private func runValidators(for rowId: String, trigger: ValidationTrigger) {
        guard let row = formDefinition.rows.first(where: { $0.id == rowId }) else { return }
        let rowErrors = row.validators
            .filter { $0.trigger == trigger }
            .compactMap { $0.validate(values[rowId]) }
        errors[rowId] = rowErrors
    }

    /// Schedule debounced validation for a row.
    /// Uses the longest debounce interval among all debounced validators for the row.
    private func scheduleDebouncedValidation(for rowId: String) {
        guard let row = formDefinition.rows.first(where: { $0.id == rowId }) else { return }

        let debouncedValidators = row.validators.filter(\.trigger.isDebouncedInput)
        guard !debouncedValidators.isEmpty else { return }

        let maxDelay = debouncedValidators
            .compactMap(\.trigger.debounceDuration)
            .max() ?? 0.5

        // Cancel any existing timer for this row.
        debounceTimers[rowId]?.cancel()

        let capturedSelf = self
        debounceTimers[rowId] = Task {
            try? await Task.sleep(for: .seconds(maxDelay))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                capturedSelf.runDebouncedValidators(for: rowId)
            }
        }
    }

    /// Fire all debounced validators for a row (called after the debounce delay).
    @MainActor
    private func runDebouncedValidators(for rowId: String) {
        guard let row = formDefinition.rows.first(where: { $0.id == rowId }) else { return }
        let rowErrors = row.validators
            .filter(\.trigger.isDebouncedInput)
            .compactMap { $0.validate(values[rowId]) }
        errors[rowId] = rowErrors
    }

    /// Dispatch all onChange actions declared on the row with the given ID.
    /// Immediate actions fire synchronously; debounced actions are scheduled via a Task.
    private func dispatchActions(for rowId: String) {
        guard let row = formDefinition.rows.first(where: { $0.id == rowId }) else { return }

        let onChangeActions = row.onChange.enumerated().filter(\.element.isOnChangeAction)

        for (index, action) in onChangeActions {
            let timing = action.timing ?? .immediate

            if timing.debounce == nil {
                // Immediate — fire now.
                executeAction(action, rowId: rowId)
            } else {
                // Debounced — cancel any pending task for this action slot and reschedule.
                let timerKey = "\(rowId)_\(index)"
                actionDebounceTimers[timerKey]?.cancel()

                let delay = timing.debounce ?? 0.5
                let capturedSelf = self
                actionDebounceTimers[timerKey] = Task {
                    try? await Task.sleep(for: .seconds(delay))
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        capturedSelf.executeAction(action, rowId: rowId)
                    }
                }
            }
        }
    }

    /// Execute a single `FormRowAction` against the current form state.
    private func executeAction(_ action: FormRowAction, rowId: String) {
        switch action {
        case .showRow:
            // Show/hide is evaluated reactively via isRowVisible — no imperative state to update.
            break

        case let .setValue(targetRowId, _, valueFactory):
            // Derive the new value from the current store and apply it if non-nil.
            // Use the internal setter to avoid triggering a full action dispatch cycle on the target.
            if let newValue = valueFactory(values) {
                values[targetRowId] = newValue
                isDirty = true
                errors[targetRowId] = []
            }

        case .runValidation:
            runValidators(for: rowId, trigger: .onChange)
            scheduleDebouncedValidation(for: rowId)

        case let .custom(_, handler):
            handler(values, rowId)

        case .onSave:
            // onSave actions are dispatched from save(), not here.
            break
        }
    }

    /// Fire all `.onSave` actions across every row in the form.
    private func dispatchOnSaveActions() {
        for row in formDefinition.rows {
            for action in row.onChange {
                if case let .onSave(handler) = action {
                    handler(values)
                }
            }
        }
    }
}
