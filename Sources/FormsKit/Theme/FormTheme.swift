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
/// For per-row-ID overrides, populate `rowOverrides` with a `FormRowStyle`-conforming
/// value keyed by row ID string. Each property in the override falls back to the
/// corresponding semantic token if `nil`.
///
/// ```swift
/// var theme = FormTheme()
/// theme.rowOverrides["email"] = TextInputRowStyle(titleColor: .blue, titleFont: .headline)
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

    // MARK: - Per-row Overrides

    /// Per-row-ID style overrides. Key is the row's `id` string.
    /// The value must conform to `FormRowStyle`; cast to the concrete type for the row type
    /// to access type-specific properties.
    ///
    /// Common properties (`titleColor`, `titleFont`, `subtitleColor`, `subtitleFont`) fall back
    /// to the semantic tokens when `nil`.
    public var rowOverrides: [String: any FormRowStyle]

    // MARK: - Init

    public init(
        colors: Colors = Colors(),
        fonts: Fonts = Fonts(),
        spacing: Spacing = Spacing(),
        icons: Icons = Icons(),
        animations: Animations = Animations(),
        rowOverrides: [String: any FormRowStyle] = [:]
    ) {
        self.colors = colors
        self.fonts = fonts
        self.spacing = spacing
        self.icons = icons
        self.animations = animations
        self.rowOverrides = rowOverrides
    }

    /// The default theme, matching the library's original hardcoded appearance.
    public static let `default` = FormTheme()
}

// MARK: - FormTheme.Colors

extension FormTheme {
    /// Color tokens used throughout FormsKit views.
    public struct Colors: Sendable {

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
            self.skeletonDark = skeletonDark
            self.skeletonLight = skeletonLight
        }
    }
}

// MARK: - FormTheme.Fonts

extension FormTheme {
    /// Font tokens used throughout FormsKit views.
    public struct Fonts: Sendable {

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
            loadFailedTitle: Font = .headline,
            loadFailedSubtitle: Font = .subheadline
        ) {
            self.rowTitle = rowTitle
            self.subtitle = subtitle
            self.error = error
            self.saveButton = saveButton
            self.infoValue = infoValue
            self.loadFailedTitle = loadFailedTitle
            self.loadFailedSubtitle = loadFailedSubtitle
        }
    }
}

// MARK: - FormTheme.Spacing

extension FormTheme {
    /// Spacing tokens used throughout FormsKit views.
    public struct Spacing: Sendable {

        /// Vertical spacing between elements within a row content wrapper.
        public var rowContentSpacing: CGFloat

        /// Vertical spacing between title and subtitle within a row header.
        public var headerSpacing: CGFloat

        /// Vertical spacing between individual validation error messages.
        public var errorSpacing: CGFloat

        /// Corner radius of the save button background.
        public var saveButtonCornerRadius: CGFloat

        /// Vertical padding inside the sticky bottom save button.
        public var stickyButtonVerticalPadding: CGFloat

        public init(
            rowContentSpacing: CGFloat = 4,
            headerSpacing: CGFloat = 2,
            errorSpacing: CGFloat = 2,
            saveButtonCornerRadius: CGFloat = 10,
            stickyButtonVerticalPadding: CGFloat = 16
        ) {
            self.rowContentSpacing = rowContentSpacing
            self.headerSpacing = headerSpacing
            self.errorSpacing = errorSpacing
            self.saveButtonCornerRadius = saveButtonCornerRadius
            self.stickyButtonVerticalPadding = stickyButtonVerticalPadding
        }
    }
}

// MARK: - FormTheme.Icons

extension FormTheme {
    /// SF Symbol name tokens used by FormsKit views.
    public struct Icons: Sendable {

        /// SF Symbol name for the collapsible section disclosure arrow.
        public var collapsibleDisclosure: String

        /// SF Symbol name for the validation error icon.
        public var validationError: String

        /// SF Symbol name for the multi-value selection checkmark.
        public var selectionCheckmark: String

        public init(
            collapsibleDisclosure: String = "chevron.right",
            validationError: String = "exclamationmark.circle.fill",
            selectionCheckmark: String = "checkmark"
        ) {
            self.collapsibleDisclosure = collapsibleDisclosure
            self.validationError = validationError
            self.selectionCheckmark = selectionCheckmark
        }
    }
}

// MARK: - FormTheme.Animations

extension FormTheme {
    /// Animation tokens used by FormsKit views.
    public struct Animations: Sendable {

        /// Duration in seconds of the collapsible section expand/collapse animation.
        public var collapsibleDuration: Double

        public init(
            collapsibleDuration: Double = 0.2
        ) {
            self.collapsibleDuration = collapsibleDuration
        }
    }
}
