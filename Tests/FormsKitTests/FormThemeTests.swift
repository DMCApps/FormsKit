@testable import FormsKit
import SwiftUI
import Testing

// MARK: - FormThemeTests

@Suite("FormTheme")
struct FormThemeTests {

    // MARK: Default values

    @Test("default theme has expected color tokens")
    func defaultColors() {
        let theme = FormTheme.default
        #expect(theme.colors.error == .red)
        #expect(theme.colors.rowTitle == .secondary)
        #expect(theme.colors.subtitle == .secondary)
        #expect(theme.colors.saveButtonBackground == .accentColor)
        #expect(theme.colors.saveButtonDisabledBackground == .secondary)
        #expect(theme.colors.saveButtonForeground == .white)
        #expect(theme.colors.optionText == .primary)
        #expect(theme.colors.selectionIndicator == .accentColor)
        #expect(theme.colors.sectionHeader == .primary)
        #expect(theme.colors.placeholder == nil)
        #expect(theme.colors.switchTint == nil)
        #expect(theme.colors.pickerTint == nil)
        #expect(theme.colors.secureFieldToggle == .secondary)
        #expect(theme.colors.skeletonDark == Color(red: 30/255, green: 30/255, blue: 30/255).opacity(0.4))
        #expect(theme.colors.skeletonLight == Color(red: 64/255, green: 64/255, blue: 64/255).opacity(0.4))
    }

    @Test("default theme has expected font tokens")
    func defaultFonts() {
        let theme = FormTheme.default
        #expect(theme.fonts.rowTitle == .subheadline)
        #expect(theme.fonts.subtitle == .caption)
        #expect(theme.fonts.error == .caption)
        #expect(theme.fonts.saveButton == .body.weight(.semibold))
        #expect(theme.fonts.infoValue == .caption)
        #expect(theme.fonts.sectionHeader == .headline)
        #expect(theme.fonts.loadFailedTitle == .headline)
        #expect(theme.fonts.loadFailedSubtitle == .subheadline)
    }

    @Test("default theme has expected spacing tokens")
    func defaultSpacing() {
        let theme = FormTheme.default
        #expect(theme.spacing.rowContentSpacing == 4)
        #expect(theme.spacing.headerSpacing == 2)
        #expect(theme.spacing.errorSpacing == 2)
        #expect(theme.spacing.saveButtonCornerRadius == 10)
        #expect(theme.spacing.optionRowVerticalPadding == 4)
        #expect(theme.spacing.stickyButtonVerticalPadding == 16)
    }

    @Test("default theme has expected icon tokens")
    func defaultIcons() {
        let theme = FormTheme.default
        #expect(theme.icons.collapsibleDisclosure == .system("chevron.right"))
        #expect(theme.icons.validationError == .system("exclamationmark.circle.fill"))
        #expect(theme.icons.selectionCheckmark == .system("checkmark"))
        #expect(theme.icons.secureFieldReveal == .system("eye"))
        #expect(theme.icons.secureFieldHide == .system("eye.slash"))
    }

    @Test("default theme has expected animation tokens")
    func defaultAnimations() {
        let theme = FormTheme.default
        #expect(theme.animations.collapsibleDuration == 0.2)
        #expect(theme.animations.skeletonDuration == 1)
    }

    @Test("default theme has nil component styles")
    func defaultComponentStyles() {
        let theme = FormTheme.default
        #expect(theme.saveButtonStyle == nil)
        #expect(theme.validationErrorStyle == nil)
    }

    // MARK: Custom values

    @Test("custom color tokens are stored correctly")
    func customColors() {
        let theme = FormTheme(colors: .init(error: .orange, saveButtonBackground: .indigo))
        #expect(theme.colors.error == .orange)
        #expect(theme.colors.saveButtonBackground == .indigo)
        // Unmodified tokens retain defaults
        #expect(theme.colors.rowTitle == .secondary)
    }

