import Foundation

// MARK: - FormCondition

/// Defines a visibility condition for a form row.
/// Conditions reference other rows by their ID and compare against the current FormValueStore.
/// Compose conditions using `.and` and `.or` for complex logic.
public enum FormCondition: Sendable {
    // MARK: Equality

    /// Visible when `store[rowId] == value`.
    case equals(rowId: String, value: AnyCodableValue)

    /// Visible when `store[rowId] != value`.
    case notEquals(rowId: String, value: AnyCodableValue)

    // MARK: Collection

    /// Visible when the multi-value row at `rowId` contains `value` in its array.
    case contains(rowId: String, value: AnyCodableValue)

    /// Visible when the multi-value row at `rowId` does NOT contain `value` in its array.
    case notContains(rowId: String, value: AnyCodableValue)

    // MARK: Comparison (numeric)

    /// Visible when `store[rowId] > value` (numeric comparison).
    case greaterThan(rowId: String, value: AnyCodableValue)

    /// Visible when `store[rowId] >= value` (numeric comparison).
    case greaterThanOrEqual(rowId: String, value: AnyCodableValue)

    /// Visible when `store[rowId] < value` (numeric comparison).
    case lessThan(rowId: String, value: AnyCodableValue)

    /// Visible when `store[rowId] <= value` (numeric comparison).
    case lessThanOrEqual(rowId: String, value: AnyCodableValue)

    // MARK: Existence

    /// Visible when `rowId` has no value or its value is `.null` or an empty string/array.
    case isEmpty(rowId: String)

    /// Visible when `rowId` has a non-null, non-empty value.
    case isNotEmpty(rowId: String)

    // MARK: Boolean Shorthand

    /// Visible when the boolean row at `rowId` is true.
    case isTrue(rowId: String)

    /// Visible when the boolean row at `rowId` is false.
    case isFalse(rowId: String)

    // MARK: Custom

    /// Visible when the custom predicate returns true.
    /// The predicate receives the full FormValueStore for maximum flexibility.
    case custom(@Sendable (FormValueStore) -> Bool)

    // MARK: Composition

    /// Visible when ALL sub-conditions are satisfied (logical AND).
    indirect case and([FormCondition])

    /// Visible when AT LEAST ONE sub-condition is satisfied (logical OR).
    indirect case or([FormCondition])

    /// Negates the wrapped condition.
    indirect case not(FormCondition)
}

// MARK: - Evaluation

public extension FormCondition {
    /// Evaluate this condition against the current form value store.
    /// Returns `true` if the row should be visible.
    func evaluate(with store: FormValueStore) -> Bool {
        switch self {
        case let .equals(rowId, expected):
            return store[rowId] == expected

        case let .notEquals(rowId, expected):
            return store[rowId] != expected

        case let .contains(rowId, value):
            return store.arrayContains(key: rowId, value: value)

        case let .notContains(rowId, value):
            return !store.arrayContains(key: rowId, value: value)

        case let .greaterThan(rowId, expected):
            guard let current = store[rowId] else { return false }
            return current > expected

        case let .greaterThanOrEqual(rowId, expected):
            guard let current = store[rowId] else { return false }
            return current >= expected

        case let .lessThan(rowId, expected):
            guard let current = store[rowId] else { return false }
            return current < expected

        case let .lessThanOrEqual(rowId, expected):
            guard let current = store[rowId] else { return false }
            return current <= expected

        case let .isEmpty(rowId):
            guard let value = store[rowId] else { return true }
            switch value {
            case .null: return true
            case let .string(s): return s.isEmpty
            case let .array(a): return a.isEmpty
            default: return false
            }

        case let .isNotEmpty(rowId):
            return !FormCondition.isEmpty(rowId: rowId).evaluate(with: store)

        case let .isTrue(rowId):
            return store[rowId] == .bool(true)

        case let .isFalse(rowId):
            let value = store[rowId]
            // Nil and .null both evaluate as true here: an unset (nil) row or an
            // explicitly cleared (.null) row is treated as falsy. This means newly
            // presented forms where a row has never been filled in will satisfy an
            // `.isFalse` condition. Document this so callers are not surprised.
            return value == .bool(false) || value == nil || value == .null

        case let .custom(predicate):
            return predicate(store)

        case let .and(conditions):
            return conditions.allSatisfy { $0.evaluate(with: store) }

        case let .or(conditions):
            return conditions.contains { $0.evaluate(with: store) }

        case let .not(condition):
            return !condition.evaluate(with: store)
        }
    }
}

// MARK: - Convenience Factory

public extension FormCondition {
    // MARK: Show / Hide Convenience

    /// A row is visible when `condition` evaluates to true.
    /// Semantically identical to using the condition directly, but reads more clearly
    /// when building row definitions:
    /// ```swift
    /// conditions: [.showIf(.isTrue(rowId: "enabled"))]
    /// // is the same as:
    /// conditions: [.isTrue(rowId: "enabled")]
    /// ```
    static func showIf(_ condition: FormCondition) -> FormCondition {
        condition
    }

    /// A row is visible when `condition` evaluates to false.
    /// Equivalent to `.not(condition)`.
    /// ```swift
    /// conditions: [.hideIf(.isTrue(rowId: "disabled"))]
    /// ```
    static func hideIf(_ condition: FormCondition) -> FormCondition {
        .not(condition)
    }

    // MARK: String Shorthands

    /// Shorthand for `.equals(rowId:value:)` with a string value.
    static func equals(rowId: String, string: String) -> FormCondition {
        .equals(rowId: rowId, value: .string(string))
    }

    /// Shorthand for `.equals(rowId:value:)` with an int value.
    static func equals(rowId: String, int: Int) -> FormCondition {
        .equals(rowId: rowId, value: .int(int))
    }

    /// Shorthand for `.equals(rowId:value:)` with a bool value.
    static func equals(rowId: String, bool: Bool) -> FormCondition {
        .equals(rowId: rowId, value: .bool(bool))
    }
}
