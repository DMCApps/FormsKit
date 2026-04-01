import SwiftUI

// MARK: - FormRowStyle

/// A protocol for per-row-ID style overrides within a `FormTheme`.
///
/// Conforming types carry optional styling properties. Any property set to `nil`
/// falls back to the corresponding semantic token in `FormTheme`.
///
/// Common properties (`titleColor`, `titleFont`, `subtitleColor`, `subtitleFont`)
/// are defined here and shared across all row style types. Row-type-specific extras
/// are defined on the concrete structs.
///
/// Register a style override using the theme's subscript API keyed by the row's `id`:
///
/// ```swift
/// var theme = FormTheme()
/// theme["email"] = TextInputRowStyle(titleColor: .blue, titleFont: .headline)
/// // Or with a typed enum:
/// theme[Row.email] = TextInputRowStyle(titleColor: .blue, titleFont: .headline)
/// ```
public protocol FormRowStyle: Sendable {
    /// Override for the row title color. Falls back to `theme.colors.rowTitle` when `nil`.
    var titleColor: Color? { get }
    /// Override for the row title font. Falls back to `theme.fonts.rowTitle` when `nil`.
    var titleFont: Font? { get }
    /// Override for the row subtitle color. Falls back to `theme.colors.subtitle` when `nil`.
    var subtitleColor: Color? { get }
    /// Override for the row subtitle font. Falls back to `theme.fonts.subtitle` when `nil`.
    var subtitleFont: Font? { get }
}

// Default implementations — all nil so concrete types only need to declare what they override.
extension FormRowStyle {
    public var titleColor: Color? { nil }
    public var titleFont: Font? { nil }
    public var subtitleColor: Color? { nil }
    public var subtitleFont: Font? { nil }
}

// MARK: - TextInputRowStyle

/// Per-row style overrides for `TextInputRow`.
public struct TextInputRowStyle: FormRowStyle, Equatable {
    public var titleColor: Color?
    public var titleFont: Font?
    public var subtitleColor: Color?
    public var subtitleFont: Font?

    /// Override for the placeholder text color. Falls back to the system default when `nil`.
    public var placeholderColor: Color?

    public init(
        titleColor: Color? = nil,
        titleFont: Font? = nil,
        subtitleColor: Color? = nil,
        subtitleFont: Font? = nil,
        placeholderColor: Color? = nil
    ) {
        self.titleColor = titleColor
        self.titleFont = titleFont
        self.subtitleColor = subtitleColor
        self.subtitleFont = subtitleFont
        self.placeholderColor = placeholderColor
    }
}

// MARK: - NumberInputRowStyle

/// Per-row style overrides for `NumberInputRow`.
public struct NumberInputRowStyle: FormRowStyle, Equatable {
    public var titleColor: Color?
    public var titleFont: Font?
    public var subtitleColor: Color?
    public var subtitleFont: Font?

    public init(
        titleColor: Color? = nil,
        titleFont: Font? = nil,
        subtitleColor: Color? = nil,
        subtitleFont: Font? = nil
    ) {
        self.titleColor = titleColor
        self.titleFont = titleFont
        self.subtitleColor = subtitleColor
        self.subtitleFont = subtitleFont
    }
}

// MARK: - BooleanSwitchRowStyle

/// Per-row style overrides for `BooleanSwitchRow`.
public struct BooleanSwitchRowStyle: FormRowStyle, Equatable {
    public var titleColor: Color?
    public var titleFont: Font?
    public var subtitleColor: Color?
    public var subtitleFont: Font?

    public init(
        titleColor: Color? = nil,
        titleFont: Font? = nil,
        subtitleColor: Color? = nil,
        subtitleFont: Font? = nil
    ) {
        self.titleColor = titleColor
        self.titleFont = titleFont
        self.subtitleColor = subtitleColor
        self.subtitleFont = subtitleFont
    }
}

// MARK: - SingleValueRowStyle

