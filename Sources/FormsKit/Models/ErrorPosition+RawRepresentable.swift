import Foundation

// MARK: - ErrorPosition RawRepresentable Convenience

/// Overload that accepts a `RawRepresentable` row ID (e.g. a `String`-backed enum case)
/// instead of a raw `String`.
///
/// ```swift
/// enum RowID: String { case email, name }
///
/// FormValidator(errorPosition: .belowRow(id: RowID.email)) { ... }
/// ```
public extension ErrorPosition {
    /// Convenience factory accepting a `RawRepresentable` row ID (e.g. an enum case).
    static func belowRow<ID: RawRepresentable>(id: ID) -> ErrorPosition where ID.RawValue == String {
        .belowRow(id: id.rawValue)
    }
}
