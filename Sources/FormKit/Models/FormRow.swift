import Foundation

// MARK: - ActionTiming

/// Controls when a `FormRowAction` fires.
public struct ActionTiming: Sendable {
    /// Optional debounce delay in seconds. `nil` means fire immediately on every change.
    public let debounce: Double?

    /// Fires immediately on every change.
    public static let immediate = ActionTiming(debounce: nil)

    /// Fires after the user pauses for the specified number of seconds.
    public static func debounced(_ seconds: Double) -> ActionTiming {
        ActionTiming(debounce: seconds)
    }
}

// MARK: - FormSaveAction

/// An action that fires when the form is successfully saved.
///
/// Unlike `FormRowAction` (which responds to value changes on individual rows),
/// save actions are a form-level concern and are declared on `FormDefinition`.
/// They only fire from `FormViewModel.save()`.
///
/// ```swift
/// FormDefinition(id: "settings", title: "Settings", onSave: [
///     FormSaveAction { store in
///         // React to saved values
///     }
/// ]) { ... }
/// ```
public struct FormSaveAction: Sendable {
    /// The closure to execute after a successful save.
    public let handler: @Sendable (_ store: FormValueStore) -> Void

    /// Create a save action.
    /// - Parameter handler: Closure receiving the final form values at save time.
    public init(handler: @Sendable @escaping (_ store: FormValueStore) -> Void) {
        self.handler = handler
    }
}

// MARK: - FormRowAction

/// Declarative actions attached to a row that fire when the row's value changes.
///
/// ```swift
/// SingleValueRow<LocationsList>(
///     id: .spoofingLocation,
///     title: "Spoofing Location",
///     onChange: [
///         // Show downstream rows only when simulating is enabled.
///         .showRow(id: "latitude", when: [.isTrue(rowId: "isSimulated")]),
///         // Auto-fill lat/lon when a preset is selected.
///         .setValue(on: "latitude") { store in
///             guard case let .string(raw) = store["spoofingLocation"],
///                   let loc = LocationsList(rawValue: raw)?.location else { return nil }
///             return .string(loc.coordinate.latitude.description)
///         },
///         // Run validators on this row whenever its value changes.
///         .runValidation(),
///         // Custom action with access to the full form store and the changed row.
///         .custom { store, rowId in print("changed \(rowId)") },
///     ]
/// )
/// ```
public enum FormRowAction: Sendable {
    // MARK: Show / Hide

    /// Show the row at `targetRowId` when ALL `conditions` evaluate to true against the
    /// current form store. Hide it when any condition fails.
    ///
    /// - Parameters:
    ///   - targetRowId: The ID of the row to show or hide.
    ///   - conditions: `FormCondition` expressions evaluated against the full form store.
    ///     Empty conditions mean the target is always shown.
    ///   - timing: When to evaluate — `.immediate` or `.debounced(_:)`.
    case showRow(id: String, when: [FormCondition] = [], timing: ActionTiming = .immediate)

    // MARK: Set Value

    /// Set the value of another row when this row changes.
    /// The closure receives the current `FormValueStore` and returns the new value to set,
    /// or `nil` to skip the update.
    ///
    /// - Parameters:
    ///   - targetRowId: The ID of the row to update.
    ///   - timing: When to fire.
    ///   - value: Closure returning the value to set (or nil to skip).
    case setValue(
        on: String,
        timing: ActionTiming = .immediate,
        value: @Sendable (_ store: FormValueStore) -> AnyCodableValue?
    )

    // MARK: Run Validation

    /// Re-run the validators on this row when its value changes.
    /// Useful for triggering `.onChange` validation without redeclaring `validators`.
    ///
    /// - Parameter timing: When to fire.
    case runValidation(timing: ActionTiming = .immediate)

    // MARK: Custom

    /// Arbitrary closure that fires when this row's value changes.
    /// Receives the full `FormValueStore` and this row's ID.
    ///
    /// - Parameters:
    ///   - timing: When to fire.
    ///   - handler: Closure receiving the current store and the changed row's ID.
    case custom(
        timing: ActionTiming = .immediate,
        handler: @Sendable (_ store: FormValueStore, _ rowId: String) -> Void
    )

    // MARK: - Internal Helpers

    /// When this action fires relative to the value change.
    var timing: ActionTiming {
        switch self {
        case let .showRow(_, _, timing): return timing
        case let .setValue(_, timing, _): return timing
        case let .runValidation(timing): return timing
        case let .custom(timing, _): return timing
        }
    }
}

