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

    // MARK: Disable / Enable

    /// Disable the row at `targetRowId` when ALL `conditions` evaluate to true against the
    /// current form store. Enable it when any condition fails.
    ///
    /// A disabled row remains visible but cannot be interacted with (input is blocked).
    /// Disabled rows are still included in validation and persistence.
    ///
    /// - Parameters:
    ///   - targetRowId: The ID of the row to disable or enable.
    ///   - conditions: `FormCondition` expressions evaluated against the full form store.
    ///     Empty conditions mean the target is always disabled.
    ///   - timing: When to evaluate — `.immediate` or `.debounced(_:)`.
    case disableRow(id: String, when: [FormCondition] = [], timing: ActionTiming = .immediate)

    // MARK: Hide Row

    /// Hide the row at `targetRowId` when ALL `conditions` evaluate to true.
    /// Show it again when any condition fails.
    ///
    /// Semantic inverse of `.showRow`: use whichever reads more naturally at the call site.
    /// `.hideRow(id: "x", when: [.isTrue(rowId: "disabled")])` is equivalent to
    /// `.showRow(id: "x", when: [.isFalse(rowId: "disabled")])`.
    ///
    /// - Parameters:
    ///   - targetRowId: The ID of the row to hide or show.
    ///   - conditions: Conditions under which the row is hidden.
    ///     Empty conditions mean the target is always hidden.
    ///   - timing: When to evaluate — `.immediate` or `.debounced(_:)`.
    case hideRow(id: String, when: [FormCondition] = [], timing: ActionTiming = .immediate)

    // MARK: Clear Value

    /// Clear the value of the row at `targetRowId` when ALL `conditions` evaluate to true.
    /// No-op when any condition fails.
    ///
    /// ```swift
    /// // Clear the custom endpoint field whenever the user disables the override toggle.
    /// BooleanSwitchRow(id: "useCustomEndpoint", title: "Use Custom Endpoint",
    ///     onChange: [
    ///         .clearValue(id: "endpoint", when: [.isFalse(rowId: "useCustomEndpoint")])
    ///     ])
    /// ```
    ///
    /// - Parameters:
    ///   - targetRowId: The ID of the row whose value should be cleared.
    ///   - conditions: Conditions under which the value is cleared.
    ///     Empty conditions mean the value is always cleared on every change.
    ///   - timing: When to fire — `.immediate` or `.debounced(_:)`.
    case clearValue(id: String, when: [FormCondition] = [], timing: ActionTiming = .immediate)

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
        case let .disableRow(_, _, timing): return timing
        case let .hideRow(_, _, timing): return timing
        case let .clearValue(_, _, timing): return timing
        case let .setValue(_, timing, _): return timing
        case let .runValidation(timing): return timing
        case let .custom(timing, _): return timing
        }
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

    /// An optional per-row style override attached directly to this row at definition time.
    ///
    /// Passed as the `style:` parameter in the row's initialiser.
    /// `DynamicFormView` reads this and merges it into `theme.rowOverrides` automatically.
    var rowStyle: (any FormRowStyle)? { get }
}

// MARK: - Default Implementations

public extension FormRow {
    var subtitle: String? { nil }
    var onChange: [FormRowAction] { [] }
    var validators: [FormValidator] { [] }
    var defaultValue: AnyCodableValue? { nil }
    var rowStyle: (any FormRowStyle)? { nil }
}

// MARK: - FormPickerStyle

/// Platform-independent picker style hint for `SingleValueRow`.
///
/// Not all styles are available on every platform. `SingleValueRowView` maps
/// each case to the closest supported SwiftUI `PickerStyle` for the current platform:
///
/// | Case          | iOS / iPadOS     | tvOS             |
/// |---------------|------------------|------------------|
/// | `.automatic`  | `.automatic`     | `.automatic`     |
/// | `.segmented`  | `.segmented`     | `.segmented`     |
/// | `.menu`       | `.menu`          | `.automatic`*    |
/// | `.navigationLink` | `.navigationLink` | `.automatic`* |
///
/// *Styles marked with `*` are not available on tvOS and fall back to `.automatic`.
public enum FormPickerStyle: Sendable {
    /// The default picker style for the current platform and context.
    case automatic
    /// A segmented control. Best for 2–5 short options. Available on iOS and tvOS.
    case segmented
    /// A menu button that reveals options when pressed. iOS / iPadOS only; falls back to `.automatic` on tvOS.
    case menu
    /// A navigation link that pushes a picker list. iOS / iPadOS only; falls back to `.automatic` on tvOS and macOS.
    case navigationLink
}

