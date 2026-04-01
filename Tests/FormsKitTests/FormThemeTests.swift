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
        #expect(theme.spacing.stickyButtonVerticalPadding == 16)
    }

    @Test("default theme has expected icon tokens")
    func defaultIcons() {
        let theme = FormTheme.default
        #expect(theme.icons.collapsibleDisclosure == "chevron.right")
        #expect(theme.icons.validationError == "exclamationmark.circle.fill")
        #expect(theme.icons.selectionCheckmark == "checkmark")
    }

    @Test("default theme has expected animation tokens")
    func defaultAnimations() {
        let theme = FormTheme.default
        #expect(theme.animations.collapsibleDuration == 0.2)
    }

    @Test("default theme has empty row overrides")
    func defaultRowOverrides() {
        let theme = FormTheme.default
        #expect(theme.rowOverrides.isEmpty)
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
        let theme = FormTheme(icons: .init(collapsibleDisclosure: "chevron.down"))
        #expect(theme.icons.collapsibleDisclosure == "chevron.down")
        #expect(theme.icons.validationError == "exclamationmark.circle.fill")
    }

    @Test("custom animation tokens are stored correctly")
    func customAnimations() {
        let theme = FormTheme(animations: .init(collapsibleDuration: 0.5))
        #expect(theme.animations.collapsibleDuration == 0.5)
    }

    // MARK: Row overrides

    @Test("TextInputRowStyle override is stored and retrieved correctly")
    func textInputRowStyleOverride() {
        var theme = FormTheme()
        theme.rowOverrides["email"] = TextInputRowStyle(titleColor: .blue, titleFont: .headline)

        let style = theme.rowOverrides["email"] as? TextInputRowStyle
        #expect(style != nil)
        #expect(style?.titleColor == .blue)
        #expect(style?.titleFont == .headline)
        #expect(style?.subtitleColor == nil)
        #expect(style?.subtitleFont == nil)
    }

    @Test("MultiValueRowStyle override carries type-specific properties")
    func multiValueRowStyleOverride() {
        var theme = FormTheme()
        theme.rowOverrides["tags"] = MultiValueRowStyle(
            optionTextColor: .purple,
            selectionIndicatorColor: .green,
            selectionIcon: "star.fill"
        )

        let style = theme.rowOverrides["tags"] as? MultiValueRowStyle
        #expect(style?.optionTextColor == .purple)
        #expect(style?.selectionIndicatorColor == .green)
        #expect(style?.selectionIcon == "star.fill")
    }

    @Test("InfoRowStyle override carries value font and color properties")
    func infoRowStyleOverride() {
        var theme = FormTheme()
        theme.rowOverrides["status"] = InfoRowStyle(valueFont: .body, valueColor: .blue)

        let style = theme.rowOverrides["status"] as? InfoRowStyle
        #expect(style?.valueFont == .body)
        #expect(style?.valueColor == .blue)
    }

    @Test("CollapsibleSectionStyle override carries disclosure icon and duration")
    func collapsibleSectionStyleOverride() {
        var theme = FormTheme()
        theme.rowOverrides["advanced"] = CollapsibleSectionStyle(
            disclosureIcon: "chevron.down",
            animationDuration: 0.4
        )

        let style = theme.rowOverrides["advanced"] as? CollapsibleSectionStyle
        #expect(style?.disclosureIcon == "chevron.down")
        #expect(style?.animationDuration == 0.4)
    }

    @Test("SaveButtonStyle is stored under the reserved key")
    func saveButtonStyleOverride() {
        var theme = FormTheme()
        theme.rowOverrides[FormTheme.saveButtonOverrideKey] = SaveButtonStyle(
            backgroundColor: .indigo,
            cornerRadius: 16
        )

        let style = theme.rowOverrides[FormTheme.saveButtonOverrideKey] as? SaveButtonStyle
        #expect(style?.backgroundColor == .indigo)
        #expect(style?.cornerRadius == 16)
        #expect(style?.foregroundColor == nil)
    }

    @Test("ValidationErrorStyle is stored under the reserved key")
    func validationErrorStyleOverride() {
        var theme = FormTheme()
        theme.rowOverrides[FormTheme.validationErrorOverrideKey] = ValidationErrorStyle(
            color: .orange,
            icon: "exclamationmark.triangle.fill"
        )

        let style = theme.rowOverrides[FormTheme.validationErrorOverrideKey] as? ValidationErrorStyle
        #expect(style?.color == .orange)
        #expect(style?.icon == "exclamationmark.triangle.fill")
        #expect(style?.font == nil)
    }

    @Test("wrong override type returns nil on cast")
    func wrongTypeCastReturnsNil() {
        var theme = FormTheme()
        theme.rowOverrides["name"] = TextInputRowStyle(titleColor: .blue)

        // Casting to the wrong concrete type yields nil
        let style = theme.rowOverrides["name"] as? InfoRowStyle
        #expect(style == nil)
    }

    @Test("FormRowStyle default implementations return nil")
    func protocolDefaultsAreNil() {
        let style = TextInputRowStyle()
        #expect(style.titleColor == nil)
        #expect(style.titleFont == nil)
        #expect(style.subtitleColor == nil)
        #expect(style.subtitleFont == nil)
    }

    @Test("NumberInputRowStyle override is stored and retrieved correctly")
    func numberInputRowStyleOverride() {
        var theme = FormTheme()
        theme.rowOverrides["age"] = NumberInputRowStyle(titleColor: .green, titleFont: .callout)

        let style = theme.rowOverrides["age"] as? NumberInputRowStyle
        #expect(style != nil)
        #expect(style?.titleColor == .green)
        #expect(style?.titleFont == .callout)
        #expect(style?.subtitleColor == nil)
        #expect(style?.subtitleFont == nil)
    }

    @Test("BooleanSwitchRowStyle override is stored and retrieved correctly")
    func booleanSwitchRowStyleOverride() {
        var theme = FormTheme()
        theme.rowOverrides["notifications"] = BooleanSwitchRowStyle(
            subtitleColor: .gray,
            subtitleFont: .footnote
        )

        let style = theme.rowOverrides["notifications"] as? BooleanSwitchRowStyle
        #expect(style != nil)
        #expect(style?.titleColor == nil)
        #expect(style?.subtitleColor == .gray)
        #expect(style?.subtitleFont == .footnote)
    }

    @Test("SingleValueRowStyle override is stored and retrieved correctly")
    func singleValueRowStyleOverride() {
        var theme = FormTheme()
        theme.rowOverrides["country"] = SingleValueRowStyle(
            titleColor: .purple,
            titleFont: .body
        )

        let style = theme.rowOverrides["country"] as? SingleValueRowStyle
        #expect(style != nil)
        #expect(style?.titleColor == .purple)
        #expect(style?.titleFont == .body)
        #expect(style?.subtitleColor == nil)
    }

    @Test("ButtonRowStyle override is stored and retrieved correctly")
    func buttonRowStyleOverride() {
        var theme = FormTheme()
        theme.rowOverrides["logout"] = ButtonRowStyle(
            titleColor: .red,
            subtitleColor: .secondary
        )

        let style = theme.rowOverrides["logout"] as? ButtonRowStyle
        #expect(style != nil)
        #expect(style?.titleColor == .red)
        #expect(style?.subtitleColor == .secondary)
        #expect(style?.titleFont == nil)
    }

    @Test("NavigationRowStyle override is stored and retrieved correctly")
    func navigationRowStyleOverride() {
        var theme = FormTheme()
        theme.rowOverrides["advanced"] = NavigationRowStyle(
            titleFont: .headline,
            subtitleFont: .caption2
        )

        let style = theme.rowOverrides["advanced"] as? NavigationRowStyle
        #expect(style != nil)
        #expect(style?.titleFont == .headline)
        #expect(style?.subtitleFont == .caption2)
        #expect(style?.titleColor == nil)
    }

    @Test("rowOverrides entry can be overwritten with a new value")
    func rowOverrideOverwrite() {
        var theme = FormTheme()
        theme.rowOverrides["email"] = TextInputRowStyle(titleColor: .blue)

        // Overwrite with a new style for the same key
        theme.rowOverrides["email"] = TextInputRowStyle(titleColor: .red, titleFont: .headline)

        let style = theme.rowOverrides["email"] as? TextInputRowStyle
        #expect(style?.titleColor == .red)
        #expect(style?.titleFont == .headline)
    }

    @Test("multiple rowOverrides with different types coexist independently")
    func multipleRowOverridesCoexist() {
        var theme = FormTheme()
        theme.rowOverrides["email"] = TextInputRowStyle(titleColor: .blue)
        theme.rowOverrides["tags"] = MultiValueRowStyle(selectionIcon: "star.fill")
        theme.rowOverrides["status"] = InfoRowStyle(valueFont: .body)

        #expect((theme.rowOverrides["email"] as? TextInputRowStyle)?.titleColor == .blue)
        #expect((theme.rowOverrides["tags"] as? MultiValueRowStyle)?.selectionIcon == "star.fill")
        #expect((theme.rowOverrides["status"] as? InfoRowStyle)?.valueFont == .body)
        #expect(theme.rowOverrides.count == 3)
    }

    // MARK: Reserved keys

    @Test("reserved key constants have expected values")
    func reservedKeys() {
        #expect(FormTheme.saveButtonOverrideKey == "__formkit_saveButton")
        #expect(FormTheme.validationErrorOverrideKey == "__formkit_validationError")
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
        let theme = FormTheme(icons: .init(collapsibleDisclosure: "chevron.down"))
        let form = FormDefinition(id: "test", title: "Test", theme: theme) {
            TextInputRow(id: "name", title: "Name")
        }
        #expect(form.theme?.icons.collapsibleDisclosure == "chevron.down")
    }

    // MARK: EnvironmentValues

    @Test("EnvironmentValues.formTheme defaults to FormTheme.default")
    func environmentDefaultValue() {
        let values = EnvironmentValues()
        let theme = values.formTheme
        // Verify a representative subset of tokens matches the static default
        #expect(theme.colors.error == FormTheme.default.colors.error)
        #expect(theme.fonts.rowTitle == FormTheme.default.fonts.rowTitle)
        #expect(theme.spacing.saveButtonCornerRadius == FormTheme.default.spacing.saveButtonCornerRadius)
        #expect(theme.icons.collapsibleDisclosure == FormTheme.default.icons.collapsibleDisclosure)
        #expect(theme.animations.collapsibleDuration == FormTheme.default.animations.collapsibleDuration)
        #expect(theme.rowOverrides.isEmpty)
    }

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

    @Test("FormTheme can be initialized with pre-populated rowOverrides")
    func initWithPrePopulatedRowOverrides() {
        let overrides: [String: any FormRowStyle] = [
            "email": TextInputRowStyle(titleColor: .blue),
            "age": NumberInputRowStyle(titleFont: .callout),
            FormTheme.saveButtonOverrideKey: SaveButtonStyle(backgroundColor: .indigo)
        ]
        let theme = FormTheme(rowOverrides: overrides)
        #expect(theme.rowOverrides.count == 3)
        #expect((theme.rowOverrides["email"] as? TextInputRowStyle)?.titleColor == .blue)
        #expect((theme.rowOverrides["age"] as? NumberInputRowStyle)?.titleFont == .callout)
        #expect((theme.rowOverrides[FormTheme.saveButtonOverrideKey] as? SaveButtonStyle)?.backgroundColor == .indigo)
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
        let theme = FormTheme(icons: .init(validationError: "exclamationmark.triangle.fill"))
        let typed = TypedFormDefinition<Row>(id: "t", title: "T", theme: theme) {
            TextInputRow(id: Row.name.rawValue, title: "Name")
        }
        #expect(typed.definition.theme?.icons.validationError == "exclamationmark.triangle.fill")
    }

    @Test("TypedFormDefinition theme is nil by default")
    func typedFormDefinitionThemeDefaultsToNil() {
        enum Row: String { case name }
        let typed = TypedFormDefinition<Row>(id: "t", title: "T", rows: [])
        #expect(typed.definition.theme == nil)
    }
}
