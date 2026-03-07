import Foundation
import Observation

// MARK: - FormStatus

/// Represents the mutually exclusive lifecycle states of a `FormViewModel`.
///
/// Use this to drive loading indicators and button disabled states in your UI:
/// ```swift
/// switch viewModel.status {
/// case .needsLoad, .loading: ProgressView()
/// case .ready:               FormContentView()
/// case .saving:              FormContentView().disabled(true)
/// case .loadFailed(let err): ErrorView(error: err)
/// }
/// ```
public enum FormStatus: Equatable, Sendable {
    /// The form has been initialised but the async load from persistence has not yet started.
    /// Transitions to `.loading` once `loadFromPersistence()` is called.
    case needsLoad
    /// The async load from persistence is in flight.
    case loading
    /// Values are loaded and the form is ready for interaction.
    case ready
    /// A save operation is currently in progress.
    case saving
    /// The load from persistence failed. The form is showing default values only.
    /// The associated error describes what went wrong.
    /// Call `loadFromPersistence()` again to retry.
    case loadFailed(Error)

    /// True when the status is `.loadFailed`, regardless of the associated error.
    public var isLoadFailed: Bool {
        if case .loadFailed = self { return true }
        return false
    }

    public static func == (lhs: FormStatus, rhs: FormStatus) -> Bool {
        switch (lhs, rhs) {
        case (.needsLoad, .needsLoad): return true
        case (.loading, .loading): return true
        case (.ready, .ready): return true
        case (.saving, .saving): return true
        case (.loadFailed, .loadFailed): return true
        default: return false
        }
    }
}

// MARK: - FormValidationError

/// Errors that can be surfaced by `FormViewModel` during a save attempt.
public enum FormValidationError: LocalizedError {
    /// The form has live validation errors that must be fixed before saving.
    case hasLiveErrors

    public var errorDescription: String? {
        switch self {
        case .hasLiveErrors:
            return "Please fix the form errors before saving."
        }
    }
}

// MARK: - FormError

/// A single validation error produced by a `FormValidator`, capturing both the
/// error message and the position in the form UI where it should be displayed.
public struct FormError: Sendable, Equatable {
    /// The human-readable error message.
    public let message: String

    /// Where in the form UI this error should be displayed.
    public let position: ErrorPosition

