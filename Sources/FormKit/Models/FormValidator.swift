import Foundation

// MARK: - ErrorPosition

/// Controls where a validator's error message is displayed in the form UI.
public enum ErrorPosition: Sendable, Equatable {
    /// Display the error below the row that owns the validator (default).
    /// Pass `nil` for `id` (or use the `.belowRow` static property) for the owning row.
    /// Pass a non-nil `id` to display the error below a different row.
    case belowRow(id: String? = nil)

    /// Display the error at the top of the form, above all rows.
    case formTop

    /// Display the error at the bottom of the form, above the save button.
    case formBottom

    /// Display the error in a dismissible alert dialog.
    case alert
}

public extension ErrorPosition {
    /// Convenience static property for the default "below the owning row" position.
    static var belowRow: ErrorPosition { .belowRow(id: nil) }
}

// MARK: - ValidationTrigger

/// Controls when a validator fires.
public enum ValidationTrigger: Sendable, Equatable {
    /// Fires only when the user taps the Save button.
    case onSave

    /// Fires after the user pauses typing for the given number of seconds.
    case onDebouncedInput(seconds: Double)

    /// Fires immediately on every value change.
    case onChange

    // MARK: Equatable

    public static func == (lhs: ValidationTrigger, rhs: ValidationTrigger) -> Bool {
        switch (lhs, rhs) {
        case (.onSave, .onSave):
            return true
        case (.onChange, .onChange):
            return true
        case let (.onDebouncedInput(a), .onDebouncedInput(b)):
            return a == b
        default:
            return false
        }
    }

    /// Returns true if this trigger is a debounced-input trigger (regardless of duration).
    var isDebouncedInput: Bool {
        if case .onDebouncedInput = self { return true }
        return false
    }

    /// The debounce duration in seconds, or nil if not a debounced trigger.
    var debounceDuration: Double? {
        if case let .onDebouncedInput(seconds) = self { return seconds }
        return nil
    }
}

// MARK: - FormValidator

/// A validator that inspects a row's current value and optionally returns an error message.
/// Validators are attached per-row and fire based on their `trigger`.
public struct FormValidator: Sendable {
    /// When this validator fires.
    public let trigger: ValidationTrigger

    /// Where the error message is displayed in the form UI. Defaults to `.belowRow`.
    public let errorPosition: ErrorPosition

    /// The validation closure. Returns `nil` if valid, or an error message string if invalid.
    /// Used by validators that only need the row's own value.
    public let validate: @Sendable (AnyCodableValue?) -> String?

    /// Optional store-aware validation closure.
    /// When non-nil, this is called instead of `validate`, giving the validator access to
    /// the full `FormValueStore` for cross-row comparisons (e.g. `.matches`).
    public let validateWithStore: (@Sendable (AnyCodableValue?, FormValueStore) -> String?)?

    /// Create a standard single-value validator.
    public init(trigger: ValidationTrigger = .onSave,
                errorPosition: ErrorPosition = .belowRow,
                validate: @escaping @Sendable (AnyCodableValue?) -> String?) {
        self.trigger = trigger
        self.errorPosition = errorPosition
        self.validate = validate
        validateWithStore = nil
    }

    /// Create a store-aware validator that can read other rows' values.
    /// Use this for cross-row validation (e.g. "confirm password must match password").
    public init(trigger: ValidationTrigger = .onSave,
                errorPosition: ErrorPosition = .belowRow,
                validate: @escaping @Sendable (AnyCodableValue?, FormValueStore) -> String?) {
        self.trigger = trigger
        self.errorPosition = errorPosition
        self.validate = { _ in nil } // unused when validateWithStore is set
        validateWithStore = validate
    }
}

// MARK: - Built-in Validators

public extension FormValidator {
    // MARK: Required

    /// The row must have a non-null, non-empty value.
    static func required(message: String = "This field is required",
                         trigger: ValidationTrigger = .onSave,
                         errorPosition: ErrorPosition = .belowRow) -> FormValidator {
        FormValidator(trigger: trigger, errorPosition: errorPosition) { value in
            guard let value else { return message }
            switch value {
            case .null:
                return message
            case let .string(s) where s.trimmingCharacters(in: .whitespaces).isEmpty:
                return message
            case let .array(a) where a.isEmpty:
                return message
            default:
                return nil
            }
        }
    }

    // MARK: Email

