import Foundation

// MARK: - FormViewModel RawRepresentable Convenience

/// Overloads that accept `RawRepresentable` row IDs (e.g. `String`-backed enum cases)
/// instead of raw `String` values.
///
/// ```swift
/// enum SettingsRowID: String { case username, notifications }
///
/// viewModel.value(for: .username)
/// viewModel.setBool(true, for: .notifications)
/// ```
@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
public extension FormViewModel {
    /// Returns a typed value for the given row ID (enum case overload).
    func value<T: Decodable, ID: RawRepresentable>(for rowId: ID) -> T? where ID.RawValue == String {
        value(for: rowId.rawValue)
    }

    /// Returns the raw `AnyCodableValue` for the given row ID (enum case overload).
    func rawValue<ID: RawRepresentable>(for rowId: ID) -> AnyCodableValue? where ID.RawValue == String {
        rawValue(for: rowId.rawValue)
    }

    /// Set a raw `AnyCodableValue` for a row (enum case overload).
    func setValue(_ value: AnyCodableValue?, for rowId: some RawRepresentable<String>) {
        setValue(value, for: rowId.rawValue)
    }

    /// Convenience: set a `Bool` value (enum case overload).
    func setBool(_ value: Bool, for rowId: some RawRepresentable<String>) {
        setBool(value, for: rowId.rawValue)
    }

    /// Convenience: set a `String` value (enum case overload).
    func setString(_ value: String, for rowId: some RawRepresentable<String>) {
        setString(value, for: rowId.rawValue)
    }

    /// Convenience: set an `Int` value (enum case overload).
    func setInt(_ value: Int, for rowId: some RawRepresentable<String>) {
        setInt(value, for: rowId.rawValue)
    }

    /// Convenience: set a `Double` value (enum case overload).
    func setDouble(_ value: Double, for rowId: some RawRepresentable<String>) {
        setDouble(value, for: rowId.rawValue)
    }

    /// Convenience: set a `Date` value (enum case overload).
    func setDate(_ value: Date, for rowId: some RawRepresentable<String>) {
        setDate(value, for: rowId.rawValue)
    }

    /// Toggle an element in a multi-value array row (enum case overload).
    func toggleArrayValue(_ value: AnyCodableValue, for rowId: some RawRepresentable<String>) {
        toggleArrayValue(value, for: rowId.rawValue)
    }

    /// Returns the validation errors for a specific row (enum case overload).
    func errorsForRow(_ rowId: some RawRepresentable<String>) -> [String] {
        errorsForRow(rowId.rawValue)
    }

    /// True if the row currently has validation errors (enum case overload).
    func rowHasError(_ rowId: some RawRepresentable<String>) -> Bool {
        rowHasError(rowId.rawValue)
    }

    /// Notify the view model that a field has lost focus (enum case overload).
    func rowDidBlur(_ rowId: some RawRepresentable<String>) {
        rowDidBlur(rowId.rawValue)
    }

    /// Toggle the expanded/collapsed state of a `CollapsibleSection` (enum case overload).
    func toggleSection(_ sectionId: some RawRepresentable<String>) {
        toggleSection(sectionId.rawValue)
    }

    /// Returns `true` if the `CollapsibleSection` is currently expanded (enum case overload).
    func isSectionExpanded(_ sectionId: some RawRepresentable<String>) -> Bool {
        isSectionExpanded(sectionId.rawValue)
    }
}
