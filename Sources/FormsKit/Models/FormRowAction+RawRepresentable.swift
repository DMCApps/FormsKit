import Foundation

// MARK: - FormRowAction RawRepresentable Convenience

/// Overloads that accept `RawRepresentable` row IDs (e.g. `String`-backed enum cases)
/// instead of raw `String` values.
///
/// ```swift
/// enum RowID: String { case name, notifications }
///
/// BooleanSwitchRow(id: .notifications, title: "Notifications",
///     onChange: [
///         .showRow(id: RowID.name, when: [.isTrue(rowId: .notifications)])
///     ]
/// )
/// ```
public extension FormRowAction {
    /// `.showRow` accepting a `RawRepresentable` target row ID (enum case).
    static func showRow<ID: RawRepresentable>(id: ID,
                                              when conditions: [FormCondition] = [],
                                              timing: ActionTiming = .immediate) -> FormRowAction where ID.RawValue == String {
        .showRow(id: id.rawValue, when: conditions, timing: timing)
    }

    /// `.hideRow` accepting a `RawRepresentable` target row ID (enum case).
    static func hideRow<ID: RawRepresentable>(id: ID,
                                              when conditions: [FormCondition] = [],
                                              timing: ActionTiming = .immediate) -> FormRowAction where ID.RawValue == String {
        .hideRow(id: id.rawValue, when: conditions, timing: timing)
    }

    /// `.disableRow` accepting a `RawRepresentable` target row ID (enum case).
    static func disableRow<ID: RawRepresentable>(id: ID,
                                                 when conditions: [FormCondition] = [],
                                                 timing: ActionTiming = .immediate) -> FormRowAction where ID.RawValue == String {
        .disableRow(id: id.rawValue, when: conditions, timing: timing)
    }

    /// `.clearValue` accepting a `RawRepresentable` target row ID (enum case).
    static func clearValue<ID: RawRepresentable>(id: ID,
                                                 when conditions: [FormCondition] = [],
                                                 timing: ActionTiming = .immediate) -> FormRowAction where ID.RawValue == String {
        .clearValue(id: id.rawValue, when: conditions, timing: timing)
    }

    /// `.setValue` accepting a `RawRepresentable` target row ID (enum case).
    static func setValue<ID: RawRepresentable>(on targetRowId: ID,
                                               timing: ActionTiming = .immediate,
                                               value: @Sendable @escaping (_ store: FormValueStore) -> AnyCodableValue?) -> FormRowAction where ID.RawValue == String {
        .setValue(on: targetRowId.rawValue, timing: timing, value: value)
    }
}
