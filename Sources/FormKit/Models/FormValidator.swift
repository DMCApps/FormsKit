import Foundation

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

    /// The validation closure. Returns `nil` if valid, or an error message string if invalid.
    public let validate: @Sendable (AnyCodableValue?) -> String?

    public init(trigger: ValidationTrigger = .onSave,
                validate: @escaping @Sendable (AnyCodableValue?) -> String?) {
        self.trigger = trigger
        self.validate = validate
    }
}

// MARK: - Built-in Validators

public extension FormValidator {
    // MARK: Required

    /// The row must have a non-null, non-empty value.
    static func required(message: String = "This field is required",
                         trigger: ValidationTrigger = .onSave) -> FormValidator {
        FormValidator(trigger: trigger) { value in
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
                      trigger: ValidationTrigger = .onSave) -> FormValidator {
        FormValidator(trigger: trigger) { value in
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
                          trigger: ValidationTrigger = .onSave) -> FormValidator {
        let errorMessage = message ?? "Must be at least \(min) character\(min == 1 ? "" : "s")"
        return FormValidator(trigger: trigger) { value in
            guard let value, case let .string(s) = value else { return nil }
            return s.count < min ? errorMessage : nil
        }
    }

    /// The string value must have at most `max` characters.
    static func maxLength(_ max: Int,
                          message: String? = nil,
                          trigger: ValidationTrigger = .onSave) -> FormValidator {
        let errorMessage = message ?? "Must be at most \(max) character\(max == 1 ? "" : "s")"
        return FormValidator(trigger: trigger) { value in
            guard let value, case let .string(s) = value else { return nil }
            return s.count > max ? errorMessage : nil
        }
    }

    // MARK: Range

    /// The numeric value must be within the given closed range.
    static func range(_ range: ClosedRange<Double>,
                      message: String? = nil,
                      trigger: ValidationTrigger = .onSave) -> FormValidator {
        let errorMessage = message ?? "Must be between \(range.lowerBound) and \(range.upperBound)"
        return FormValidator(trigger: trigger) { value in
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
                      trigger: ValidationTrigger = .onSave) -> FormValidator {
        let errorMessage = message ?? "Must be between \(range.lowerBound) and \(range.upperBound)"
        return FormValidator(trigger: trigger) { value in
            guard let value, case let .int(v) = value else { return nil }
            return range.contains(v) ? nil : errorMessage
        }
    }

    // MARK: Regex

    /// The string value must match the given regular expression pattern.
    static func regex(_ pattern: String,
                      message: String = "Invalid format",
                      trigger: ValidationTrigger = .onSave) -> FormValidator {
        FormValidator(trigger: trigger) { value in
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
                       trigger: ValidationTrigger = .onSave) -> FormValidator {
        FormValidator(trigger: trigger) { value in
            guard case let .string(s) = value, !s.isEmpty else { return nil }
            return Swift.Double(s) != nil ? nil : message
        }
    }

    // MARK: IPv4

    /// The string value must be a valid IPv4 address (e.g. "192.168.1.1").
    /// Each octet must be 0–255. Passes when the field is empty.
    static func ipv4(message: String = "Must be a valid IPv4 address (e.g. 192.168.1.1)",
                     trigger: ValidationTrigger = .onSave) -> FormValidator {
        FormValidator(trigger: trigger) { value in
            guard case let .string(s) = value, !s.isEmpty else { return nil }
            let pattern = #"^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$"#
            guard s.range(of: pattern, options: .regularExpression) != nil else { return message }
            let valid = s.split(separator: ".").compactMap { Int($0) }.allSatisfy { $0 <= 255 }
            return valid ? nil : message
        }
    }

    // MARK: Custom

    /// A custom validator with a user-provided predicate.
    /// The predicate should return `true` when the value is VALID.
    static func custom(message: String,
                       trigger: ValidationTrigger = .onSave,
                       isValid: @escaping @Sendable (AnyCodableValue?) -> Bool) -> FormValidator {
        FormValidator(trigger: trigger) { value in
            isValid(value) ? nil : message
        }
    }

    // MARK: Not Empty (alias)

    /// Alias for `.required()` with clearer intent for non-text fields.
    static func notEmpty(message: String = "A selection is required",
                         trigger: ValidationTrigger = .onSave) -> FormValidator {
        required(message: message, trigger: trigger)
    }
}