// MARK: - SingleValueRowRepresentable

/// Marker protocol that lets views work with `SingleValueRow<T>` without knowing `T`.
///
/// Each option is represented as a `(label:storedValue:)` pair:
/// - `label` is the human-readable string shown in the picker UI.
/// - `storedValue` is the stable value written to the backing store. For
///   `Codable`/`RawRepresentable` types this is the Codable rawValue, so
///   storage survives description renames without corrupting saved selections.
///
/// `defaultStoredValue` is the `storedValue` of the pre-selected option (or `nil`
/// when no default is configured). It seeds the initial store entry and drives the
/// picker's `selection` binding before any persisted value has been loaded.
public protocol SingleValueRowRepresentable: FormRow {
    /// `(label, storedValue)` pairs for every option, in display order.
    ///
    /// `label` is the human-readable string shown as the picker option.
    /// `storedValue` is the Codable rawValue written to the backing store —
    /// for `String`-backed enums this is the `rawValue`, not `description`.
    /// Falls back to `description` when the type's Codable representation is a
    /// JSON object/array that cannot be expressed as a scalar.
    var pickerOptions: [(label: String, storedValue: String)] { get }

    /// The `storedValue` of the default option, or `nil` when no default is set.
    ///
    /// Used to seed the initial backing-store entry and to drive the picker's
    /// `selection` binding before any persisted value has been loaded.
    var defaultStoredValue: String? { get }

    /// The preferred picker style for this row.
    var pickerStyle: FormPickerStyle { get }

    /// An optional placeholder label shown when no value is selected.
    /// Pass `nil` (the default) to show no placeholder — the picker will display
    /// whichever item SwiftUI naturally selects. Not shown for `.segmented` style.
    var placeholder: String? { get }
}

public extension SingleValueRowRepresentable {
    var placeholder: String? { nil }
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
    /// The per-row style attached via the `style:` init parameter at definition time, if any.
    public let rowStyle: (any FormRowStyle)?

    /// The underlying concrete row. Internal so views inside the module can cast it.
    let base: any FormRow

