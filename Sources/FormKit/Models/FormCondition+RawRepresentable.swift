import Foundation

// MARK: - FormCondition RawRepresentable Convenience

/// Overloads that accept `RawRepresentable` row IDs (e.g. `String`-backed enum cases)
/// instead of raw `String` values.
///
/// ```swift
/// enum RowID: String { case notifications, categories }
///
/// .isTrue(rowId: RowID.notifications)
/// .equals(rowId: RowID.categories, string: "sports")
/// ```
public extension FormCondition {
    static func equals<ID: RawRepresentable>(rowId: ID, value: AnyCodableValue) -> FormCondition where ID.RawValue == String {
        .equals(rowId: rowId.rawValue, value: value)
    }

    static func equals<ID: RawRepresentable>(rowId: ID, string: String) -> FormCondition where ID.RawValue == String {
        .equals(rowId: rowId.rawValue, value: .string(string))
    }

    static func equals<ID: RawRepresentable>(rowId: ID, int: Int) -> FormCondition where ID.RawValue == String {
        .equals(rowId: rowId.rawValue, value: .int(int))
    }

    static func equals<ID: RawRepresentable>(rowId: ID, bool: Bool) -> FormCondition where ID.RawValue == String {
        .equals(rowId: rowId.rawValue, value: .bool(bool))
    }

    static func notEquals<ID: RawRepresentable>(rowId: ID, value: AnyCodableValue) -> FormCondition where ID.RawValue == String {
        .notEquals(rowId: rowId.rawValue, value: value)
    }

    static func contains<ID: RawRepresentable>(rowId: ID, value: AnyCodableValue) -> FormCondition where ID.RawValue == String {
        .contains(rowId: rowId.rawValue, value: value)
    }

    static func notContains<ID: RawRepresentable>(rowId: ID, value: AnyCodableValue) -> FormCondition where ID.RawValue == String {
        .notContains(rowId: rowId.rawValue, value: value)
    }

    static func greaterThan<ID: RawRepresentable>(rowId: ID, value: AnyCodableValue) -> FormCondition where ID.RawValue == String {
        .greaterThan(rowId: rowId.rawValue, value: value)
    }

    static func greaterThanOrEqual<ID: RawRepresentable>(rowId: ID, value: AnyCodableValue) -> FormCondition where ID.RawValue == String {
        .greaterThanOrEqual(rowId: rowId.rawValue, value: value)
    }

    static func lessThan<ID: RawRepresentable>(rowId: ID, value: AnyCodableValue) -> FormCondition where ID.RawValue == String {
        .lessThan(rowId: rowId.rawValue, value: value)
    }

    static func lessThanOrEqual<ID: RawRepresentable>(rowId: ID, value: AnyCodableValue) -> FormCondition where ID.RawValue == String {
        .lessThanOrEqual(rowId: rowId.rawValue, value: value)
    }

    static func isEmpty<ID: RawRepresentable>(rowId: ID) -> FormCondition where ID.RawValue == String {
        .isEmpty(rowId: rowId.rawValue)
    }

    static func isNotEmpty<ID: RawRepresentable>(rowId: ID) -> FormCondition where ID.RawValue == String {
        .isNotEmpty(rowId: rowId.rawValue)
    }

    static func isTrue<ID: RawRepresentable>(rowId: ID) -> FormCondition where ID.RawValue == String {
        .isTrue(rowId: rowId.rawValue)
    }

    static func isFalse<ID: RawRepresentable>(rowId: ID) -> FormCondition where ID.RawValue == String {
        .isFalse(rowId: rowId.rawValue)
    }
}