    /// The row value must be a syntactically valid email address.
    /// Does not enforce that the row is non-empty — combine with `.required()` for that.
    static func email(message: String = "Please enter a valid email address",
                      trigger: ValidationTrigger = .onSave,
                      errorPosition: ErrorPosition = .belowRow) -> FormValidator {
        FormValidator(trigger: trigger, errorPosition: errorPosition) { value in
            guard let value, case let .string(s) = value, !s.isEmpty else {
                return nil
            }
            let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
            guard s.range(of: pattern, options: .regularExpression) != nil else {
                return message
            }
            return nil
        }
    }

    // MARK: Length

    /// The string value must have at least `min` characters.
    static func minLength(_ min: Int,
                          message: String? = nil,
                          trigger: ValidationTrigger = .onSave,
                          errorPosition: ErrorPosition = .belowRow) -> FormValidator {
        let errorMessage = message ?? "Must be at least \(min) character\(min == 1 ? "" : "s")"
        return FormValidator(trigger: trigger, errorPosition: errorPosition) { value in
            guard let value, case let .string(s) = value else { return nil }
            return s.count < min ? errorMessage : nil
        }
    }

    /// The string value must have at most `max` characters.
    static func maxLength(_ max: Int,
                          message: String? = nil,
                          trigger: ValidationTrigger = .onSave,
                          errorPosition: ErrorPosition = .belowRow) -> FormValidator {
        let errorMessage = message ?? "Must be at most \(max) character\(max == 1 ? "" : "s")"
        return FormValidator(trigger: trigger, errorPosition: errorPosition) { value in
            guard let value, case let .string(s) = value else { return nil }
            return s.count > max ? errorMessage : nil
        }
    }

    // MARK: Range

    /// The numeric value must be within the given closed range.
    static func range(_ range: ClosedRange<Double>,
                      message: String? = nil,
                      trigger: ValidationTrigger = .onSave,
                      errorPosition: ErrorPosition = .belowRow) -> FormValidator {
        let errorMessage = message ?? "Must be between \(range.lowerBound) and \(range.upperBound)"
        return FormValidator(trigger: trigger, errorPosition: errorPosition) { value in
            guard let value else { return nil }
            let numericValue: Double? = switch value {
            case let .int(v): Double(v)
            case let .double(v): v
            default: nil
            }
            guard let num = numericValue else { return nil }
            return range.contains(num) ? nil : errorMessage
        }
    }

    /// The integer value must be within the given closed range.
    static func range(_ range: ClosedRange<Int>,
                      message: String? = nil,
                      trigger: ValidationTrigger = .onSave,
                      errorPosition: ErrorPosition = .belowRow) -> FormValidator {
        let errorMessage = message ?? "Must be between \(range.lowerBound) and \(range.upperBound)"
        return FormValidator(trigger: trigger, errorPosition: errorPosition) { value in
            guard let value, case let .int(v) = value else { return nil }
            return range.contains(v) ? nil : errorMessage
        }
    }

    // MARK: Regex

    /// The string value must match the given regular expression pattern.
    static func regex(_ pattern: String,
                      message: String = "Invalid format",
                      trigger: ValidationTrigger = .onSave,
                      errorPosition: ErrorPosition = .belowRow) -> FormValidator {
        FormValidator(trigger: trigger, errorPosition: errorPosition) { value in
            guard let value, case let .string(s) = value, !s.isEmpty else { return nil }
            guard s.range(of: pattern, options: .regularExpression) != nil else {
                return message
            }
            return nil
        }
    }

    // MARK: Double

    /// The string value must parse as a valid Double (e.g. "37.7833" or "-122.4167").
    /// Passes when the field is empty — combine with `.required()` to enforce a value.
    static func double(message: String = "Must be a valid decimal number",
                       trigger: ValidationTrigger = .onSave,
                       errorPosition: ErrorPosition = .belowRow) -> FormValidator {
        FormValidator(trigger: trigger, errorPosition: errorPosition) { value in
            guard case let .string(s) = value, !s.isEmpty else { return nil }
            return Swift.Double(s) != nil ? nil : message
        }
    }

    // MARK: IPv4

    /// The string value must be a valid IPv4 address (e.g. "192.168.1.1").
    /// Each octet must be 0–255. Passes when the field is empty.
    static func ipv4(message: String = "Must be a valid IPv4 address (e.g. 192.168.1.1)",
                     trigger: ValidationTrigger = .onSave,
                     errorPosition: ErrorPosition = .belowRow) -> FormValidator {
        FormValidator(trigger: trigger, errorPosition: errorPosition) { value in
            guard case let .string(s) = value, !s.isEmpty else { return nil }
            let pattern = #"^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$"#
            guard s.range(of: pattern, options: .regularExpression) != nil else { return message }
            let valid = s.split(separator: ".").compactMap { Int($0) }.allSatisfy { $0 <= 255 }
            return valid ? nil : message
        }
    }