    @Test("custom spacing tokens are stored correctly")
    func customSpacing() {
        let theme = FormTheme(spacing: .init(rowContentSpacing: 8, saveButtonCornerRadius: 20))
        #expect(theme.spacing.rowContentSpacing == 8)
        #expect(theme.spacing.saveButtonCornerRadius == 20)
        // Unmodified tokens retain defaults
        #expect(theme.spacing.headerSpacing == 2)
    }

    @Test("custom icon tokens are stored correctly")
    func customIcons() {
        let theme = FormTheme(icons: .init(collapsibleDisclosure: .system("chevron.down")))
        #expect(theme.icons.collapsibleDisclosure == .system("chevron.down"))
        #expect(theme.icons.validationError == .system("exclamationmark.circle.fill"))
    }

    @Test("custom animation tokens are stored correctly")
    func customAnimations() {
        let theme = FormTheme(animations: .init(collapsibleDuration: 0.5))
        #expect(theme.animations.collapsibleDuration == 0.5)
    }

    @Test("custom skeletonDuration token is stored correctly")
    func customSkeletonDuration() {
        let theme = FormTheme(animations: .init(skeletonDuration: 0.8))
        #expect(theme.animations.skeletonDuration == 0.8)
        // Unmodified tokens retain defaults
        #expect(theme.animations.collapsibleDuration == 0.2)
    }

    @Test("custom section header tokens are stored correctly")
    func customSectionHeaderTokens() {
        let theme = FormTheme(
            colors: .init(sectionHeader: .blue),
            fonts: .init(sectionHeader: .caption)
        )
        #expect(theme.colors.sectionHeader == .blue)
        #expect(theme.fonts.sectionHeader == .caption)
        // Unmodified tokens retain defaults
        #expect(theme.colors.rowTitle == .secondary)
    }

    @Test("custom secure field tokens are stored correctly")
    func customSecureFieldTokens() {
        let theme = FormTheme(
            colors: .init(secureFieldToggle: .blue),
            icons: .init(secureFieldReveal: .system("lock.open"), secureFieldHide: .system("lock"))
        )
        #expect(theme.colors.secureFieldToggle == .blue)
        #expect(theme.icons.secureFieldReveal == .system("lock.open"))
        #expect(theme.icons.secureFieldHide == .system("lock"))
    }

    // MARK: Equatable

    @Test("FormTheme.Colors equality holds for identical values")
    func colorsEquatable() {
        let a = FormTheme.Colors(rowTitle: .blue, error: .orange)
        let b = FormTheme.Colors(rowTitle: .blue, error: .orange)
        #expect(a == b)
    }

    @Test("FormTheme.Colors inequality detected")
    func colorsNotEquatable() {
        let a = FormTheme.Colors(error: .orange)
        let b = FormTheme.Colors(error: .red)
        #expect(a != b)
    }

    @Test("FormTheme.Fonts equality holds for identical values")
    func fontsEquatable() {
        let a = FormTheme.Fonts(rowTitle: .body, subtitle: .footnote)
        let b = FormTheme.Fonts(rowTitle: .body, subtitle: .footnote)
        #expect(a == b)
    }

    @Test("FormTheme.Spacing equality holds for identical values")
    func spacingEquatable() {
        let a = FormTheme.Spacing(rowContentSpacing: 8)
        let b = FormTheme.Spacing(rowContentSpacing: 8)
        #expect(a == b)
    }

    @Test("FormTheme.Icons equality holds for identical values")
    func iconsEquatable() {
        let a = FormTheme.Icons(collapsibleDisclosure: .system("chevron.down"))
        let b = FormTheme.Icons(collapsibleDisclosure: .system("chevron.down"))
        #expect(a == b)
    }

    @Test("FormTheme.Animations equality holds for identical values")
    func animationsEquatable() {
        let a = FormTheme.Animations(collapsibleDuration: 0.3, skeletonDuration: 2)
        let b = FormTheme.Animations(collapsibleDuration: 0.3, skeletonDuration: 2)
        #expect(a == b)
    }

