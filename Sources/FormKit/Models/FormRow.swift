import Foundation

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

    /// The default value for this row. Loaded into FormViewModel on initialisation.
    var defaultValue: AnyCodableValue? { get }
}

// MARK: - Default Implementations

public extension FormRow {
    var subtitle: String? { nil }
    var isRequired: Bool { false }
    var conditions: [FormCondition] { [] }
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
    public let isRequired: Bool
    public let conditions: [FormCondition]
    public let validators: [FormValidator]
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

    /// All available options. Defaults to `T.allCases` if not provided.
    public let options: [T]

    /// The initially selected value.
    public let defaultSelection: T?

    public var defaultValue: AnyCodableValue? {
        defaultSelection.map { .string($0.description) }
    }

    // MARK: SingleValueRowRepresentable

    public var optionDescriptions: [String] {
        options.map(\.description)
    }

    public var selectedDescription: String? {
        defaultSelection?.description
    }

    public init(id: String,
                title: String,
                subtitle: String? = nil,
                isRequired: Bool = false,
                options: [T]? = nil,
                defaultSelection: T? = nil,
                conditions: [FormCondition] = [],
                validators: [FormValidator] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.isRequired = isRequired
        self.options = options ?? Array(T.allCases)
        self.defaultSelection = defaultSelection
        self.conditions = conditions
        self.validators = validators
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

    /// All available options.
    public let options: [T]

    /// The initially selected values.
    public let defaultSelections: Set<T>

    public var defaultValue: AnyCodableValue? {
        defaultSelections.isEmpty
            ? nil
            : .array(defaultSelections.map { .string($0.description) })
    }

    // MARK: MultiValueRowRepresentable

    public var optionDescriptions: [String] {
        options.map(\.description)
    }

    public var selectedDescriptions: [String] {
        defaultSelections.map(\.description)
    }

    public init(id: String,
                title: String,
                subtitle: String? = nil,
                isRequired: Bool = false,
                options: [T]? = nil,
                defaultSelections: Set<T> = [],
                conditions: [FormCondition] = [],
                validators: [FormValidator] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.isRequired = isRequired
        self.options = options ?? Array(T.allCases)
        self.defaultSelections = defaultSelections
        self.conditions = conditions
        self.validators = validators
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
    public let defaultIsOn: Bool

    public var defaultValue: AnyCodableValue? { .bool(defaultIsOn) }

    public init(id: String,
                title: String,
                subtitle: String? = nil,
                isRequired: Bool = false,
                defaultIsOn: Bool = false,
                conditions: [FormCondition] = [],
                validators: [FormValidator] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.isRequired = isRequired
        self.defaultIsOn = defaultIsOn
        self.conditions = conditions
        self.validators = validators
    }
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
    public let placeholder: String?
    public let defaultText: String?
    public let isSecure: Bool

    public var defaultValue: AnyCodableValue? {
        defaultText.map { .string($0) }
    }

    public init(id: String,
                title: String,
                subtitle: String? = nil,
                placeholder: String? = nil,
                isRequired: Bool = false,
                defaultText: String? = nil,
                isSecure: Bool = false,
                conditions: [FormCondition] = [],
                validators: [FormValidator] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.placeholder = placeholder
        self.isRequired = isRequired
        self.defaultText = defaultText
        self.isSecure = isSecure
        self.conditions = conditions
        self.validators = validators
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
    public let placeholder: String?
    public let kind: NumberKind
    private let _defaultValue: AnyCodableValue?

    public var defaultValue: AnyCodableValue? { _defaultValue }

    public init(id: String,
                title: String,
                subtitle: String? = nil,
                placeholder: String? = nil,
                isRequired: Bool = false,
                kind: NumberKind = .integer,
                defaultInt: Int? = nil,
                conditions: [FormCondition] = [],
                validators: [FormValidator] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.placeholder = placeholder
        self.isRequired = isRequired
        self.kind = kind
        _defaultValue = defaultInt.map { .int($0) }
        self.conditions = conditions
        self.validators = validators
    }

    public init(id: String,
                title: String,
                subtitle: String? = nil,
                placeholder: String? = nil,
                isRequired: Bool = false,
                defaultDouble: Double?,
                conditions: [FormCondition] = [],
                validators: [FormValidator] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.placeholder = placeholder
        self.isRequired = isRequired
        kind = .decimal
        _defaultValue = defaultDouble.map { .double($0) }
        self.conditions = conditions
        self.validators = validators
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
    public let placeholder: String?
    public let defaultEmail: String?

    public var defaultValue: AnyCodableValue? {
        defaultEmail.map { .string($0) }
    }

    public init(id: String,
                title: String,
                subtitle: String? = nil,
                placeholder: String? = "email@example.com",
                isRequired: Bool = false,
                defaultEmail: String? = nil,
                conditions: [FormCondition] = [],
                validators: [FormValidator] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.placeholder = placeholder
        self.isRequired = isRequired
        self.defaultEmail = defaultEmail
        self.conditions = conditions
        // Automatically prepend email format validator (fires onSave by default).
        var allValidators: [FormValidator] = [.email()]
        allValidators.append(contentsOf: validators)
        self.validators = allValidators
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
                               defaultSelection: T? = nil,
                               conditions: [FormCondition] = [],
                               validators: [FormValidator] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            isRequired: isRequired,
            options: options,
            defaultSelection: defaultSelection,
            conditions: conditions,
            validators: validators
        )
    }
}

public extension MultiValueRow {
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               subtitle: String? = nil,
                               isRequired: Bool = false,
                               options: [T]? = nil,
                               defaultSelections: Set<T> = [],
                               conditions: [FormCondition] = [],
                               validators: [FormValidator] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            isRequired: isRequired,
            options: options,
            defaultSelections: defaultSelections,
            conditions: conditions,
            validators: validators
        )
    }
}

public extension BooleanSwitchRow {
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               subtitle: String? = nil,
                               isRequired: Bool = false,
                               defaultIsOn: Bool = false,
                               conditions: [FormCondition] = [],
                               validators: [FormValidator] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            isRequired: isRequired,
            defaultIsOn: defaultIsOn,
            conditions: conditions,
            validators: validators
        )
    }
}

