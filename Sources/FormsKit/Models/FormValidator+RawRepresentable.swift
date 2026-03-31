import Foundation

// MARK: - FormValidator RawRepresentable Convenience

/// Overloads that accept `RawRepresentable` row IDs (e.g. `String`-backed enum cases)
/// instead of raw `String` values.
///
/// ```swift
/// enum RowID: String { case password, confirmPassword }
///
/// TextInputRow(id: .confirmPassword, title: "Confirm Password",
///     validators: [.matches(rowId: RowID.password)])
/// ```
public extension FormValidator {
    /// `.matches` accepting a `RawRepresentable` reference row ID (enum case).
    static func matches<ID: RawRepresentable>(rowId: ID,
                                              message: String = "Values do not match",
                                              trigger: ValidationTrigger = .onSave,
                                              errorPosition: ErrorPosition = .belowRow) -> FormValidator where ID.RawValue == String {
        .matches(rowId: rowId.rawValue, message: message, trigger: trigger, errorPosition: errorPosition)
    }
}