// MARK: - FormRowAction RawRepresentable Convenience

public extension FormRowAction {
    /// `.showRow` accepting a `RawRepresentable` target row ID (enum case).
    static func showRow<ID: RawRepresentable>(id: ID,
                                              when conditions: [FormCondition] = [],
                                              timing: ActionTiming = .immediate) -> FormRowAction where ID.RawValue == String {
        .showRow(id: id.rawValue, when: conditions, timing: timing)
    }

    /// `.setValue` accepting a `RawRepresentable` target row ID (enum case).
    static func setValue<ID: RawRepresentable>(on targetRowId: ID,
                                               timing: ActionTiming = .immediate,
                                               value: @Sendable @escaping (_ store: FormValueStore) -> AnyCodableValue?) -> FormRowAction where ID.RawValue == String {
        .setValue(on: targetRowId.rawValue, timing: timing, value: value)
    }
}

// MARK: - FormRow Protocol

/// The base protocol all form row types conform to.
/// Rows are identified by a unique string ID used for persistence, bindings, and action references.
public protocol FormRow: Sendable, Identifiable where ID == String {
    /// Unique identifier for this row. Must be unique within a form.
    var id: String { get }

    /// The display title shown to the user.
    var title: String { get }

    /// Optional help or description text shown below the title.
    var subtitle: String? { get }

    /// Declarative actions — show/hide other rows, set values, run validation, or
    /// execute custom logic in response to this row's value changing or the form saving.
    var onChange: [FormRowAction] { get }

    /// Validators attached to this row.
    var validators: [FormValidator] { get }

    /// The default value for this row. Loaded into FormViewModel on initialisation.
    var defaultValue: AnyCodableValue? { get }
}

// MARK: - Default Implementations

public extension FormRow {
    var subtitle: String? { nil }
    var onChange: [FormRowAction] { [] }
    var validators: [FormValidator] { [] }
    var defaultValue: AnyCodableValue? { nil }
}

// MARK: - SingleValueRowRepresentable

/// Marker protocol that lets views work with SingleValueRow<T> without knowing T.
public protocol SingleValueRowRepresentable: FormRow {
    /// Descriptions of all available options, in order.
    var optionDescriptions: [String] { get }
    /// The description of the currently selected option, or nil.
    var selectedDescription: String? { get }
}

// MARK: - MultiValueRowRepresentable

/// Marker protocol that lets views work with MultiValueRow<T> without knowing T.
public protocol MultiValueRowRepresentable: FormRow {
    /// Descriptions of all available options, in order.
    var optionDescriptions: [String] { get }
    /// Descriptions of all currently selected options.
    var selectedDescriptions: [String] { get }
}

// MARK: - AnyFormRow (Type-Erased Wrapper)

/// Type-erased wrapper around any FormRow.
/// Allows FormDefinition to hold a heterogeneous [AnyFormRow] array.
public struct AnyFormRow: Sendable, Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let onChange: [FormRowAction]
    public let validators: [FormValidator]
    public let defaultValue: AnyCodableValue?

    /// The underlying concrete row. Internal so views inside the module can cast it.
    let base: any FormRow

    public init(_ row: some FormRow) {
        id = row.id
        title = row.title
        subtitle = row.subtitle
        onChange = row.onChange
        validators = row.validators
        defaultValue = row.defaultValue
        base = row
    }

    /// Attempt to cast the underlying row to a specific concrete type.
    public func asType<R: FormRow>(_ type: R.Type) -> R? {
        base as? R
    }

    /// Returns the underlying row as SingleValueRowRepresentable if it conforms.
    public var asSingleValueRepresentable: (any SingleValueRowRepresentable)? {
        base as? any SingleValueRowRepresentable
    }

    /// Returns the underlying row as MultiValueRowRepresentable if it conforms.
    public var asMultiValueRepresentable: (any MultiValueRowRepresentable)? {
        base as? any MultiValueRowRepresentable
    }
}

// MARK: - SingleValueRow

