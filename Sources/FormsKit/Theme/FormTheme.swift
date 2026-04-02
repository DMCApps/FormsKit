import SwiftUI

// MARK: - FormTheme

/// The theming object for FormsKit forms.
///
/// A `FormTheme` controls colors, fonts, spacing, icons, and animations used across
/// all form views. All properties have sensible defaults matching the library's original
/// appearance, so existing usage is unaffected.
///
/// Apply a theme using the `.formTheme(_:)` view modifier, or pass it through
/// `FormDefinition(theme:)` for convenience:
///
/// ```swift
/// // Via view modifier (can override per-subtree):
/// DynamicFormView(formDefinition: myForm)
///     .formTheme(myTheme)
///
/// // Via FormDefinition (injected into environment by DynamicFormView):
/// let form = FormDefinition(id: "x", title: "X", theme: myTheme) { ... }
/// ```
///
/// For per-row style overrides, pass the style as the `style:` parameter directly in
/// the row's initialiser. The compiler enforces the correct style type for each row:
///
/// ```swift
/// TextInputRow(id: "email", title: "Email",
///     style: TextInputRowStyle(titleColor: .blue, placeholderColor: .blue.opacity(0.5)))
///
/// BooleanSwitchRow(id: "notifications", title: "Push Notifications",
///     style: BooleanSwitchRowStyle(titleColor: .indigo))
/// ```
///
/// For form-level components (save button, validation errors), use the dedicated typed
/// properties:
///
/// ```swift
/// var theme = FormTheme()
/// theme.saveButtonStyle = SaveButtonStyle(backgroundColor: .indigo, cornerRadius: 16)
/// theme.validationErrorStyle = ValidationErrorStyle(color: .orange)
/// ```
public struct FormTheme: Sendable {

    // MARK: - Semantic Tokens

    /// Color tokens.
    public var colors: Colors

    /// Font tokens.
    public var fonts: Fonts

    /// Spacing tokens.
    public var spacing: Spacing

    /// Icon (SF Symbol name) tokens.
    public var icons: Icons

    /// Animation tokens.
    public var animations: Animations

    // MARK: - Component Styles

    /// Style overrides for the form's save button.
    /// Each property falls back to the corresponding semantic token when `nil`.
    public var saveButtonStyle: SaveButtonStyle?

    /// Style overrides for validation error display across all rows.
    /// Each property falls back to the corresponding semantic token when `nil`.
    public var validationErrorStyle: ValidationErrorStyle?

    // MARK: - Init

    public init(
        colors: Colors = Colors(),
        fonts: Fonts = Fonts(),
        spacing: Spacing = Spacing(),
        icons: Icons = Icons(),
        animations: Animations = Animations(),
        saveButtonStyle: SaveButtonStyle? = nil,
        validationErrorStyle: ValidationErrorStyle? = nil
    ) {
        self.colors = colors
        self.fonts = fonts
        self.spacing = spacing
        self.icons = icons
        self.animations = animations
        self.saveButtonStyle = saveButtonStyle
        self.validationErrorStyle = validationErrorStyle
    }

    /// The default theme, matching the library's original hardcoded appearance.
    public static let `default` = FormTheme()
}

// MARK: - FormTheme.Colors

extension FormTheme {
    /// Color tokens used throughout FormsKit views.
    public struct Colors: Sendable, Equatable {

        // MARK: Row content

        /// Foreground color for row title labels (e.g. TextInputRow, NumberInputRow headers).
        public var rowTitle: Color

        /// Foreground color for subtitle text across all row types.
        public var subtitle: Color

        // MARK: Validation

        /// Color for validation error text and icons.
        public var error: Color

        // MARK: Save button

        /// Background color of the save button when enabled.
        public var saveButtonBackground: Color

        /// Background color of the save button when disabled.
        public var saveButtonDisabledBackground: Color

        /// Foreground (text/icon) color of the save button.
        public var saveButtonForeground: Color

        // MARK: Multi-value

        /// Foreground color for option labels in multi-value rows.
        public var optionText: Color

        /// Color for the selection checkmark in multi-value rows.
        public var selectionIndicator: Color

        // MARK: Section header

        /// Foreground color for section header titles.
        public var sectionHeader: Color

        // MARK: Input placeholder

        /// Foreground color for placeholder text in `TextInputRow` and `NumberInputRow` fields.
        /// When `nil`, the system default placeholder color is used.
        public var placeholder: Color?

        // MARK: Toggle / Picker tint

        /// Tint (fill) color for `Toggle` controls in `BooleanSwitchRow`.
        /// When `nil`, the system accent color is used.
        public var switchTint: Color?

        /// Tint color for `Picker` controls in `SingleValueRow` (affects selected-value
        /// label in `.menu` style and selection highlight in `.navigationLink` style).
        /// When `nil`, the system accent color is used.
        public var pickerTint: Color?

        // MARK: Secure field

        /// Foreground color for the secure field reveal/hide toggle button.
        public var secureFieldToggle: Color

        // MARK: Skeleton

        /// The darker color in the skeleton shimmer animation cycle.
        public var skeletonDark: Color

        /// The lighter color in the skeleton shimmer animation cycle.
        public var skeletonLight: Color