    // MARK: Date

    /// The value must represent a valid calendar date.
    ///
    /// Accepts both a typed `AnyCodableValue.date(Date)` (stored by the `.date` mask)
    /// and a formatted string. When used with the built-in `.date` mask no `format`
    /// parameter is needed — the mask commits a typed `Date` directly.
    ///
    /// ```swift
    /// // With the built-in .date mask (stores a typed Date)
    /// TextInputRow(id: "dob", title: "Date of Birth",
    ///              mask: .date,
    ///              validators: [.date()])
    ///
    /// // With a pre-formatted string (e.g. "12/25/2026")
    /// TextInputRow(id: "dob", title: "Date of Birth",
    ///              validators: [.date(format: "MM/dd/yyyy")])
    /// ```
    ///
    /// Passes when the field is empty — combine with `.required()` to enforce a value.
    /// - Parameters:
    ///   - format: The `DateFormatter` format string the string input must satisfy.
    ///     Optional when using the `.date` mask (which stores a typed `Date`).
    ///   - message: Error message shown when the date is invalid.
    ///   - trigger: When to fire the validator.
    static func date(format: String? = nil,
                     message: String = "Please enter a valid date",
                     trigger: ValidationTrigger = .onSave,
                     errorPosition: ErrorPosition = .belowRow) -> FormValidator {
        FormValidator(trigger: trigger, errorPosition: errorPosition) { value in
            switch value {
            case .date:
                // Already a typed Date — always valid.
                return nil
            case let .string(s) where !s.isEmpty:
                guard let fmt = format else { return nil }
                let formatter = DateFormatter()
                formatter.dateFormat = fmt
                formatter.isLenient = false
                return formatter.date(from: s) != nil ? nil : message
            default:
                return nil
            }
        }
    }

    // MARK: Custom

    /// A custom validator with a user-provided predicate.
    /// The predicate should return `true` when the value is VALID.
    static func custom(message: String,
                       trigger: ValidationTrigger = .onSave,
                       errorPosition: ErrorPosition = .belowRow,
                       isValid: @escaping @Sendable (AnyCodableValue?) -> Bool) -> FormValidator {
        FormValidator(trigger: trigger, errorPosition: errorPosition) { value in
            isValid(value) ? nil : message
        }
    }

    // MARK: Not Empty (alias)

    /// Alias for `.required()` with clearer intent for non-text fields.
    static func notEmpty(message: String = "A selection is required",
                         trigger: ValidationTrigger = .onSave,
                         errorPosition: ErrorPosition = .belowRow) -> FormValidator {
        required(message: message, trigger: trigger, errorPosition: errorPosition)
    }

    // MARK: URL

    /// The string value must be a well-formed URL with a non-empty scheme (e.g. "https://example.com").
    /// Passes when the field is empty — combine with `.required()` to enforce a value.
    static func url(message: String = "Must be a valid URL",
                    trigger: ValidationTrigger = .onSave,
                    errorPosition: ErrorPosition = .belowRow) -> FormValidator {
        FormValidator(trigger: trigger, errorPosition: errorPosition) { value in
            guard case let .string(s) = value, !s.isEmpty else { return nil }
            guard let parsed = URL(string: s), parsed.scheme?.isEmpty == false else {
                return message
            }
            return nil
        }
    }

    // MARK: Integer

    /// The string value must parse as a valid integer (e.g. "42" or "-7").
    /// Passes when the field is empty — combine with `.required()` to enforce a value.
    static func integer(message: String = "Must be a whole number",
                        trigger: ValidationTrigger = .onSave,
                        errorPosition: ErrorPosition = .belowRow) -> FormValidator {
        FormValidator(trigger: trigger, errorPosition: errorPosition) { value in
            guard case let .string(s) = value, !s.isEmpty else { return nil }
            return Int(s) != nil ? nil : message
        }
    }

    // MARK: Matches

    /// This row's value must equal the value of another row (e.g. "confirm password").
    /// Uses the store-aware validator initialiser so it can read the reference row at validation time.
    ///
    /// ```swift
    /// TextInputRow(id: "confirmPassword", title: "Confirm Password", isSecure: true,
    ///     validators: [.matches(rowId: "password", message: "Passwords must match")])
    /// ```
    static func matches(rowId: String,
                        message: String = "Values do not match",
                        trigger: ValidationTrigger = .onSave,
                        errorPosition: ErrorPosition = .belowRow) -> FormValidator {
        FormValidator(trigger: trigger, errorPosition: errorPosition) { value, store in
            guard value != store[rowId] else { return nil }
            return message
        }
    }
}