    public init(message: String, position: ErrorPosition) {
        self.message = message
        self.position = position
    }
}

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
    /// Each entry is a `FormError` capturing the message and its display position.
    /// An empty array means the row has no current errors.
    public private(set) var errors: [String: [FormError]] = [:]

    /// True when there are no validation errors across all visible rows.
    /// Hidden rows are excluded — their errors do not count against form validity.
    public var isValid: Bool {
        let visibleRowIds = Set(allRows.filter { isRowVisible($0) }.map(\.id))
        return errors.allSatisfy { key, rowErrors in
            !visibleRowIds.contains(key) || rowErrors.isEmpty
        }
    }

    /// Error messages that should be displayed at the top of the form, above all rows.
    public var formTopErrors: [String] {
        errors.values.flatMap { $0 }
            .filter { $0.position == .formTop }
            .map(\.message)
    }

    /// Error messages that should be displayed at the bottom of the form, above the save button.
    public var formBottomErrors: [String] {
        errors.values.flatMap { $0 }
            .filter { $0.position == .formBottom }
            .map(\.message)
    }

    /// Error messages that should be surfaced in a dismissible alert dialog.
    public var alertErrors: [String] {
        errors.values.flatMap { $0 }
            .filter { $0.position == .alert }
            .map(\.message)
    }

    /// The current lifecycle state of the form.
    /// Use this to drive loading indicators and disable the save button during saves.
    public private(set) var status: FormStatus = .needsLoad

    /// The most recent save error, if any.
    public private(set) var saveError: Error?

    /// True when any value has changed since the last successful save or load.
    public private(set) var isDirty: Bool = false

    // MARK: - Private State

    public let formDefinition: FormDefinition
    private let persistence: (any FormPersistence)?

    /// Cancellable debounce tasks keyed by row ID (for debounced validators).
    private var debounceTimers: [String: Task<Void, Never>] = [:]

    /// Cancellable debounce tasks for row actions, keyed by a composite key of rowId + actionIndex.
    private var actionDebounceTimers: [String: Task<Void, Never>] = [:]

    /// Row IDs currently being processed by `dispatchActions`. Used to prevent re-entrant
    /// dispatch on the same row (e.g. a `.custom` action that calls `setValue` back on the
    /// same row, which would otherwise cause unbounded recursion).
    private var dispatchingRows: Set<String> = []

    /// All leaf rows in the form, flattened from nested sections. Immutable for the
    /// lifetime of the view model — safe because `FormDefinition.rows` is a `let`.
    private let allRows: [AnyFormRow]

    // MARK: - Initialisation

    /// - Parameters:
    ///   - formDefinition: The form to manage.
    ///   - persistence: Override persistence backend.
    ///     Falls back to `formDefinition.persistence` if nil.
    public init(formDefinition: FormDefinition,
                persistence: (any FormPersistence)? = nil) {
        self.formDefinition = formDefinition
        let resolvedPersistence = persistence ?? formDefinition.persistence
        self.persistence = resolvedPersistence

        // Flatten once here — used to seed defaults and then stored as `allRows`.
        let flatRows = FormViewModel.allRows(in: formDefinition.rows)
        allRows = flatRows

        // Seed the store with row defaults. Persisted values are loaded
        // asynchronously below so that all persistence backends (sync or async)
        // are handled uniformly, and callers never need to manage a separate load call.
        var store = FormValueStore()
        for row in flatRows {
            if let defaultValue = row.defaultValue {
                store[row.id] = defaultValue
            }
        }
        values = store

        // Kick off the async load. `status` starts as `.needsLoad` and transitions
        // to `.loading` → `.ready` (or `.loadFailed`) once the load completes.
        // `loadFromPersistence()` dispatches its own state mutations onto the
        // MainActor internally, so the Task itself doesn't need to run there.
        Task { [weak self] in await self?.loadFromPersistence() }
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
            Task { [weak self] in await self?.save() }
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

    /// Convenience: set a `Date` value.
    public func setDate(_ value: Date, for rowId: String) {
        setValue(.date(value), for: rowId)
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
    ///
    /// If the row is a child of a `FormSection`, the section's own visibility
    /// is checked first — a hidden section hides all its children regardless
    /// of any actions targeting those children directly.
    public func isRowVisible(_ row: AnyFormRow) -> Bool {
        // If this row lives inside a section, check the section's visibility first.
        if let parentSection = parentSection(of: row.id, in: formDefinition.rows) {
            guard isRowVisible(parentSection) else { return false }
        }

        // Collect all .showRow actions across ALL rows (including section children)
        // that target this row.
        let showActions = allRows.flatMap { sourceRow in
            sourceRow.onChange.compactMap { action -> [FormCondition]? in
                if case let .showRow(targetId, conditions, _) = action, targetId == row.id {
                    return conditions
                }
                return nil
            }
        }

        // Collect all .hideRow actions targeting this row.
        let hideActions = allRows.flatMap { sourceRow in
            sourceRow.onChange.compactMap { action -> [FormCondition]? in
                if case let .hideRow(targetId, conditions, _) = action, targetId == row.id {
                    return conditions
                }
                return nil
            }
        }

        // If any hideRow action has all its conditions satisfied, hide the row.
        let isHidden = hideActions.contains { conditions in
            conditions.isEmpty || conditions.allSatisfy { $0.evaluate(with: values) }
        }
        if isHidden { return false }

        // No .showRow actions point at this row → always visible (unless hidden above).
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

    /// Returns true if the given row is currently disabled.
    ///
    /// Disabled state is controlled by `.disableRow` actions on *other* rows.
    /// If no row in the form has a `.disableRow` action targeting this row's ID,
    /// the row is always enabled. Otherwise it is disabled when at least one
    /// `.disableRow` action targeting it has all its conditions satisfied.
    ///
    /// If the row's parent section is disabled, all its children are disabled regardless
    /// of any actions targeting those children directly.
    public func isRowDisabled(_ row: AnyFormRow) -> Bool {
        // If this row lives inside a section, check the section's disabled state first.
        if let parentSection = parentSection(of: row.id, in: formDefinition.rows) {
            if isRowDisabled(parentSection) { return true }
        }

        // Collect all .disableRow actions across ALL rows that target this row.
        let disableActions = allRows.flatMap { sourceRow in
            sourceRow.onChange.compactMap { action -> [FormCondition]? in
                if case let .disableRow(targetId, conditions, _) = action, targetId == row.id {
                    return conditions
                }
                return nil
            }
        }

        // No .disableRow actions point at this row → always enabled.
        guard !disableActions.isEmpty else { return false }

        // Disabled if ANY disableRow action has all its conditions satisfied.
        return disableActions.contains { conditions in
            conditions.isEmpty || conditions.allSatisfy { $0.evaluate(with: values) }
        }
    }

    // MARK: - Validation

    /// Validates the form before saving.
    ///
    /// First checks whether any live `.onChange` / debounced errors are already
    /// present for visible rows. If so, returns `false` immediately — the row-level
    /// error UI already tells the user what to fix, so running `.onSave` validators
    /// on top would be redundant.
    ///
    /// If there are no live errors, runs all `.onSave` validators for visible rows
    /// and updates `errors`.
    ///
    /// - Returns: `true` if no errors were found; `false` otherwise.
    @discardableResult
    public func validateAll() -> Bool {
        let visibleRowIds = Set(
            allRows
                .filter { isRowVisible($0) }
                .map(\.id)
        )

        // If any visible row already has live errors, bail out immediately.
        // The existing error UI tells the user what to fix without needing to pile on.
        let hasLiveErrors = errors.contains { visibleRowIds.contains($0.key) && !$0.value.isEmpty }
        if hasLiveErrors { return false }

        // No live errors — run .onSave validators.
        var newErrors: [String: [FormError]] = [:]

        for row in allRows where isRowVisible(row) {
            let validatorErrors = row.validators
                .filter { $0.trigger == .onSave }
                .compactMap { validator -> FormError? in
                    guard let message = validator.validate(values[row.id], values) else { return nil }
                    return FormError(message: message, position: validator.errorPosition)
                }

            if !validatorErrors.isEmpty {
                newErrors[row.id] = validatorErrors
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
        guard status == .ready else { return false }

        // If there are already live errors visible to the user, surface an alert
        // prompting them to fix those before saving rather than silently failing.
        let visibleRowIds = Set(
            allRows
                .filter { isRowVisible($0) }
                .map(\.id)
        )
        let hasLiveErrors = errors.contains { visibleRowIds.contains($0.key) && !$0.value.isEmpty }
        if hasLiveErrors {
            saveError = FormValidationError.hasLiveErrors
            return false
        }

        guard validateAll() else { return false }

        guard let persistence else {
            isDirty = false
            dispatchOnSaveActions()
            return true
        }

        status = .saving
        saveError = nil

        do {
            try await persistence.save(values, formId: formDefinition.id)
            isDirty = false
            status = .ready
            dispatchOnSaveActions()
            return true
        } catch {
            saveError = error
            status = .ready
            return false
        }
    }

    // MARK: - Load

    /// Load persisted values, merging over row defaults.
    /// Transitions `status` from `.needsLoad` → `.loading` → `.ready` (or `.loadFailed`).
    ///
    /// Concurrent calls are safely deduplicated: only the caller that observes
    /// `status == .needsLoad` proceeds; any racing caller bails out because the
    /// transition to `.loading` happens atomically inside `MainActor.run`.
    ///
    /// The persistence I/O runs on whatever executor the backend requires
    /// (e.g. a background thread for network calls). All state mutations
    /// are then dispatched back to the `@MainActor` so SwiftUI's
    /// `@Observable` callbacks fire correctly on the main thread.
    public func loadFromPersistence() async {
        // Atomically claim the load on the MainActor. Because MainActor.run
        // is serialised, only the first concurrent caller that observes
        // `.needsLoad` or `.loadFailed` can transition to `.loading`;
        // any racing caller already sees `.loading` and bails out,
        // preventing a double-load race.
        let shouldLoad: Bool = await MainActor.run {
            guard status == .needsLoad || status.isLoadFailed else { return false }
            status = .loading
            return true
        }
        guard shouldLoad else { return }

        guard let persistence else {
            await MainActor.run { status = .ready }
            return
        }
        do {
            // I/O runs off the main thread — safe for network-backed backends.
            let loaded = try await persistence.load(formId: formDefinition.id)
            // All state mutations back on the main thread.
            await MainActor.run {
                // Cancel pending timers before replacing values so stale tasks
                // don't overwrite errors or trigger actions on the freshly loaded state.
                debounceTimers.values.forEach { $0.cancel() }
                debounceTimers = [:]
                actionDebounceTimers.values.forEach { $0.cancel() }
                actionDebounceTimers = [:]
                var store = FormValueStore()
                for row in allRows {
                    if let defaultValue = row.defaultValue {
                        store[row.id] = defaultValue
                    }
                }
                store.merge(loaded)
                values = store
                isDirty = false
                errors = [:]
                status = .ready
            }
        } catch {
            await MainActor.run {
                status = .loadFailed(error)
            }
        }
    }

    // MARK: - Reset

    /// Reset all values to their row defaults and clear all errors.
    ///
    /// Any unsaved changes are discarded. If a persistence backend is configured,
    /// a reload from storage is kicked off immediately — the form will transition
    /// through `.needsLoad` → `.loading` → `.ready` (or `.loadFailed`) just as it
    /// did on first load. Any call to `save()` is blocked until the reload completes.
    public func reset() {
        var store = FormValueStore()
        for row in allRows {
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
        dispatchingRows = []
        // If persistence is configured, reload from storage immediately.
        // Mirrors the same pattern used in init().
        if persistence != nil {
            status = .needsLoad
            Task { [weak self] in await self?.loadFromPersistence() }
        }
    }

    /// Clears the most recent save error. Call this when dismissing a save-failure alert.
    public func clearSaveError() {
        saveError = nil
    }

    /// Removes all `.alert`-positioned errors. Call this when dismissing the validation alert.
    public func clearAlertErrors() {
        for key in errors.keys {
            errors[key] = errors[key]?.filter { $0.position != .alert }
        }
    }

    /// Clear persisted data for this form.
    public func clearPersistence() async {
        guard let persistence else { return }
        try? await persistence.clear(formId: formDefinition.id)
    }

    // MARK: - Error Helpers

    /// Returns error messages to display below the given row.
    ///
    /// Includes:
    /// - Errors from the row's own validators with position `.belowRow` (no associated id).
    /// - Errors from any other row's validators with position `.belowRow(id: rowId)`.
    public func errorsForRow(_ rowId: String) -> [String] {
        // Own-row errors positioned directly below this row (id == nil means owning row).
        let ownErrors = (errors[rowId] ?? [])
            .filter {
                if case let .belowRow(id) = $0.position { return id == nil }
                return false
            }
            .map(\.message)

        // Errors from other rows that are targeted to display below this row.
        let targeted = errors
            .filter { $0.key != rowId }
            .flatMap(\.value)
            .filter { $0.position == .belowRow(id: rowId) }
            .map(\.message)

        return ownErrors + targeted
    }

    /// True if the row currently has validation errors that display below it.
    public func rowHasError(_ rowId: String) -> Bool {
        !errorsForRow(rowId).isEmpty
    }

    // MARK: - Private Helpers

    /// Run all validators matching the given trigger for a specific row.
    private func runValidators(for rowId: String, trigger: ValidationTrigger) {
        guard let row = allRows.first(where: { $0.id == rowId }) else { return }
        let rowErrors = row.validators
            .filter { $0.trigger == trigger }
            .compactMap { validator -> FormError? in
                guard let message = validator.validate(values[rowId], values) else { return nil }
                return FormError(message: message, position: validator.errorPosition)
            }
        errors[rowId] = rowErrors
    }

    /// Schedule debounced validation for a row.
    /// Uses the longest debounce interval among all debounced validators for the row.
    private func scheduleDebouncedValidation(for rowId: String) {
        guard let row = allRows.first(where: { $0.id == rowId }) else { return }

        let debouncedValidators = row.validators.filter(\.trigger.isDebouncedInput)
        guard !debouncedValidators.isEmpty else { return }

        let maxDelay = debouncedValidators
            .compactMap(\.trigger.debounceDuration)
            .max() ?? 0.5

        // Cancel any existing timer for this row.
        debounceTimers[rowId]?.cancel()

        debounceTimers[rowId] = Task { [weak self] in
            try? await Task.sleep(for: .seconds(maxDelay))
            guard !Task.isCancelled else { return }
            await MainActor.run { [weak self] in
                self?.runDebouncedValidators(for: rowId)
            }
        }
    }

    /// Fire all debounced validators for a row (called after the debounce delay).
    @MainActor
    private func runDebouncedValidators(for rowId: String) {
        guard let row = allRows.first(where: { $0.id == rowId }) else { return }
        let rowErrors = row.validators
            .filter(\.trigger.isDebouncedInput)
            .compactMap { validator -> FormError? in
                guard let message = validator.validate(values[rowId], values) else { return nil }
                return FormError(message: message, position: validator.errorPosition)
            }
        errors[rowId] = rowErrors
    }

    /// Dispatch all onChange actions declared on the row with the given ID.
    /// Immediate actions fire synchronously; debounced actions are scheduled via a Task.
    private func dispatchActions(for rowId: String) {
        // Re-entrancy guard: if a .custom action writes back to the same row and triggers
        // another dispatchActions call for the same rowId, we bail out immediately to
        // prevent unbounded recursion.
        guard !dispatchingRows.contains(rowId) else { return }
        guard let row = allRows.first(where: { $0.id == rowId }) else { return }

        dispatchingRows.insert(rowId)
        defer { dispatchingRows.remove(rowId) }

        for (index, action) in row.onChange.enumerated() {
            let timing = action.timing

            if timing.debounce == nil {
                // Immediate — fire now.
                executeAction(action, rowId: rowId)
            } else {
                // Debounced — cancel any pending task for this action slot and reschedule.
                let timerKey = "\(rowId)_\(index)"
                actionDebounceTimers[timerKey]?.cancel()

                let delay = timing.debounce ?? 0.5
                actionDebounceTimers[timerKey] = Task { [weak self] in
                    try? await Task.sleep(for: .seconds(delay))
                    guard !Task.isCancelled else { return }
                    await MainActor.run { [weak self] in
                        self?.executeAction(action, rowId: rowId)
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

        case .disableRow:
            // Disabled state is evaluated reactively via isRowDisabled — no imperative state to update.
            break

        case .hideRow:
            // Hide/show is evaluated reactively via isRowVisible — no imperative state to update.
            break

        case let .clearValue(targetRowId, conditions, _):
            // Clear the target row's value if all conditions are satisfied (or there are none).
            let shouldClear = conditions.isEmpty || conditions.allSatisfy { $0.evaluate(with: values) }
            if shouldClear {
                values[targetRowId] = nil
                isDirty = true
                errors[targetRowId] = []
            }

        case let .setValue(targetRowId, _, valueFactory):
            // Derive the new value from the current store and apply it if non-nil.
            // Use the internal setter to avoid triggering a full action dispatch cycle on the target.
            // Skip the write if the value hasn't changed — prevents oscillation loops where
            // two rows' setValue actions reference each other and never reach a fixed point.
            if let newValue = valueFactory(values), newValue != values[targetRowId] {
                values[targetRowId] = newValue
                isDirty = true
                errors[targetRowId] = []
            }

        case .runValidation:
            runValidators(for: rowId, trigger: .onChange)
            scheduleDebouncedValidation(for: rowId)

        case let .custom(_, handler):
            handler(values, rowId)
        }
    }

    /// Fire all form-level save actions declared on the `FormDefinition`.
    private func dispatchOnSaveActions() {
        for action in formDefinition.onSave {
            action.handler(values)
        }
    }

    // MARK: - Section Helpers

    /// Returns a flattened array of all leaf rows, recursively expanding any `FormSection` rows.
    /// Sections themselves are included so that their `onChange` actions can be inspected.
    static func allRows(in rows: [AnyFormRow]) -> [AnyFormRow] {
        rows.flatMap { row -> [AnyFormRow] in
            if let section = row.asType(FormSection.self) {
                // Include the section row itself (for its onChange actions) plus all its children.
                return [row] + allRows(in: section.rows)
            }
            return [row]
        }
    }

    /// Returns the `AnyFormRow` wrapping the `FormSection` that directly contains `rowId`,
    /// or `nil` if the row is not inside any section.
    private func parentSection(of rowId: String, in rows: [AnyFormRow]) -> AnyFormRow? {
        for row in rows {
            if let section = row.asType(FormSection.self) {
                if section.rows.contains(where: { $0.id == rowId }) {
                    return row
                }
                // Recurse into nested sections.
                if let found = parentSection(of: rowId, in: section.rows) {
                    return found
                }
            }
        }
        return nil
    }
}