/// Per-row style overrides for `SingleValueRow<T>`.
public struct SingleValueRowStyle: FormRowStyle, Equatable {
    public var titleColor: Color?
    public var titleFont: Font?
    public var subtitleColor: Color?
    public var subtitleFont: Font?

    public init(
        titleColor: Color? = nil,
        titleFont: Font? = nil,
        subtitleColor: Color? = nil,
        subtitleFont: Font? = nil
    ) {
        self.titleColor = titleColor
        self.titleFont = titleFont
        self.subtitleColor = subtitleColor
        self.subtitleFont = subtitleFont
    }
}

// MARK: - MultiValueRowStyle

/// Per-row style overrides for `MultiValueRow<T>`.
public struct MultiValueRowStyle: FormRowStyle, Equatable {
    public var titleColor: Color?
    public var titleFont: Font?
    public var subtitleColor: Color?
    public var subtitleFont: Font?

    /// Override for option label text color. Falls back to `theme.colors.optionText` when `nil`.
    public var optionTextColor: Color?
    /// Override for the selection indicator (checkmark) color. Falls back to `theme.colors.selectionIndicator` when `nil`.
    public var selectionIndicatorColor: Color?
    /// Override for the SF Symbol name used as the selection indicator. Falls back to `theme.icons.selectionCheckmark` when `nil`.
    public var selectionIcon: String?

    public init(
        titleColor: Color? = nil,
        titleFont: Font? = nil,
        subtitleColor: Color? = nil,
        subtitleFont: Font? = nil,
        optionTextColor: Color? = nil,
        selectionIndicatorColor: Color? = nil,
        selectionIcon: String? = nil
    ) {
        self.titleColor = titleColor
        self.titleFont = titleFont
        self.subtitleColor = subtitleColor
        self.subtitleFont = subtitleFont
        self.optionTextColor = optionTextColor
        self.selectionIndicatorColor = selectionIndicatorColor
        self.selectionIcon = selectionIcon
    }
}

// MARK: - InfoRowStyle

/// Per-row style overrides for `InfoRow`.
public struct InfoRowStyle: FormRowStyle, Equatable {
    public var titleColor: Color?
    public var titleFont: Font?
    public var subtitleColor: Color?
    public var subtitleFont: Font?

    /// Override for the trailing value text font. Falls back to `theme.fonts.infoValue` when `nil`.
    public var valueFont: Font?
    /// Override for the trailing value text color. Falls back to `theme.colors.rowTitle` when `nil`.
    public var valueColor: Color?

    public init(
        titleColor: Color? = nil,
        titleFont: Font? = nil,
        subtitleColor: Color? = nil,
        subtitleFont: Font? = nil,
        valueFont: Font? = nil,
        valueColor: Color? = nil
    ) {
        self.titleColor = titleColor
        self.titleFont = titleFont
        self.subtitleColor = subtitleColor
        self.subtitleFont = subtitleFont
        self.valueFont = valueFont
        self.valueColor = valueColor
    }
}

// MARK: - ButtonRowStyle

/// Per-row style overrides for `ButtonRow`.
public struct ButtonRowStyle: FormRowStyle, Equatable {
    public var titleColor: Color?
    public var titleFont: Font?
    public var subtitleColor: Color?
    public var subtitleFont: Font?

    public init(
        titleColor: Color? = nil,
        titleFont: Font? = nil,
        subtitleColor: Color? = nil,
        subtitleFont: Font? = nil
    ) {
        self.titleColor = titleColor
        self.titleFont = titleFont
        self.subtitleColor = subtitleColor
        self.subtitleFont = subtitleFont
    }
}

// MARK: - NavigationRowStyle

/// Per-row style overrides for `NavigationRow`.
public struct NavigationRowStyle: FormRowStyle, Equatable {
    public var titleColor: Color?
    public var titleFont: Font?
    public var subtitleColor: Color?
    public var subtitleFont: Font?