public extension TextInputRow {
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               subtitle: String? = nil,
                               placeholder: String? = nil,
                               isRequired: Bool = false,
                               defaultText: String? = nil,
                               isSecure: Bool = false,
                               conditions: [FormCondition] = [],
                               validators: [FormValidator] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            placeholder: placeholder,
            isRequired: isRequired,
            defaultText: defaultText,
            isSecure: isSecure,
            conditions: conditions,
            validators: validators
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
                               defaultInt: Int? = nil,
                               conditions: [FormCondition] = [],
                               validators: [FormValidator] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            placeholder: placeholder,
            isRequired: isRequired,
            kind: kind,
            defaultInt: defaultInt,
            conditions: conditions,
            validators: validators
        )
    }

    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               subtitle: String? = nil,
                               placeholder: String? = nil,
                               isRequired: Bool = false,
                               defaultDouble: Double?,
                               conditions: [FormCondition] = [],
                               validators: [FormValidator] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            placeholder: placeholder,
            isRequired: isRequired,
            defaultDouble: defaultDouble,
            conditions: conditions,
            validators: validators
        )
    }
}

public extension EmailInputRow {
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               subtitle: String? = nil,
                               placeholder: String? = "email@example.com",
                               isRequired: Bool = false,
                               defaultEmail: String? = nil,
                               conditions: [FormCondition] = [],
                               validators: [FormValidator] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            placeholder: placeholder,
            isRequired: isRequired,
            defaultEmail: defaultEmail,
            conditions: conditions,
            validators: validators
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