    @Test("SaveButtonStyle Equatable holds for identical values")
    func saveButtonStyleEquatable() {
        let a = SaveButtonStyle(backgroundColor: .indigo, cornerRadius: 16)
        let b = SaveButtonStyle(backgroundColor: .indigo, cornerRadius: 16)
        #expect(a == b)
    }

    @Test("SaveButtonStyle Equatable detects inequality")
    func saveButtonStyleNotEquatable() {
        let a = SaveButtonStyle(backgroundColor: .indigo)
        let b = SaveButtonStyle(backgroundColor: .purple)
        #expect(a != b)
    }

    @Test("ValidationErrorStyle Equatable holds for identical values")
    func validationErrorStyleEquatable() {
        let a = ValidationErrorStyle(color: .orange, icon: .system("exclamationmark.triangle"))
        let b = ValidationErrorStyle(color: .orange, icon: .system("exclamationmark.triangle"))
        #expect(a == b)
    }

    @Test("TextInputRowStyle Equatable holds for identical values")
    func textInputRowStyleEquatable() {
        let a = TextInputRowStyle(titleColor: .blue, titleFont: .headline)
        let b = TextInputRowStyle(titleColor: .blue, titleFont: .headline)
        #expect(a == b)
    }

    @Test("TextInputRowStyle Equatable detects placeholderColor vs nil difference")
    func textInputRowStylePlaceholderColorVsNilNotEquatable() {
        let a = TextInputRowStyle(titleColor: .blue, placeholderColor: .purple)
        let b = TextInputRowStyle(titleColor: .blue)
        #expect(a != b)
    }

    @Test("SaveButtonStyle typed property stores and retrieves correctly")
    func saveButtonStyleOverride() {
        var theme = FormTheme()
        theme.saveButtonStyle = SaveButtonStyle(backgroundColor: .indigo, cornerRadius: 16)

        #expect(theme.saveButtonStyle?.backgroundColor == .indigo)
        #expect(theme.saveButtonStyle?.cornerRadius == 16)
        #expect(theme.saveButtonStyle?.foregroundColor == nil)
    }

    @Test("ValidationErrorStyle typed property stores and retrieves correctly")
    func validationErrorStyleOverride() {
        var theme = FormTheme()
        theme.validationErrorStyle = ValidationErrorStyle(
            color: .orange,
            icon: .system("exclamationmark.triangle.fill")
        )

        #expect(theme.validationErrorStyle?.color == .orange)
        #expect(theme.validationErrorStyle?.icon == .system("exclamationmark.triangle.fill"))
        #expect(theme.validationErrorStyle?.font == nil)
    }

    @Test("SaveButtonStyle can be set via FormTheme init")
    func saveButtonStyleViaInit() {
        let style = SaveButtonStyle(backgroundColor: .purple, font: .headline)
        let theme = FormTheme(saveButtonStyle: style)
        #expect(theme.saveButtonStyle?.backgroundColor == .purple)
        #expect(theme.saveButtonStyle?.font == .headline)
    }

    @Test("ValidationErrorStyle can be set via FormTheme init")
    func validationErrorStyleViaInit() {
        let style = ValidationErrorStyle(color: .orange, icon: .system("exclamationmark.triangle"))
        let theme = FormTheme(validationErrorStyle: style)
        #expect(theme.validationErrorStyle?.color == .orange)
        #expect(theme.validationErrorStyle?.icon == .system("exclamationmark.triangle"))
    }

    @Test("FormRowStyle default implementations return nil")
    func protocolDefaultsAreNil() {
        let style = TextInputRowStyle()
        #expect(style.titleColor == nil)
        #expect(style.titleFont == nil)
        #expect(style.subtitleColor == nil)
        #expect(style.subtitleFont == nil)
        #expect(style.placeholderColor == nil)
    }