    public init(
        titleColor: Color? = nil,
        titleFont: Font? = nil,
        subtitleColor: Color? = nil,
        subtitleFont: Font? = nil
    ) {
        self.titleColor = titleColor
        self.titleFont = titleFont
        self.subtitleColor = subtitleColor
        self.subtitleFont = subtitleFont
    }
}

// MARK: - CollapsibleSectionStyle

/// Per-row style overrides for `CollapsibleSection`.
public struct CollapsibleSectionStyle: FormRowStyle, Equatable {
    public var titleColor: Color?
    public var titleFont: Font?
    public var subtitleColor: Color?
    public var subtitleFont: Font?

    /// Override for the SF Symbol name used as the disclosure arrow.
    /// Falls back to `theme.icons.collapsibleDisclosure` when `nil`.
    public var disclosureIcon: String?
    /// Override for the expand/collapse animation duration in seconds.
    /// Falls back to `theme.animations.collapsibleDuration` when `nil`.
    public var animationDuration: Double?

    public init(
        titleColor: Color? = nil,
        titleFont: Font? = nil,
        subtitleColor: Color? = nil,
        subtitleFont: Font? = nil,
        disclosureIcon: String? = nil,
        animationDuration: Double? = nil
    ) {
        self.titleColor = titleColor
        self.titleFont = titleFont
        self.subtitleColor = subtitleColor
        self.subtitleFont = subtitleFont
        self.disclosureIcon = disclosureIcon
        self.animationDuration = animationDuration
    }
}

// MARK: - SaveButtonStyle

/// Style overrides for the form's save button.
///
/// Assign directly to `FormTheme.saveButtonStyle`:
///
/// ```swift
/// var theme = FormTheme()
/// theme.saveButtonStyle = SaveButtonStyle(backgroundColor: .indigo, cornerRadius: 16)
/// ```
public struct SaveButtonStyle: Sendable, Equatable {

    /// Override for the save button background color when enabled.
    /// Falls back to `theme.colors.saveButtonBackground` when `nil`.
    public var backgroundColor: Color?
    /// Override for the save button background color when disabled.
    /// Falls back to `theme.colors.saveButtonDisabledBackground` when `nil`.
    public var disabledBackgroundColor: Color?
    /// Override for the save button text/icon foreground color.
    /// Falls back to `theme.colors.saveButtonForeground` when `nil`.
    public var foregroundColor: Color?
    /// Override for the save button corner radius.
    /// Falls back to `theme.spacing.saveButtonCornerRadius` when `nil`.
    public var cornerRadius: CGFloat?
    /// Override for the save button text font.
    /// Falls back to `theme.fonts.saveButton` when `nil`.
    public var font: Font?

    public init(
        backgroundColor: Color? = nil,
        disabledBackgroundColor: Color? = nil,
        foregroundColor: Color? = nil,
        cornerRadius: CGFloat? = nil,
        font: Font? = nil
    ) {
        self.backgroundColor = backgroundColor
        self.disabledBackgroundColor = disabledBackgroundColor
        self.foregroundColor = foregroundColor
        self.cornerRadius = cornerRadius
        self.font = font
    }
}

// MARK: - ValidationErrorStyle

/// Style overrides for validation error display.
///
/// Assign directly to `FormTheme.validationErrorStyle`:
///
/// ```swift
/// var theme = FormTheme()
/// theme.validationErrorStyle = ValidationErrorStyle(color: .orange, icon: "exclamationmark.triangle.fill")
/// ```
public struct ValidationErrorStyle: Sendable, Equatable {

    /// Override for the error text and icon color. Falls back to `theme.colors.error` when `nil`.
    public var color: Color?
    /// Override for the error text font. Falls back to `theme.fonts.error` when `nil`.
    public var font: Font?
    /// Override for the SF Symbol name used as the error icon.
    /// Falls back to `theme.icons.validationError` when `nil`.
    public var icon: String?

    public init(
        color: Color? = nil,
        font: Font? = nil,
        icon: String? = nil
    ) {
        self.color = color
        self.font = font
        self.icon = icon
    }
}

