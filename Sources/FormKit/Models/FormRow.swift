import Foundation

// MARK: - FormValueChangeHandler

/// A handler that runs when a row's value changes.
/// Attach handlers to rows inline alongside `validators` and `conditions`.
///
/// ```swift
/// TextInputRow(
///     id: .latitude,
///     title: "Latitude",
///     onChange: [
///         .immediate { _ in print("changed") },
///         .debounced(0.5) { value in doSomething(with: value) }
///     ]
/// )
/// ```
public struct FormValueChangeHandler: Sendable {
    /// Optional debounce delay in seconds. `nil` means fire immediately on every change.
    public let debounce: Double?

    /// The handler closure. Receives the new `AnyCodableValue?` for the row.
    public let run: @Sendable (AnyCodableValue?) -> Void

    public init(debounce: Double? = nil, run: @escaping @Sendable (AnyCodableValue?) -> Void) {
        self.debounce = debounce
        self.run = run
    }

    /// Fires immediately on every value change.
    public static func immediate(_ run: @escaping @Sendable (AnyCodableValue?) -> Void) -> FormValueChangeHandler {
        FormValueChangeHandler(debounce: nil, run: run)
    }

    /// Fires after the user pauses changing the value for `seconds`.
    public static func debounced(_ seconds: Double,
                                 _ run: @escaping @Sendable (AnyCodableValue?) -> Void) -> FormValueChangeHandler {
        FormValueChangeHandler(debounce: seconds, run: run)
    }
}

// MARK: - FormRow Protocol

/// The base protocol all form row types conform to.
/// Rows are identified by a unique string ID used for persistence, bindings, and condition references.
public protocol FormRow: Sendable, Identifiable where ID == String {
    /// Unique identifier for this row. Must be unique within a form.
    var id: String { get }

    /// The display title shown to the user.
    var title: String { get }

    /// Optional help or description text shown below the title.
    var subtitle: String? { get }

    /// Whether the row must have a value for the form to be saved.
    var isRequired: Bool { get }

    /// Visibility conditions. When empty the row is always visible.
    /// Multiple conditions use AND logic by default; wrap in `.or()` for OR.
    var conditions: [FormCondition] { get }

    /// Validators attached to this row.
    var validators: [FormValidator] { get }

    /// Value-change handlers attached to this row.
    /// Declared inline alongside `validators` and `conditions`.
    var onChange: [FormValueChangeHandler] { get }

    /// The default value for this row. Loaded into FormViewModel on initialisation.
    var defaultValue: AnyCodableValue? { get }
}

// MARK: - Default Implementations

public extension FormRow {
    var subtitle: String? { nil }
    var isRequired: Bool { false }
    var conditions: [FormCondition] { [] }
    var validators: [FormValidator] { [] }
    var onChange: [FormValueChangeHandler] { [] }
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
    public let isRequired: Bool
    public let conditions: [FormCondition]
    public let validators: [FormValidator]
    public let onChange: [FormValueChangeHandler]
    public let defaultValue: AnyCodableValue?

    /// The underlying concrete row. Internal so views inside the module can cast it.
    let base: any FormRow