        public init(
            rowTitle: Color = .secondary,
            subtitle: Color = .secondary,
            error: Color = .red,
            saveButtonBackground: Color = .accentColor,
            saveButtonDisabledBackground: Color = .secondary,
            saveButtonForeground: Color = .white,
            optionText: Color = .primary,
            selectionIndicator: Color = .accentColor,
            sectionHeader: Color = .primary,
            placeholder: Color? = nil,
            switchTint: Color? = nil,
            pickerTint: Color? = nil,
            secureFieldToggle: Color = .secondary,
            skeletonDark: Color = Color(red: 30/255, green: 30/255, blue: 30/255).opacity(0.4),
            skeletonLight: Color = Color(red: 64/255, green: 64/255, blue: 64/255).opacity(0.4)
        ) {
            self.rowTitle = rowTitle
            self.subtitle = subtitle
            self.error = error
            self.saveButtonBackground = saveButtonBackground
            self.saveButtonDisabledBackground = saveButtonDisabledBackground
            self.saveButtonForeground = saveButtonForeground
            self.optionText = optionText
            self.selectionIndicator = selectionIndicator
            self.sectionHeader = sectionHeader
            self.placeholder = placeholder
            self.switchTint = switchTint
            self.pickerTint = pickerTint
            self.secureFieldToggle = secureFieldToggle
            self.skeletonDark = skeletonDark
            self.skeletonLight = skeletonLight
        }
    }
}

// MARK: - FormTheme.Fonts

extension FormTheme {
    /// Font tokens used throughout FormsKit views.
    public struct Fonts: Sendable, Equatable {

        /// Font for row title labels (TextInputRow, NumberInputRow header labels).
        public var rowTitle: Font

        /// Font for subtitle text across all row types.
        public var subtitle: Font

        /// Font for validation error messages.
        public var error: Font

        /// Font for the save button text.
        public var saveButton: Font

        /// Font for the info row trailing value text.
        public var infoValue: Font

        /// Font for section header titles.
        public var sectionHeader: Font

        /// Font for the "Failed to Load" heading.
        public var loadFailedTitle: Font

        /// Font for the load failure description text.
        public var loadFailedSubtitle: Font

        public init(
            rowTitle: Font = .subheadline,
            subtitle: Font = .caption,
            error: Font = .caption,
            saveButton: Font = .body.weight(.semibold),
            infoValue: Font = .caption,
            sectionHeader: Font = .headline,
            loadFailedTitle: Font = .headline,
            loadFailedSubtitle: Font = .subheadline
        ) {
            self.rowTitle = rowTitle
            self.subtitle = subtitle
            self.error = error
            self.saveButton = saveButton
            self.infoValue = infoValue
            self.sectionHeader = sectionHeader
            self.loadFailedTitle = loadFailedTitle
            self.loadFailedSubtitle = loadFailedSubtitle
        }
    }
}

// MARK: - FormTheme.Spacing

extension FormTheme {
    /// Spacing tokens used throughout FormsKit views.
    public struct Spacing: Sendable, Equatable {

        /// Vertical spacing between elements within a row content wrapper.
        public var rowContentSpacing: CGFloat

        /// Vertical spacing between title and subtitle within a row header.
        public var headerSpacing: CGFloat

        /// Vertical spacing between individual validation error messages.
        public var errorSpacing: CGFloat

        /// Corner radius of the save button background.
        public var saveButtonCornerRadius: CGFloat

        /// Vertical padding applied to each option row in a MultiValueRow list.
        public var optionRowVerticalPadding: CGFloat

        /// Vertical padding inside the sticky bottom save button.
        public var stickyButtonVerticalPadding: CGFloat

        public init(
            rowContentSpacing: CGFloat = 4,
            headerSpacing: CGFloat = 2,
            errorSpacing: CGFloat = 2,
            saveButtonCornerRadius: CGFloat = 10,
            optionRowVerticalPadding: CGFloat = 4,
            stickyButtonVerticalPadding: CGFloat = 16
        ) {
            self.rowContentSpacing = rowContentSpacing
            self.headerSpacing = headerSpacing
            self.errorSpacing = errorSpacing
            self.saveButtonCornerRadius = saveButtonCornerRadius
            self.optionRowVerticalPadding = optionRowVerticalPadding
            self.stickyButtonVerticalPadding = stickyButtonVerticalPadding
        }
    }
}

// MARK: - FormTheme.Icons

extension FormTheme {
    /// Icon tokens used by FormsKit views.
    public struct Icons: Sendable, Equatable {

        /// Icon for the collapsible section disclosure arrow.
        public var collapsibleDisclosure: FormIcon

        /// Icon for the validation error indicator.
        public var validationError: FormIcon

        /// Icon for the multi-value selection checkmark.
        public var selectionCheckmark: FormIcon

        /// Icon shown on the secure field toggle button when the field is hidden (reveal action).
        public var secureFieldReveal: FormIcon

        /// Icon shown on the secure field toggle button when the field is revealed (hide action).
        public var secureFieldHide: FormIcon

        public init(
            collapsibleDisclosure: FormIcon = .system("chevron.right"),
            validationError: FormIcon = .system("exclamationmark.circle.fill"),
            selectionCheckmark: FormIcon = .system("checkmark"),
            secureFieldReveal: FormIcon = .system("eye"),
            secureFieldHide: FormIcon = .system("eye.slash")
        ) {
            self.collapsibleDisclosure = collapsibleDisclosure
            self.validationError = validationError
            self.selectionCheckmark = selectionCheckmark
            self.secureFieldReveal = secureFieldReveal
            self.secureFieldHide = secureFieldHide
        }
    }
}

// MARK: - FormTheme.Animations

extension FormTheme {
    /// Animation tokens used by FormsKit views.
    public struct Animations: Sendable, Equatable {

        /// Duration in seconds of the collapsible section expand/collapse animation.
        public var collapsibleDuration: Double

        /// Duration in seconds of the skeleton shimmer animation cycle.
        public var skeletonDuration: Double

        public init(
            collapsibleDuration: Double = 0.2,
            skeletonDuration: Double = 1
        ) {
            self.collapsibleDuration = collapsibleDuration
            self.skeletonDuration = skeletonDuration
        }
    }
}
