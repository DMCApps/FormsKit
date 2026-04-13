import Foundation

// MARK: - Row Type RawRepresentable Row ID Overloads

/// Overloads for all concrete row types that accept a `RawRepresentable` ID
/// (e.g. a `String`-backed enum case) instead of a raw `String`.
///
/// ```swift
/// enum SettingsRowID: String { case username, notifications, theme }
///
/// TextInputRow(id: .username, title: "Username")
/// BooleanSwitchRow(id: .notifications, title: "Enable Notifications")
/// ```

public extension SingleValueRow {
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               subtitle: String? = nil,
                               options: [T]? = nil,
                               defaultValue: T? = nil,
                               pickerStyle: FormPickerStyle = .automatic,
                               validators: [SelectionValidator] = [],
                               onChange: [FormRowAction] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            options: options,
            defaultValue: defaultValue,
            pickerStyle: pickerStyle,
            validators: validators,
            onChange: onChange
        )
    }
}

public extension MultiValueRow {
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               subtitle: String? = nil,
                               options: [T]? = nil,
                               defaultValue: Set<T> = [],
                               validators: [SelectionValidator] = [],
                               onChange: [FormRowAction] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            options: options,
            defaultValue: defaultValue,
            validators: validators,
            onChange: onChange
        )
    }
}

public extension BooleanSwitchRow {
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               subtitle: String? = nil,
                               defaultValue: Bool = false,
                               validators: [SelectionValidator] = [],
                               onChange: [FormRowAction] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            defaultValue: defaultValue,
            validators: validators,
            onChange: onChange
        )
    }
}

public extension TextInputRow {
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               subtitle: String? = nil,
                               defaultValue: String? = nil,
                               isSecure: Bool = false,
                               showSecureToggle: Bool = false,
                               keyboardType: FormKeyboardType = .default,
                               placeholder: String? = nil,
                               mask: FormInputMask? = nil,
                               validators: [FormValidator] = [],
                               onChange: [FormRowAction] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            defaultValue: defaultValue,
            isSecure: isSecure,
            showSecureToggle: showSecureToggle,
            keyboardType: keyboardType,
            placeholder: placeholder,
            mask: mask,
            validators: validators,
            onChange: onChange
        )
    }
}

public extension NumberInputRow {
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               subtitle: String? = nil,
                               placeholder: String? = nil,
                               kind: NumberKind = .int(defaultValue: nil),
                               validators: [FormValidator] = [],
                               onChange: [FormRowAction] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            placeholder: placeholder,
            kind: kind,
            validators: validators,
            onChange: onChange
        )
    }
}

public extension ButtonRow {
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               subtitle: String? = nil,
                               onChange: [FormRowAction] = [],
                               action: @MainActor @Sendable @escaping () -> Void) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            onChange: onChange,
            action: action
        )
    }
}

public extension InfoRow {
    init<ID: RawRepresentable>(id: ID, title: String, value: @escaping @Sendable () -> String) where ID.RawValue == String {
        self.init(id: id.rawValue, title: title, value: value)
    }
}

public extension FormSection {
    /// Create a section with a `RawRepresentable` id and a pre-built array of rows.
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               rows: [AnyFormRow],
                               onChange: [FormRowAction] = []) where ID.RawValue == String {
        self.init(id: id.rawValue, title: title, rows: rows, onChange: onChange)
    }

    /// Create a section with a `RawRepresentable` id using the `@FormRowBuilder` DSL.
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               onChange: [FormRowAction] = [],
                               @FormRowBuilder rows: () -> [AnyFormRow]) where ID.RawValue == String {
        self.init(id: id.rawValue, title: title, onChange: onChange, rows: rows)
    }
}

public extension CollapsibleSection {
    /// Create a collapsible section with a `RawRepresentable` id and a pre-built array of rows.
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               isExpandedByDefault: Bool = true,
                               rows: [AnyFormRow],
                               onChange: [FormRowAction] = []) where ID.RawValue == String {
        self.init(id: id.rawValue, title: title, isExpandedByDefault: isExpandedByDefault, rows: rows, onChange: onChange)
    }

    /// Create a collapsible section with a `RawRepresentable` id using the `@FormRowBuilder` DSL.
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               isExpandedByDefault: Bool = true,
                               onChange: [FormRowAction] = [],
                               @FormRowBuilder rows: () -> [AnyFormRow]) where ID.RawValue == String {
        self.init(id: id.rawValue, title: title, isExpandedByDefault: isExpandedByDefault, onChange: onChange, rows: rows)
    }
}

public extension NavigationRow {
    init<ID: RawRepresentable>(id: ID,
                               title: String,
                               subtitle: String? = nil,
                               destination: FormDefinition,
                               onChange: [FormRowAction] = []) where ID.RawValue == String {
        self.init(
            id: id.rawValue,
            title: title,
            subtitle: subtitle,
            destination: destination,
            onChange: onChange
        )
    }
}