/// A row that lets the user select exactly one value from a list.
/// T must be CaseIterable, CustomStringConvertible, Hashable, Sendable, and Codable.
public struct SingleValueRow<T>: FormRow, SingleValueRowRepresentable
    where T: CaseIterable & CustomStringConvertible & Hashable & Sendable & Codable,
    T.AllCases: Sendable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let onChange: [FormRowAction]
    public let validators: [FormValidator]

    /// All available options. Defaults to `T.allCases` if not provided.
    public let options: [T]

    private let _defaultValue: T?

    public var defaultValue: AnyCodableValue? {
        _defaultValue.map { .string($0.description) }
    }

    // MARK: SingleValueRowRepresentable

    public var optionDescriptions: [String] {
        options.map(\.description)
    }

    public var selectedDescription: String? {
        _defaultValue?.description
    }

    public init(id: String,
                title: String,
                subtitle: String? = nil,
                options: [T]? = nil,
                defaultValue: T? = nil,
                validators: [FormValidator] = [],
                onChange: [FormRowAction] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.options = options ?? Array(T.allCases)
        _defaultValue = defaultValue
        self.validators = validators
        self.onChange = onChange
    }
}

// MARK: - MultiValueRow

/// A row that lets the user select multiple values from a list.
public struct MultiValueRow<T>: FormRow, MultiValueRowRepresentable
    where T: CaseIterable & CustomStringConvertible & Hashable & Sendable & Codable,
    T.AllCases: Sendable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let onChange: [FormRowAction]
    public let validators: [FormValidator]

    /// All available options.
    public let options: [T]

    private let _defaultValue: Set<T>

    public var defaultValue: AnyCodableValue? {
        _defaultValue.isEmpty
            ? nil
            : .array(_defaultValue.map { .string($0.description) })
    }

    // MARK: MultiValueRowRepresentable

    public var optionDescriptions: [String] {
        options.map(\.description)
    }

    public var selectedDescriptions: [String] {
        _defaultValue.map(\.description)
    }

    public init(id: String,
                title: String,
                subtitle: String? = nil,
                options: [T]? = nil,
                defaultValue: Set<T> = [],
                validators: [FormValidator] = [],
                onChange: [FormRowAction] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.options = options ?? Array(T.allCases)
        _defaultValue = defaultValue
        self.validators = validators
        self.onChange = onChange
    }
}

// MARK: - BooleanSwitchRow

/// A toggle row with an on/off state.
public struct BooleanSwitchRow: FormRow {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let onChange: [FormRowAction]
    public let validators: [FormValidator]

    private let _defaultValue: Bool

    public var defaultValue: AnyCodableValue? { .bool(_defaultValue) }

    public init(id: String,
                title: String,
                subtitle: String? = nil,
                defaultValue: Bool = false,
                validators: [FormValidator] = [],
                onChange: [FormRowAction] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        _defaultValue = defaultValue
        self.validators = validators
        self.onChange = onChange
    }
}

// MARK: - FormKeyboardType

/// Platform-independent keyboard type hint for TextInputRow.
/// Mapped to `UIKeyboardType` on iOS and ignored on platforms that don't support it.
public enum FormKeyboardType: Sendable {
    /// The default keyboard for the current input method.
    case `default`
    /// A keyboard optimised for decimal number entry (includes the decimal separator).
    case decimalPad
    /// A numeric keypad (0–9 only, no decimal separator).
    case numberPad
    /// A keyboard for entering email addresses.
    case emailAddress
    /// A keyboard for URL entry.
    case url
    /// A keyboard for entering telephone numbers.
    case phonePad
}

// MARK: - TextInputRow

/// A free-text input row. Supports secure (password) input.
public struct TextInputRow: FormRow {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let onChange: [FormRowAction]
    public let validators: [FormValidator]
    public let placeholder: String?
    public let isSecure: Bool
    public let keyboardType: FormKeyboardType

    private let _defaultValue: String?

    public var defaultValue: AnyCodableValue? {
        _defaultValue.map { .string($0) }
    }

    public init(id: String,
                title: String,
                subtitle: String? = nil,
                placeholder: String? = nil,
                defaultValue: String? = nil,
                isSecure: Bool = false,
                keyboardType: FormKeyboardType = .default,
                validators: [FormValidator] = [],
                onChange: [FormRowAction] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.placeholder = placeholder
        _defaultValue = defaultValue
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.validators = validators
        self.onChange = onChange
    }
}

// MARK: - NumberKind

/// Declares the numeric kind (integer vs decimal) and an optional default value for a
/// `NumberInputRow` in a single, unified parameter.
///
/// Using one parameter for both eliminates the ambiguity of pairing a separate `kind`
/// with a `defaultValue` that might not match.
///
/// ```swift
/// NumberInputRow(id: "retries", title: "Retries", kind: .int(defaultValue: 3))
/// NumberInputRow(id: "rate",    title: "Rate",    kind: .decimal(defaultValue: 1.5))
/// NumberInputRow(id: "count",   title: "Count")   // defaults to .int(defaultValue: nil)
/// ```
public enum NumberKind: Sendable {
    /// An integer field with an optional integer default value.
    case int(defaultValue: Int?)
    /// A decimal field with an optional double default value.
    case decimal(defaultValue: Double?)
}