    // MARK: FormDefinition integration

    @Test("FormDefinition stores theme when provided")
    func formDefinitionStoresTheme() {
        let theme = FormTheme(colors: .init(error: .orange))
        let form = FormDefinition(id: "test", title: "Test", rows: [], theme: theme)
        #expect(form.theme?.colors.error == .orange)
    }

    @Test("FormDefinition theme is nil by default")
    func formDefinitionThemeDefaultsToNil() {
        let form = FormDefinition(id: "test", title: "Test", rows: [])
        #expect(form.theme == nil)
    }

    @Test("FormDefinition DSL init stores theme when provided")
    func formDefinitionDSLStoresTheme() {
        let theme = FormTheme(icons: .init(collapsibleDisclosure: .system("chevron.down")))
        let form = FormDefinition(id: "test", title: "Test", theme: theme) {
            TextInputRow(id: "name", title: "Name")
        }
        #expect(form.theme?.icons.collapsibleDisclosure == .system("chevron.down"))
    }

    // MARK: EnvironmentValues

    @Test("EnvironmentValues.formTheme setter stores and returns the custom theme")
    func environmentSetter() {
        var values = EnvironmentValues()
        let custom = FormTheme(colors: .init(error: .orange), fonts: .init(rowTitle: .body))
        values.formTheme = custom
        #expect(values.formTheme.colors.error == .orange)
        #expect(values.formTheme.fonts.rowTitle == .body)
        // Unmodified tokens still come from the custom theme's defaults (not FormTheme.default)
        #expect(values.formTheme.spacing.saveButtonCornerRadius == 10)
    }

    // MARK: FormTheme.default equals FormTheme()

    @Test("FormTheme.default matches a freshly constructed FormTheme()")
    func defaultMatchesFreshInit() {
        let fresh = FormTheme()
        #expect(fresh.colors == FormTheme.default.colors)
        #expect(fresh.fonts == FormTheme.default.fonts)
        #expect(fresh.spacing == FormTheme.default.spacing)
        #expect(fresh.icons == FormTheme.default.icons)
        #expect(fresh.animations == FormTheme.default.animations)
        #expect(fresh.saveButtonStyle == FormTheme.default.saveButtonStyle)
        #expect(fresh.validationErrorStyle == FormTheme.default.validationErrorStyle)
    }

    // MARK: Custom skeleton color tokens