    public init(_ row: some FormRow) {
        id = row.id
        title = row.title
        subtitle = row.subtitle
        onChange = row.onChange
        validators = row.validators
        defaultValue = row.defaultValue
        rowStyle = row.rowStyle
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

    /// The preferred picker style. Defaults to `.automatic`.
    /// Styles unavailable on the current platform fall back to `.automatic`.
    public let pickerStyle: FormPickerStyle

    /// Optional placeholder shown when no value is selected. `nil` by default.
    /// Not shown for `.segmented` style.
    public let placeholder: String?
    
    public private(set) var rowStyle: (any FormRowStyle)?

    private let _defaultValue: T?

    public var defaultValue: AnyCodableValue? {
        _defaultValue.map { AnyCodableValue.from($0) }
    }

    // MARK: SingleValueRowRepresentable

    /// `(label, storedValue)` pairs for every option, in display order.
    ///
    /// `label` is sourced from `T.description`. `storedValue` is the Codable
    /// rawValue derived via `AnyCodableValue.from(_:)`. Falls back to `description`
    /// when the type encodes to a JSON object/array that cannot be expressed as a scalar.
    public var pickerOptions: [(label: String, storedValue: String)] {
        options.map { option in
            let encoded = AnyCodableValue.from(option)
            let storedValue = encoded != .null ? encoded.displayString : option.description
            return (label: option.description, storedValue: storedValue)
        }
    }

    /// The `storedValue` of the default option, or `nil` when no default is set.
    public var defaultStoredValue: String? {
        _defaultValue.map { option in
            let encoded = AnyCodableValue.from(option)
            return encoded != .null ? encoded.displayString : option.description
        }
    }

    public init(id: String,
                title: String,
                subtitle: String? = nil,
                options: [T]? = nil,
                defaultValue: T? = nil,
                pickerStyle: FormPickerStyle = .automatic,
                placeholder: String? = nil,
                validators: [SelectionValidator] = [],
                onChange: [FormRowAction] = [],
                style: SingleValueRowStyle? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.options = options ?? Array(T.allCases)
        _defaultValue = defaultValue
        self.pickerStyle = pickerStyle
        self.placeholder = placeholder
        self.validators = validators.map(\.asFormValidator)
        self.onChange = onChange
        self.rowStyle = style
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

    public private(set) var rowStyle: (any FormRowStyle)?

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
                validators: [SelectionValidator] = [],
                onChange: [FormRowAction] = [],
                style: MultiValueRowStyle? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.options = options ?? Array(T.allCases)
        _defaultValue = defaultValue
        self.validators = validators.map(\.asFormValidator)
        self.onChange = onChange
        self.rowStyle = style
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
    public private(set) var rowStyle: (any FormRowStyle)?

    private let _defaultValue: Bool

    public var defaultValue: AnyCodableValue? { .bool(_defaultValue) }

    public init(id: String,
                title: String,
                subtitle: String? = nil,
                defaultValue: Bool = false,
                validators: [SelectionValidator] = [],
                onChange: [FormRowAction] = [],
                style: BooleanSwitchRowStyle? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        _defaultValue = defaultValue
        self.validators = validators.map(\.asFormValidator)
        self.onChange = onChange
        self.rowStyle = style
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

// MARK: - FormInputMask

/// Describes a fixed-format input mask for a `TextInputRow`.
///
/// The mask pattern uses special placeholder characters to define where
/// the user may type, and literal characters that are inserted automatically:
///
/// | Character | Accepts              |
/// |-----------|----------------------|
/// | `#`       | Any digit (0–9)      |
/// | `A`       | Any letter (a–z A–Z) |
/// | `*`       | Any character        |
/// | other     | Literal — auto-inserted |
///
/// The stored value contains **only the characters the user typed** (no literals).
/// By default the raw chars are stored as `.string`. Supply a `toStorable` closure
/// to convert the raw chars to a typed `AnyCodableValue` (e.g. `.date(Date)`), and
/// a matching `fromStorable` closure to recover the raw chars from that stored value.
///
/// ```swift
/// // Phone number: displays "(415) 555-1234", stores "4155551234" as .string
/// TextInputRow(id: "phone", title: "Phone", mask: .usPhone)
///
/// // Date: displays "12/25/2026", stores a typed Date as .date(Date)
/// TextInputRow(id: "dob", title: "Date of Birth", mask: .date)
///
/// // Custom: stores a typed value of your own choosing
/// TextInputRow(id: "ref", title: "Reference", mask: FormInputMask("##-##-####",
///     toStorable: { rawChars in .string(rawChars.uppercased()) },
///     fromStorable: { stored in stored.typed(String.self) }))
/// ```
public struct FormInputMask: Sendable {
    /// The mask pattern string.
    public let pattern: String

    /// Converts the completed raw slot characters to the value that gets written to the
    /// store. Return `nil` to fall back to storing the raw chars as `.string`.
    /// Only called when the input is complete (length == `maxInputLength`).
    let toStorable: (@Sendable (_ rawChars: String) -> AnyCodableValue?)?

    /// Recovers the raw slot characters from a stored `AnyCodableValue` so the field
    /// can be pre-populated. Return `nil` to fall back to reading the value as `.string`.
    let fromStorable: (@Sendable (_ stored: AnyCodableValue) -> String?)?

    /// Creates a plain-text mask with no typed-value conversion.
    /// - Parameter pattern: Format string using `#` (digit), `A` (letter),
    ///   `*` (any char), and literal characters.
    public init(_ pattern: String) {
        self.pattern = pattern
        toStorable = nil
        fromStorable = nil
    }

    /// Creates a mask with custom typed-value conversion.
    /// - Parameters:
    ///   - pattern: Format string using `#` (digit), `A` (letter), `*` (any char),
    ///     and literal characters.
    ///   - toStorable: Converts completed raw slot characters to a typed
    ///     `AnyCodableValue`. Return `nil` to store as `.string` instead.
    ///   - fromStorable: Recovers raw slot characters from a stored value for display.
    ///     Return `nil` to read as `.string` instead.
    public init(_ pattern: String,
                toStorable: (@Sendable (_ rawChars: String) -> AnyCodableValue?)?,
                fromStorable: (@Sendable (_ stored: AnyCodableValue) -> String?)?) {
        self.pattern = pattern
        self.toStorable = toStorable
        self.fromStorable = fromStorable
    }

    // MARK: - Common Presets

    /// US phone number: `(###) ###-####`
    /// Stored as raw digits, e.g. `"4155551234"` (`.string`).
    public static let usPhone = FormInputMask("(###) ###-####")

    /// Date: `##/##/####` (MM/DD/YYYY display).
    /// Stored as a typed `Date` (`.date(Date)`).
    public static let date: FormInputMask = {
        let fmt = "MMddyyyy"
        return FormInputMask(
            "##/##/####",
            toStorable: { rawChars in
                guard !rawChars.isEmpty else { return nil }
                let parser = DateFormatter()
                parser.dateFormat = fmt
                parser.isLenient = false
                guard let date = parser.date(from: rawChars) else { return nil }
                return .date(date)
            },
            fromStorable: { stored in
                guard case let .date(date) = stored else { return nil }
                let writer = DateFormatter()
                writer.dateFormat = fmt
                return writer.string(from: date)
            }
        )
    }()

    /// Characters in the pattern that act as user-input slots.
    static let slotCharacters: Set<Character> = ["#", "A", "*"]

    /// Returns true if a character satisfies the given mask slot character.
    static func character(_ char: Character, satisfies slot: Character) -> Bool {
        switch slot {
        case "#": return char.isNumber
        case "A": return char.isLetter
        case "*": return true
        default: return false
        }
    }

    /// Applies `inputChars` (raw user input, no literals) into the mask pattern,
    /// returning the formatted display string.
    func apply(to inputChars: String) -> String {
        var result = ""
        var inputIndex = inputChars.startIndex

        for maskChar in pattern {
            guard inputIndex < inputChars.endIndex else { break }
            if Self.slotCharacters.contains(maskChar) {
                let inputChar = inputChars[inputIndex]
                if Self.character(inputChar, satisfies: maskChar) {
                    result.append(inputChar)
                    inputIndex = inputChars.index(after: inputIndex)
                } else {
                    // Invalid character for this slot — stop formatting.
                    break
                }
            } else {
                // Literal — auto-insert it.
                result.append(maskChar)
            }
        }
        return result
    }

    /// Strips all literal characters from a formatted string, returning only
    /// the raw input characters.
    ///
    /// This implementation extracts all characters from `formatted` that are not
    /// literal pattern characters. This correctly handles both fully-formatted strings
    /// (e.g. `"(415) 555-1234"`) and partially-typed strings where the mask literals
    /// have not yet been inserted (e.g. a raw digit string `"4155551234"`).
    func strip(from formatted: String) -> String {
        // Collect the set of literal characters used in this mask pattern.
        let literals = Set(pattern.filter { !Self.slotCharacters.contains($0) })
        // Return only the characters that are not literals.
        return formatted.filter { !literals.contains($0) }
    }

    /// The maximum number of raw (non-literal) characters the mask accepts.
    var maxInputLength: Int {
        pattern.filter { Self.slotCharacters.contains($0) }.count
    }
}

// MARK: - FormInputMask + Equatable

extension FormInputMask: Equatable {
    /// Two masks are equal when they share the same `pattern`.
    /// Closure identity is not considered — use the pattern as the stable identity.
    public static func == (lhs: FormInputMask, rhs: FormInputMask) -> Bool {
        lhs.pattern == rhs.pattern
    }
}

// MARK: - TextInputRow

/// A free-text input row. Supports secure (password) input and optional input masks.
public struct TextInputRow: FormRow {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let onChange: [FormRowAction]
    public let validators: [FormValidator]
    public let isSecure: Bool
    /// When `true` and `isSecure` is `true`, renders an eye button inside the field
    /// that the user can tap to reveal or re-hide the input.
    public let showSecureToggle: Bool
    public let keyboardType: FormKeyboardType
    /// Hint text shown when the field is empty. Ignored when `mask` is set.
    public let placeholder: String?
    /// Optional input mask. When set, user input is constrained to the mask pattern,
    /// the formatted value (with literals) is shown in the field, and the mask pattern
    /// is used as the placeholder — `placeholder` is ignored when a mask is present.
    /// The stored value contains only the raw typed characters (no literals).
    public let mask: FormInputMask?
    public private(set) var rowStyle: (any FormRowStyle)?

    private let _defaultValue: String?

    public var defaultValue: AnyCodableValue? {
        _defaultValue.map { .string($0) }
    }

    public init(id: String,
                title: String,
                subtitle: String? = nil,
                defaultValue: String? = nil,
                isSecure: Bool = false,
                showSecureToggle: Bool = false,
                keyboardType: FormKeyboardType = .default,
                placeholder: String? = nil,
                mask: FormInputMask? = nil,
                validators: [FormValidator] = [],
                onChange: [FormRowAction] = [],
                style: TextInputRowStyle? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.placeholder = placeholder
        _defaultValue = defaultValue
        self.isSecure = isSecure
        self.showSecureToggle = showSecureToggle
        self.keyboardType = keyboardType
        self.mask = mask
        self.validators = validators
        self.onChange = onChange
        self.rowStyle = style
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
    public private(set) var rowStyle: (any FormRowStyle)?

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
                onChange: [FormRowAction] = [],
                style: NumberInputRowStyle? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.placeholder = placeholder
        _kind = kind
        self.validators = validators
        self.onChange = onChange
        self.rowStyle = style
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
    public private(set) var rowStyle: (any FormRowStyle)?

    /// The action to perform when the button is tapped.
    public let action: @Sendable () -> Void

    public init(id: String,
                title: String,
                subtitle: String? = nil,
                onChange: [FormRowAction] = [],
                style: ButtonRowStyle? = nil,
                action: @Sendable @escaping () -> Void) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.onChange = onChange
        self.rowStyle = style
        self.action = action
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
    public private(set) var rowStyle: (any FormRowStyle)?

    /// Closure evaluated at render time to produce the value string shown on the trailing side.
    public let value: () -> String

    public init(id: String, title: String, style: InfoRowStyle? = nil, value: @escaping () -> String) {
        self.id = id
        self.title = title
        self.rowStyle = style
        self.value = value
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

// MARK: - CollapsibleSection

/// A container row that groups child rows under a collapsible header.
///
/// Unlike `FormSection`, which always shows its children, a `CollapsibleSection`
/// renders a tappable header with a disclosure arrow. When collapsed, only the
/// header is visible; when expanded, all child rows appear below it.
///
/// The expand/collapse state is transient UI state managed by `FormViewModel`
/// — it is NOT persisted to the form value store.
///
/// ```swift
/// FormDefinition(id: "settings", title: "Settings") {
///     CollapsibleSection(id: "advanced", title: "Advanced Settings") {
///         TextInputRow(id: "timeout", title: "Timeout")
///         NumberInputRow(id: "retries", title: "Retries")
///     }
/// }
/// ```
public struct CollapsibleSection: FormRow, @unchecked Sendable {
    public let id: String
    public let title: String
    public let subtitle: String? = nil
    public let onChange: [FormRowAction]
    public let validators: [FormValidator] = []
    public let defaultValue: AnyCodableValue? = nil
    public private(set) var rowStyle: (any FormRowStyle)?

    /// Whether this section starts expanded. Defaults to `true`.
    public let isExpandedByDefault: Bool

    /// The child rows contained in this section.
    public let rows: [AnyFormRow]

    // MARK: Initialisers

    /// Create a collapsible section with a pre-built array of rows.
    public init(id: String,
                title: String,
                isExpandedByDefault: Bool = true,
                rows: [AnyFormRow],
                onChange: [FormRowAction] = [],
                style: CollapsibleSectionStyle? = nil) {
        self.id = id
        self.title = title
        self.isExpandedByDefault = isExpandedByDefault
        self.rows = rows
        self.onChange = onChange
        self.rowStyle = style
    }

    /// Create a collapsible section using the `@FormRowBuilder` DSL.
    ///
    /// ```swift
    /// CollapsibleSection(id: "account", title: "Account") {
    ///     TextInputRow(id: "name", title: "Name")
    ///     TextInputRow(id: "email", title: "Email")
    /// }
    /// ```
    public init(id: String,
                title: String,
                isExpandedByDefault: Bool = true,
                onChange: [FormRowAction] = [],
                style: CollapsibleSectionStyle? = nil,
                @FormRowBuilder rows: () -> [AnyFormRow]) {
        self.id = id
        self.title = title
        self.isExpandedByDefault = isExpandedByDefault
        self.rows = rows()
        self.onChange = onChange
        self.rowStyle = style
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
    public private(set) var rowStyle: (any FormRowStyle)?

    /// The sub-form this row navigates to.
    public let destination: FormDefinition

    /// Navigation rows carry no editable value.
    public var defaultValue: AnyCodableValue? { nil }

    public init(id: String,
                title: String,
                subtitle: String? = nil,
                destination: FormDefinition,
                onChange: [FormRowAction] = [],
                style: NavigationRowStyle? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.destination = destination
        self.onChange = onChange
        self.rowStyle = style
    }
}