// MARK: - NumberInputRow

/// A numeric input row.
public struct NumberInputRow: FormRow {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let onChange: [FormRowAction]
    public let validators: [FormValidator]
    public let placeholder: String?

    private let _kind: NumberKind

    /// The numeric kind and default value for this row.
    public var kind: NumberKind { _kind }

    /// `true` when this row is configured as a decimal field.
    public var isDecimal: Bool {
        if case .decimal = _kind { return true }
        return false
    }

    public var defaultValue: AnyCodableValue? {
        switch _kind {
        case let .int(value): return value.map { .int($0) }
        case let .decimal(value): return value.map { .double($0) }
        }
    }

    public init(id: String,
                title: String,
                subtitle: String? = nil,
                placeholder: String? = nil,
                kind: NumberKind = .int(defaultValue: nil),
                validators: [FormValidator] = [],
                onChange: [FormRowAction] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.placeholder = placeholder
        _kind = kind
        self.validators = validators
        self.onChange = onChange
    }
}

// MARK: - ButtonRow

/// A row that renders as a tappable button with a custom action.
/// Unlike NavigationRow, this does not navigate to a sub-form — it fires
/// an arbitrary closure when tapped. Useful for actions like "Unbind User",
/// "Show Banner", or "Inspect".
public struct ButtonRow: FormRow, @unchecked Sendable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let onChange: [FormRowAction]
    public let validators: [FormValidator] = []
    public let defaultValue: AnyCodableValue? = nil

    /// The action to perform when the button is tapped.
    public let action: @Sendable () -> Void

    public init(id: String,
                title: String,
                subtitle: String? = nil,
                onChange: [FormRowAction] = [],
                action: @Sendable @escaping () -> Void) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.onChange = onChange
        self.action = action
    }
}

public extension ButtonRow {
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               subtitle: String? = nil,
                               onChange: [FormRowAction] = [],
                               action: @Sendable @escaping () -> Void) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            onChange: onChange,
            action: action
        )
    }
}

// MARK: - InfoRow

/// A read-only display row that shows a label with a corresponding value.
/// Unlike other rows, `InfoRow` carries no editable value and is never persisted.
/// Use it to surface read-only data (e.g. privacy strings, computed state) inline
/// within a form alongside editable rows.
///
/// The `value` is provided as a closure so it is evaluated at render time,
/// allowing dynamic values that update independently of the form definition.
public struct InfoRow: FormRow, @unchecked Sendable {
    public let id: String
    public let title: String
    public let subtitle: String? = nil
    public let onChange: [FormRowAction] = []
    public let validators: [FormValidator] = []
    public let defaultValue: AnyCodableValue? = nil

    /// Closure evaluated at render time to produce the value string shown on the trailing side.
    public let value: () -> String

    public init(id: String, title: String, value: @escaping () -> String) {
        self.id = id
        self.title = title
        self.value = value
    }
}

public extension InfoRow {
    init<ID: RawRepresentable>(id: ID, title: String, value: @escaping () -> String) where ID.RawValue == String {
        self.init(id: id.rawValue, title: title, value: value)
    }
}

// MARK: - FormSection

/// A container row that groups child rows under a named, identifiable section.
///
/// `FormSection` conforms to `FormRow` so it slots directly into the `@FormRowBuilder` DSL
/// alongside other row types. The `id` can be targeted by `.showRow` actions on other rows
/// to show or hide the entire section (including all its children) conditionally.
///
/// ```swift
/// FormDefinition(id: "settings", title: "Settings") {
///     BooleanSwitchRow(id: "advanced", title: "Advanced Mode")
///
///     FormSection(id: "advancedSettings", title: "Advanced Settings",
///                 onChange: [.showRow(id: "advancedSettings",
///                                    when: [.isTrue(rowId: "advanced")])]) {
///         TextInputRow(id: "timeout", title: "Timeout")
///         NumberInputRow(id: "retries", title: "Retries")
///     }
/// }
/// ```
public struct FormSection: FormRow, @unchecked Sendable {
    public let id: String
    public let title: String
    public let subtitle: String? = nil
    public let onChange: [FormRowAction]
    public let validators: [FormValidator] = []
    public let defaultValue: AnyCodableValue? = nil

