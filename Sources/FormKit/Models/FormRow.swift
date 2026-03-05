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

// MARK: - FormRowAction

/// Declarative actions attached to a row. Actions fire when the row's value changes
/// (onChange actions) or when the form is saved (onSave actions).
///
/// Replaces both the old `conditions` visibility system and `FormValueChangeHandler`.
///
/// ```swift
/// SingleValueRow<LocationsList>(
///     id: .spoofingLocation,
///     title: "Spoofing Location",
///     actions: [
///         // Show downstream rows only when simulating is enabled.
///         .showRow(id: "latitude", when: [.isTrue(rowId: "isSimulated")], timing: .immediate),
///         // Auto-fill lat/lon when a preset is selected.
///         .setValue(on: "latitude", timing: .immediate) { store in
///             guard case let .string(raw) = store["spoofingLocation"],
///                   let loc = LocationsList(rawValue: raw)?.location else { return nil }
///             return .string(loc.coordinate.latitude.description)
///         },
///         // Run validators on this row whenever its value changes.
///         .runValidation(timing: .immediate),
///         // Custom action with access to the full form store and the changed row.
///         .custom(timing: .immediate) { store, rowId in print("changed \(rowId)") },
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

    // MARK: Custom (onChange)

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

    // MARK: Custom (onSave)

    /// Arbitrary closure that fires when the form is successfully saved.
    /// Receives the final `FormValueStore` at the time of save.
    ///
    /// Unlike the other action cases this does NOT respond to value changes —
    /// it only fires from `FormViewModel.save()`.
    ///
    /// - Parameter handler: Closure receiving the saved store.
    case onSave(
        handler: @Sendable (_ store: FormValueStore) -> Void
    )

    // MARK: - Internal Helpers

    /// The timing for onChange actions. `nil` for onSave actions.
    var timing: ActionTiming? {
        switch self {
        case let .showRow(_, _, timing): return timing
        case let .setValue(_, timing, _): return timing
        case let .runValidation(timing): return timing
        case let .custom(timing, _): return timing
        case .onSave: return nil
        }
    }

    /// Whether this action fires on value changes (vs. only on save).
    var isOnChangeAction: Bool {
        switch self {
        case .showRow, .setValue, .runValidation, .custom: return true
        case .onSave: return false
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

/// Whether a NumberInputRow accepts integers or decimals.
public enum NumberKind: Sendable {
    case integer
    case decimal
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
    public let kind: NumberKind
    private let _defaultValue: AnyCodableValue?

    public var defaultValue: AnyCodableValue? { _defaultValue }

    /// Integer input row.
    public init(id: String,
                title: String,
                subtitle: String? = nil,
                placeholder: String? = nil,
                kind: NumberKind = .integer,
                defaultValue: Int? = nil,
                validators: [FormValidator] = [],
                onChange: [FormRowAction] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.placeholder = placeholder
        self.kind = kind
        _defaultValue = defaultValue.map { .int($0) }
        self.validators = validators
        self.onChange = onChange
    }

    /// Decimal input row.
    public init(id: String,
                title: String,
                subtitle: String? = nil,
                placeholder: String? = nil,
                defaultValue: Double?,
                validators: [FormValidator] = [],
                onChange: [FormRowAction] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.placeholder = placeholder
        kind = .decimal
        _defaultValue = defaultValue.map { .double($0) }
        self.validators = validators
        self.onChange = onChange
    }
}

// MARK: - EmailInputRow

/// An email-specific input row.
/// Automatically prepends an email format validator.
public struct EmailInputRow: FormRow {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let onChange: [FormRowAction]
    public let validators: [FormValidator]
    public let placeholder: String?

    private let _defaultValue: String?

    public var defaultValue: AnyCodableValue? {
        _defaultValue.map { .string($0) }
    }

    public init(id: String,
                title: String,
                subtitle: String? = nil,
                placeholder: String? = "email@example.com",
                defaultValue: String? = nil,
                validators: [FormValidator] = [],
                onChange: [FormRowAction] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.placeholder = placeholder
        _defaultValue = defaultValue
        // Automatically prepend email format validator (fires onSave by default).
        var allValidators: [FormValidator] = [.email()]
        allValidators.append(contentsOf: validators)
        self.validators = allValidators
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

// MARK: - NavigationRow

/// A row that navigates to a sub-form when tapped.
public struct NavigationRow: FormRow {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let onChange: [FormRowAction]
    public let validators: [FormValidator]

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
        validators = []
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
                               kind: NumberKind = .integer,
                               defaultValue: Int? = nil,
                               validators: [FormValidator] = [],
                               onChange: [FormRowAction] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            placeholder: placeholder,
            kind: kind,
            defaultValue: defaultValue,
            validators: validators,
            onChange: onChange
        )
    }

    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               subtitle: String? = nil,
                               placeholder: String? = nil,
                               defaultValue: Double?,
                               validators: [FormValidator] = [],
                               onChange: [FormRowAction] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            placeholder: placeholder,
            defaultValue: defaultValue,
            validators: validators,
            onChange: onChange
        )
    }
}

public extension EmailInputRow {
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               subtitle: String? = nil,
                               placeholder: String? = "email@example.com",
                               defaultValue: String? = nil,
                               validators: [FormValidator] = [],
                               onChange: [FormRowAction] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            placeholder: placeholder,
            defaultValue: defaultValue,
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