    public init(_ row: some FormRow) {
        id = row.id
        title = row.title
        subtitle = row.subtitle
        isRequired = row.isRequired
        conditions = row.conditions
        validators = row.validators
        onChange = row.onChange
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
    public let isRequired: Bool
    public let conditions: [FormCondition]
    public let validators: [FormValidator]
    public let onChange: [FormValueChangeHandler]

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
                isRequired: Bool = false,
                options: [T]? = nil,
                defaultValue: T? = nil,
                conditions: [FormCondition] = [],
                validators: [FormValidator] = [],
                onChange: [FormValueChangeHandler] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.isRequired = isRequired
        self.options = options ?? Array(T.allCases)
        _defaultValue = defaultValue
        self.conditions = conditions
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
    public let isRequired: Bool
    public let conditions: [FormCondition]
    public let validators: [FormValidator]
    public let onChange: [FormValueChangeHandler]

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
                isRequired: Bool = false,
                options: [T]? = nil,
                defaultValue: Set<T> = [],
                conditions: [FormCondition] = [],
                validators: [FormValidator] = [],
                onChange: [FormValueChangeHandler] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.isRequired = isRequired
        self.options = options ?? Array(T.allCases)
        _defaultValue = defaultValue
        self.conditions = conditions
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
    public let isRequired: Bool
    public let conditions: [FormCondition]
    public let validators: [FormValidator]
    public let onChange: [FormValueChangeHandler]

    private let _defaultValue: Bool

    public var defaultValue: AnyCodableValue? { .bool(_defaultValue) }

    public init(id: String,
                title: String,
                subtitle: String? = nil,
                isRequired: Bool = false,
                defaultValue: Bool = false,
                conditions: [FormCondition] = [],
                validators: [FormValidator] = [],
                onChange: [FormValueChangeHandler] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.isRequired = isRequired
        _defaultValue = defaultValue
        self.conditions = conditions
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
    public let isRequired: Bool
    public let conditions: [FormCondition]
    public let validators: [FormValidator]
    public let onChange: [FormValueChangeHandler]
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
                isRequired: Bool = false,
                defaultValue: String? = nil,
                isSecure: Bool = false,
                keyboardType: FormKeyboardType = .default,
                conditions: [FormCondition] = [],
                validators: [FormValidator] = [],
                onChange: [FormValueChangeHandler] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.placeholder = placeholder
        self.isRequired = isRequired
        _defaultValue = defaultValue
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.conditions = conditions
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
    public let isRequired: Bool
    public let conditions: [FormCondition]
    public let validators: [FormValidator]
    public let onChange: [FormValueChangeHandler]
    public let placeholder: String?
    public let kind: NumberKind
    private let _defaultValue: AnyCodableValue?

    public var defaultValue: AnyCodableValue? { _defaultValue }

    /// Integer input row.
    public init(id: String,
                title: String,
                subtitle: String? = nil,
                placeholder: String? = nil,
                isRequired: Bool = false,
                kind: NumberKind = .integer,
                defaultValue: Int? = nil,
                conditions: [FormCondition] = [],
                validators: [FormValidator] = [],
                onChange: [FormValueChangeHandler] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.placeholder = placeholder
        self.isRequired = isRequired
        self.kind = kind
        _defaultValue = defaultValue.map { .int($0) }
        self.conditions = conditions
        self.validators = validators
        self.onChange = onChange
    }

    /// Decimal input row.
    public init(id: String,
                title: String,
                subtitle: String? = nil,
                placeholder: String? = nil,
                isRequired: Bool = false,
                defaultValue: Double?,
                conditions: [FormCondition] = [],
                validators: [FormValidator] = [],
                onChange: [FormValueChangeHandler] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.placeholder = placeholder
        self.isRequired = isRequired
        kind = .decimal
        _defaultValue = defaultValue.map { .double($0) }
        self.conditions = conditions
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
    public let isRequired: Bool
    public let conditions: [FormCondition]
    public let validators: [FormValidator]
    public let onChange: [FormValueChangeHandler]
    public let placeholder: String?

    private let _defaultValue: String?

    public var defaultValue: AnyCodableValue? {
        _defaultValue.map { .string($0) }
    }

    public init(id: String,
                title: String,
                subtitle: String? = nil,
                placeholder: String? = "email@example.com",
                isRequired: Bool = false,
                defaultValue: String? = nil,
                conditions: [FormCondition] = [],
                validators: [FormValidator] = [],
                onChange: [FormValueChangeHandler] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.placeholder = placeholder
        self.isRequired = isRequired
        _defaultValue = defaultValue
        self.conditions = conditions
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
    public let isRequired: Bool = false
    public let conditions: [FormCondition]
    public let validators: [FormValidator] = []
    public let defaultValue: AnyCodableValue? = nil

    /// The action to perform when the button is tapped.
    /// Stored as a `@Sendable` closure to satisfy `Sendable` conformance.
    public let action: @Sendable () -> Void

    public init(id: String,
                title: String,
                subtitle: String? = nil,
                conditions: [FormCondition] = [],
                action: @Sendable @escaping () -> Void) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.conditions = conditions
        self.action = action
    }
}

public extension ButtonRow {
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               subtitle: String? = nil,
                               conditions: [FormCondition] = [],
                               action: @Sendable @escaping () -> Void) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            conditions: conditions,
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
    public let isRequired: Bool
    public let conditions: [FormCondition]
    public let validators: [FormValidator]

    /// The sub-form this row navigates to.
    public let destination: FormDefinition

    /// Navigation rows carry no editable value.
    public var defaultValue: AnyCodableValue? { nil }

    public init(id: String,
                title: String,
                subtitle: String? = nil,
                destination: FormDefinition,
                conditions: [FormCondition] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        isRequired = false
        self.destination = destination
        self.conditions = conditions
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
                               isRequired: Bool = false,
                               options: [T]? = nil,
                               defaultValue: T? = nil,
                               conditions: [FormCondition] = [],
                               validators: [FormValidator] = [],
                               onChange: [FormValueChangeHandler] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            isRequired: isRequired,
            options: options,
            defaultValue: defaultValue,
            conditions: conditions,
            validators: validators,
            onChange: onChange
        )
    }
}

public extension MultiValueRow {
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               subtitle: String? = nil,
                               isRequired: Bool = false,
                               options: [T]? = nil,
                               defaultValue: Set<T> = [],
                               conditions: [FormCondition] = [],
                               validators: [FormValidator] = [],
                               onChange: [FormValueChangeHandler] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            isRequired: isRequired,
            options: options,
            defaultValue: defaultValue,
            conditions: conditions,
            validators: validators,
            onChange: onChange
        )
    }
}