    /// The child rows contained in this section.
    public let rows: [AnyFormRow]

    // MARK: Initialisers

    /// Create a section with a pre-built array of rows.
    public init(id: String,
                title: String,
                rows: [AnyFormRow],
                onChange: [FormRowAction] = []) {
        self.id = id
        self.title = title
        self.rows = rows
        self.onChange = onChange
    }

    /// Create a section using the `@FormRowBuilder` DSL.
    ///
    /// ```swift
    /// FormSection(id: "account", title: "Account") {
    ///     TextInputRow(id: "name", title: "Name")
    ///     TextInputRow(id: "email", title: "Email")
    /// }
    /// ```
    public init(id: String,
                title: String,
                onChange: [FormRowAction] = [],
                @FormRowBuilder rows: () -> [AnyFormRow]) {
        self.id = id
        self.title = title
        self.rows = rows()
        self.onChange = onChange
    }
}

public extension FormSection {
    /// Create a section with a `RawRepresentable` id and a pre-built array of rows.
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               rows: [AnyFormRow],
                               onChange: [FormRowAction] = []) where ID.RawValue == String {
        self.init(id: id.rawValue, title: title, rows: rows, onChange: onChange)
    }

    /// Create a section with a `RawRepresentable` id using the `@FormRowBuilder` DSL.
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               onChange: [FormRowAction] = [],
                               @FormRowBuilder rows: () -> [AnyFormRow]) where ID.RawValue == String {
        self.init(id: id.rawValue, title: title, onChange: onChange, rows: rows)
    }
}

// MARK: - NavigationRow

/// A row that navigates to a sub-form when tapped.
public struct NavigationRow: FormRow {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let onChange: [FormRowAction]
    public let validators: [FormValidator] = []

    /// The sub-form this row navigates to.
    public let destination: FormDefinition

    /// Navigation rows carry no editable value.
    public var defaultValue: AnyCodableValue? { nil }

    public init(id: String,
                title: String,
                subtitle: String? = nil,
                destination: FormDefinition,
                onChange: [FormRowAction] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.destination = destination
        self.onChange = onChange
    }
}

// MARK: - RawRepresentable Row ID Overloads

// These extensions let you pass strongly-typed enum cases as row IDs.
// Example:
//   enum MyRowID: String { case name, email }
//   TextInputRow(id: MyRowID.name, title: "Name")

public extension SingleValueRow {
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               subtitle: String? = nil,
                               options: [T]? = nil,
                               defaultValue: T? = nil,
                               validators: [FormValidator] = [],
                               onChange: [FormRowAction] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            options: options,
            defaultValue: defaultValue,
            validators: validators,
            onChange: onChange
        )
    }
}

public extension MultiValueRow {
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               subtitle: String? = nil,
                               options: [T]? = nil,
                               defaultValue: Set<T> = [],
                               validators: [FormValidator] = [],
                               onChange: [FormRowAction] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            options: options,
            defaultValue: defaultValue,
            validators: validators,
            onChange: onChange
        )
    }
}

public extension BooleanSwitchRow {
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               subtitle: String? = nil,
                               defaultValue: Bool = false,
                               validators: [FormValidator] = [],
                               onChange: [FormRowAction] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            defaultValue: defaultValue,
            validators: validators,
            onChange: onChange
        )
    }
}

public extension TextInputRow {
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               subtitle: String? = nil,
                               placeholder: String? = nil,
                               defaultValue: String? = nil,
                               isSecure: Bool = false,
                               keyboardType: FormKeyboardType = .default,
                               validators: [FormValidator] = [],
                               onChange: [FormRowAction] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            placeholder: placeholder,
            defaultValue: defaultValue,
            isSecure: isSecure,
            keyboardType: keyboardType,
            validators: validators,
            onChange: onChange
        )
    }
}

public extension NumberInputRow {
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               subtitle: String? = nil,
                               placeholder: String? = nil,
                               kind: NumberKind = .int(defaultValue: nil),
                               validators: [FormValidator] = [],
                               onChange: [FormRowAction] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            placeholder: placeholder,
            kind: kind,
            validators: validators,
            onChange: onChange
        )
    }
}

public extension NavigationRow {
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               subtitle: String? = nil,
                               destination: FormDefinition,
                               onChange: [FormRowAction] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            destination: destination,
            onChange: onChange
        )
    }
}