    @Test("custom skeletonDark and skeletonLight colors are stored correctly")
    func customSkeletonColors() {
        let dark = Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.6)
        let light = Color(red: 0.5, green: 0.5, blue: 0.5).opacity(0.6)
        let theme = FormTheme(colors: .init(skeletonDark: dark, skeletonLight: light))
        #expect(theme.colors.skeletonDark == dark)
        #expect(theme.colors.skeletonLight == light)
        // Unmodified tokens retain defaults
        #expect(theme.colors.error == .red)
    }

    // MARK: SaveButtonStyle.disabledBackgroundColor

    @Test("SaveButtonStyle stores and retrieves disabledBackgroundColor")
    func saveButtonStyleDisabledBackground() {
        let style = SaveButtonStyle(disabledBackgroundColor: .gray)
        #expect(style.disabledBackgroundColor == .gray)
        #expect(style.backgroundColor == nil)
        #expect(style.foregroundColor == nil)
    }

    @Test("SaveButtonStyle with all properties set stores them all correctly")
    func saveButtonStyleAllProperties() {
        let style = SaveButtonStyle(
            backgroundColor: .indigo,
            disabledBackgroundColor: .gray,
            foregroundColor: .white,
            cornerRadius: 12,
            font: .headline
        )
        #expect(style.backgroundColor == .indigo)
        #expect(style.disabledBackgroundColor == .gray)
        #expect(style.foregroundColor == .white)
        #expect(style.cornerRadius == 12)
        #expect(style.font == .headline)
    }

    @Test("SaveButtonStyle Equatable detects disabledBackgroundColor difference")
    func saveButtonStyleDisabledBackgroundEquatable() {
        let a = SaveButtonStyle(disabledBackgroundColor: .gray)
        let b = SaveButtonStyle(disabledBackgroundColor: .secondary)
        #expect(a != b)
    }

    @Test("SaveButtonStyle stored in FormTheme includes disabledBackgroundColor")
    func saveButtonStyleInThemeHasDisabledBackground() {
        var theme = FormTheme()
        theme.saveButtonStyle = SaveButtonStyle(
            backgroundColor: .indigo,
            disabledBackgroundColor: .gray
        )
        #expect(theme.saveButtonStyle?.backgroundColor == .indigo)
        #expect(theme.saveButtonStyle?.disabledBackgroundColor == .gray)
    }

    // MARK: Equatable — row style structs

    @Test("NumberInputRowStyle Equatable holds for identical values")
    func numberInputRowStyleEquatable() {
        let a = NumberInputRowStyle(titleColor: .green, titleFont: .callout)
        let b = NumberInputRowStyle(titleColor: .green, titleFont: .callout)
        #expect(a == b)
    }

    @Test("NumberInputRowStyle Equatable detects inequality")
    func numberInputRowStyleNotEquatable() {
        let a = NumberInputRowStyle(titleColor: .green)
        let b = NumberInputRowStyle(titleColor: .blue)
        #expect(a != b)
    }

    @Test("BooleanSwitchRowStyle Equatable holds for identical values")
    func booleanSwitchRowStyleEquatable() {
        let a = BooleanSwitchRowStyle(subtitleColor: .gray, subtitleFont: .footnote)
        let b = BooleanSwitchRowStyle(subtitleColor: .gray, subtitleFont: .footnote)
        #expect(a == b)
    }

    @Test("BooleanSwitchRowStyle Equatable detects inequality")
    func booleanSwitchRowStyleNotEquatable() {
        let a = BooleanSwitchRowStyle(subtitleColor: .gray)
        let b = BooleanSwitchRowStyle(subtitleColor: .secondary)
        #expect(a != b)
    }

    @Test("BooleanSwitchRowStyle Equatable detects inequality via tintColor")
    func booleanSwitchRowStyleTintColorNotEquatable() {
        let a = BooleanSwitchRowStyle(tintColor: .green)
        let b = BooleanSwitchRowStyle(tintColor: .purple)
        #expect(a != b)
    }

    @Test("SingleValueRowStyle Equatable detects inequality via tintColor")
    func singleValueRowStyleTintColorNotEquatable() {
        let a = SingleValueRowStyle(tintColor: .teal)
        let b = SingleValueRowStyle(tintColor: .orange)
        #expect(a != b)
    }

    @Test("SingleValueRowStyle Equatable holds for identical values")
    func singleValueRowStyleEquatable() {
        let a = SingleValueRowStyle(titleColor: .purple, titleFont: .body)
        let b = SingleValueRowStyle(titleColor: .purple, titleFont: .body)
        #expect(a == b)
    }

    @Test("SingleValueRowStyle Equatable detects inequality")
    func singleValueRowStyleNotEquatable() {
        let a = SingleValueRowStyle(titleFont: .body)
        let b = SingleValueRowStyle(titleFont: .headline)
        #expect(a != b)
    }

    @Test("ButtonRowStyle Equatable holds for identical values")
    func buttonRowStyleEquatable() {
        let a = ButtonRowStyle(titleColor: .red, subtitleColor: .secondary)
        let b = ButtonRowStyle(titleColor: .red, subtitleColor: .secondary)
        #expect(a == b)
    }

    @Test("ButtonRowStyle Equatable detects inequality")
    func buttonRowStyleNotEquatable() {
        let a = ButtonRowStyle(titleColor: .red)
        let b = ButtonRowStyle(titleColor: .blue)
        #expect(a != b)
    }

    @Test("NavigationRowStyle Equatable holds for identical values")
    func navigationRowStyleEquatable() {
        let a = NavigationRowStyle(titleFont: .headline, subtitleFont: .caption2)
        let b = NavigationRowStyle(titleFont: .headline, subtitleFont: .caption2)
        #expect(a == b)
    }

    @Test("NavigationRowStyle Equatable detects inequality")
    func navigationRowStyleNotEquatable() {
        let a = NavigationRowStyle(subtitleFont: .caption)
        let b = NavigationRowStyle(subtitleFont: .footnote)
        #expect(a != b)
    }

    @Test("CollapsibleSectionStyle Equatable holds for identical values")
    func collapsibleSectionStyleEquatable() {
        let a = CollapsibleSectionStyle(disclosureIcon: .system("chevron.down"), animationDuration: 0.4)
        let b = CollapsibleSectionStyle(disclosureIcon: .system("chevron.down"), animationDuration: 0.4)
        #expect(a == b)
    }

    @Test("CollapsibleSectionStyle Equatable detects disclosureIcon difference")
    func collapsibleSectionStyleIconNotEquatable() {
        let a = CollapsibleSectionStyle(disclosureIcon: .system("chevron.down"))
        let b = CollapsibleSectionStyle(disclosureIcon: .system("chevron.right"))
        #expect(a != b)
    }

    @Test("CollapsibleSectionStyle Equatable detects animationDuration difference")
    func collapsibleSectionStyleDurationNotEquatable() {
        let a = CollapsibleSectionStyle(animationDuration: 0.2)
        let b = CollapsibleSectionStyle(animationDuration: 0.5)
        #expect(a != b)
    }

    @Test("MultiValueRowStyle Equatable covers type-specific properties")
    func multiValueRowStyleTypeSpecificEquatable() {
        let a = MultiValueRowStyle(
            optionTextColor: .purple,
            selectionIndicatorColor: .green,
            selectionIcon: .system("star.fill")
        )
        let b = MultiValueRowStyle(
            optionTextColor: .purple,
            selectionIndicatorColor: .green,
            selectionIcon: .system("star.fill")
        )
        #expect(a == b)
    }

    @Test("MultiValueRowStyle Equatable detects selectionIcon difference")
    func multiValueRowStyleIconNotEquatable() {
        let a = MultiValueRowStyle(selectionIcon: .system("checkmark"))
        let b = MultiValueRowStyle(selectionIcon: .system("star.fill"))
        #expect(a != b)
    }

    @Test("InfoRowStyle Equatable covers valueFont and valueColor")
    func infoRowStyleTypeSpecificEquatable() {
        let a = InfoRowStyle(valueFont: .body, valueColor: .blue)
        let b = InfoRowStyle(valueFont: .body, valueColor: .blue)
        #expect(a == b)
    }

    @Test("InfoRowStyle Equatable detects valueColor difference")
    func infoRowStyleValueColorNotEquatable() {
        let a = InfoRowStyle(valueColor: .blue)
        let b = InfoRowStyle(valueColor: .green)
        #expect(a != b)
    }

    // MARK: TextInputRowStyle.placeholderColor

    @Test("TextInputRowStyle stores placeholderColor correctly")
    func textInputRowStylePlaceholderColor() {
        let style = TextInputRowStyle(placeholderColor: .purple)
        #expect(style.placeholderColor == .purple)
        #expect(style.titleColor == nil)
        #expect(style.titleFont == nil)
    }

    @Test("TextInputRowStyle placeholderColor defaults to nil")
    func textInputRowStylePlaceholderColorDefaultsToNil() {
        let style = TextInputRowStyle()
        #expect(style.placeholderColor == nil)
    }

    @Test("TextInputRowStyle Equatable detects placeholderColor difference")
    func textInputRowStylePlaceholderColorNotEquatable() {
        let a = TextInputRowStyle(placeholderColor: .purple)
        let b = TextInputRowStyle(placeholderColor: .orange)
        #expect(a != b)
    }

    @Test("TextInputRowStyle Equatable holds when placeholderColor matches")
    func textInputRowStylePlaceholderColorEquatable() {
        let a = TextInputRowStyle(placeholderColor: .purple)
        let b = TextInputRowStyle(placeholderColor: .purple)
        #expect(a == b)
    }

    // MARK: FormTheme.Colors.placeholder token

    @Test("colors.placeholder defaults to nil")
    func colorsPlaceholderDefaultsToNil() {
        let theme = FormTheme.default
        #expect(theme.colors.placeholder == nil)
    }

    @Test("custom colors.placeholder is stored correctly")
    func customColorsPlaceholder() {
        let theme = FormTheme(colors: .init(placeholder: .secondary))
        #expect(theme.colors.placeholder == .secondary)
        // Unmodified tokens retain defaults
        #expect(theme.colors.rowTitle == .secondary)
        #expect(theme.colors.error == .red)
    }

    @Test("FormTheme.Colors Equatable detects placeholder difference")
    func colorsPlaceholderNotEquatable() {
        let a = FormTheme.Colors(placeholder: .secondary)
        let b = FormTheme.Colors(placeholder: .primary)
        #expect(a != b)
    }

    @Test("FormTheme.Colors Equatable holds when placeholder matches")
    func colorsPlaceholderEquatable() {
        let a = FormTheme.Colors(placeholder: .purple)
        let b = FormTheme.Colors(placeholder: .purple)
        #expect(a == b)
    }

    @Test("FormTheme.Colors Equatable holds when both placeholders are nil")
    func colorsPlaceholderBothNilEquatable() {
        let a = FormTheme.Colors()
        let b = FormTheme.Colors()
        #expect(a == b)
    }

    // MARK: TypedFormDefinition theme forwarding

    @Test("TypedFormDefinition array init forwards theme to underlying FormDefinition")
    func typedFormDefinitionArrayInitForwardsTheme() {
        enum Row: String { case name }
        let theme = FormTheme(colors: .init(error: .orange))
        let typed = TypedFormDefinition<Row>(id: "t", title: "T", rows: [], theme: theme)
        #expect(typed.definition.theme?.colors.error == .orange)
    }

    @Test("TypedFormDefinition DSL init forwards theme to underlying FormDefinition")
    func typedFormDefinitionDSLInitForwardsTheme() {
        enum Row: String { case name }
        let theme = FormTheme(icons: .init(validationError: .system("exclamationmark.triangle.fill")))
        let typed = TypedFormDefinition<Row>(id: "t", title: "T", theme: theme) {
            TextInputRow(id: Row.name.rawValue, title: "Name")
        }
        #expect(typed.definition.theme?.icons.validationError == .system("exclamationmark.triangle.fill"))
    }

    @Test("TypedFormDefinition theme is nil by default")
    func typedFormDefinitionThemeDefaultsToNil() {
        enum Row: String { case name }
        let typed = TypedFormDefinition<Row>(id: "t", title: "T", rows: [])
        #expect(typed.definition.theme == nil)
    }

    // MARK: Row-level style: init parameter

    @Test("TextInputRow style: init parameter stores style as rowStyle")
    func textInputRowStyleAttachesCorrectly() {
        let row = TextInputRow(id: "email", title: "Email",
                               style: TextInputRowStyle(titleColor: .blue, titleFont: .headline))
        let style = row.rowStyle as? TextInputRowStyle
        #expect(style?.titleColor == .blue)
        #expect(style?.titleFont == .headline)
    }

    @Test("TextInputRow style: is forwarded through AnyFormRow")
    func textInputRowStyleForwardedThroughAnyFormRow() {
        let row = AnyFormRow(
            TextInputRow(id: "email", title: "Email",
                         style: TextInputRowStyle(titleColor: .green))
        )
        let style = row.rowStyle as? TextInputRowStyle
        #expect(style?.titleColor == .green)
    }

    @Test("BooleanSwitchRow style: init parameter stores correct style type")
    func booleanSwitchRowStyleAttachesCorrectly() {
        let row = BooleanSwitchRow(id: "notifications", title: "Notifications",
                                   style: BooleanSwitchRowStyle(titleColor: .indigo))
        let style = row.rowStyle as? BooleanSwitchRowStyle
        #expect(style?.titleColor == .indigo)
    }

    @Test("NumberInputRow style: init parameter stores correct style type")
    func numberInputRowStyleAttachesCorrectly() {
        let row = NumberInputRow(id: "age", title: "Age",
                                 style: NumberInputRowStyle(titleFont: .caption))
        let style = row.rowStyle as? NumberInputRowStyle
        #expect(style?.titleFont == .caption)
    }

    @Test("ButtonRow style: init parameter stores correct style type")
    func buttonRowStyleAttachesCorrectly() {
        let row = ButtonRow(id: "logout", title: "Log Out", style: ButtonRowStyle(titleColor: .red)) {}
        let style = row.rowStyle as? ButtonRowStyle
        #expect(style?.titleColor == .red)
    }

    @Test("InfoRow style: init parameter stores correct style type")
    func infoRowStyleAttachesCorrectly() {
        let row = InfoRow(id: "version", title: "Version", style: InfoRowStyle(valueColor: .secondary)) { "1.0" }
        let style = row.rowStyle as? InfoRowStyle
        #expect(style?.valueColor == .secondary)
    }

    @Test("NavigationRow style: init parameter stores correct style type")
    func navigationRowStyleAttachesCorrectly() {
        let sub = FormDefinition(id: "sub", title: "Sub") {}
        let row = NavigationRow(id: "account", title: "Account", destination: sub,
                                style: NavigationRowStyle(titleColor: .blue))
        let style = row.rowStyle as? NavigationRowStyle
        #expect(style?.titleColor == .blue)
    }

    @Test("CollapsibleSection style: init parameter stores correct style type")
    func collapsibleSectionStyleAttachesCorrectly() {
        let section = CollapsibleSection(id: "advanced", title: "Advanced",
                                         style: CollapsibleSectionStyle(titleColor: .purple, animationDuration: 0.5)) {}
        let style = section.rowStyle as? CollapsibleSectionStyle
        #expect(style?.titleColor == .purple)
        #expect(style?.animationDuration == 0.5)
    }

    @Test("Row without style: has nil rowStyle")
    func rowWithoutStyleHasNilRowStyle() {
        let row = TextInputRow(id: "name", title: "Name")
        #expect(row.rowStyle == nil)
    }

    @Test("SingleValueRow style: init parameter stores correct style type")
    func singleValueRowStyleAttachesCorrectly() {
        enum Color: String, CaseIterable, CustomStringConvertible, Hashable, Sendable, Codable {
            case red, blue
            var description: String { rawValue }
        }
        let row = SingleValueRow<Color>(id: "color", title: "Color",
                                        style: SingleValueRowStyle(titleColor: .purple, tintColor: .teal))
        let style = row.rowStyle as? SingleValueRowStyle
        #expect(style?.titleColor == .purple)
        #expect(style?.tintColor == .teal)
    }

    @Test("MultiValueRow style: init parameter stores correct style type")
    func multiValueRowStyleAttachesCorrectly() {
        enum Tag: String, CaseIterable, CustomStringConvertible, Hashable, Sendable, Codable {
            case swift, ios
            var description: String { rawValue }
        }
        let row = MultiValueRow<Tag>(id: "tags", title: "Tags",
                                     style: MultiValueRowStyle(optionTextColor: .indigo, selectionIcon: .system("star.fill")))
        let style = row.rowStyle as? MultiValueRowStyle
        #expect(style?.optionTextColor == .indigo)
        #expect(style?.selectionIcon == .system("star.fill"))
    }
}