public extension BooleanSwitchRow {
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               subtitle: String? = nil,
                               isRequired: Bool = false,
                               defaultValue: Bool = false,
                               conditions: [FormCondition] = [],
                               validators: [FormValidator] = [],
                               onChange: [FormValueChangeHandler] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            isRequired: isRequired,
            defaultValue: defaultValue,
            conditions: conditions,
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
                               isRequired: Bool = false,
                               defaultValue: String? = nil,
                               isSecure: Bool = false,
                               keyboardType: FormKeyboardType = .default,
                               conditions: [FormCondition] = [],
                               validators: [FormValidator] = [],
                               onChange: [FormValueChangeHandler] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            placeholder: placeholder,
            isRequired: isRequired,
            defaultValue: defaultValue,
            isSecure: isSecure,
            keyboardType: keyboardType,
            conditions: conditions,
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
                               isRequired: Bool = false,
                               kind: NumberKind = .integer,
                               defaultValue: Int? = nil,
                               conditions: [FormCondition] = [],
                               validators: [FormValidator] = [],
                               onChange: [FormValueChangeHandler] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            placeholder: placeholder,
            isRequired: isRequired,
            kind: kind,
            defaultValue: defaultValue,
            conditions: conditions,
            validators: validators,
            onChange: onChange
        )
    }

    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               subtitle: String? = nil,
                               placeholder: String? = nil,
                               isRequired: Bool = false,
                               defaultValue: Double?,
                               conditions: [FormCondition] = [],
                               validators: [FormValidator] = [],
                               onChange: [FormValueChangeHandler] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            placeholder: placeholder,
            isRequired: isRequired,
            defaultValue: defaultValue,
            conditions: conditions,
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
                               isRequired: Bool = false,
                               defaultValue: String? = nil,
                               conditions: [FormCondition] = [],
                               validators: [FormValidator] = [],
                               onChange: [FormValueChangeHandler] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            placeholder: placeholder,
            isRequired: isRequired,
            defaultValue: defaultValue,
            conditions: conditions,
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
                               conditions: [FormCondition] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            destination: destination,
            conditions: conditions
        )
    }
}
