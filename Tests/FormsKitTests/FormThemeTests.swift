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
        #expect(theme.spacing.stickyButtonVerticalPadding == 16)
    }

    @Test("default theme has expected icon tokens")
    func defaultIcons() {
        let theme = FormTheme.default
        #expect(theme.icons.collapsibleDisclosure == "chevron.right")
        #expect(theme.icons.validationError == "exclamationmark.circle.fill")
        #expect(theme.icons.selectionCheckmark == "checkmark")
        #expect(theme.icons.secureFieldReveal == "eye")
        #expect(theme.icons.secureFieldHide == "eye.slash")
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

    @Test("default theme has no row overrides set")
    func defaultRowOverrides() {
        let theme = FormTheme.default
        // No overrides configured — all key lookups return nil
        #expect(theme["email"] == nil)
        #expect(theme["name"] == nil)
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
            icons: .init(secureFieldReveal: "lock.open", secureFieldHide: "lock")
        )
        #expect(theme.colors.secureFieldToggle == .blue)
        #expect(theme.icons.secureFieldReveal == "lock.open")
        #expect(theme.icons.secureFieldHide == "lock")
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
        let a = FormTheme.Icons(collapsibleDisclosure: "chevron.down")
        let b = FormTheme.Icons(collapsibleDisclosure: "chevron.down")
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
        let a = ValidationErrorStyle(color: .orange, icon: "exclamationmark.triangle")
        let b = ValidationErrorStyle(color: .orange, icon: "exclamationmark.triangle")
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

    // MARK: rowStyle(for:as:) helper

    @Test("rowStyle(for:as:) returns the override when the type matches")
    func rowStyleHelperReturnsMatchingOverride() {
        var theme = FormTheme()
        theme["email"] = TextInputRowStyle(titleColor: .blue)

        let style = theme.rowStyle(for: "email", as: TextInputRowStyle.self)
        #expect(style != nil)
        #expect(style?.titleColor == .blue)
    }

    @Test("rowStyle(for:as:) returns nil when no override exists for the key")
    func rowStyleHelperReturnNilForMissingKey() {
        let theme = FormTheme()
        let style = theme.rowStyle(for: "nonexistent", as: TextInputRowStyle.self)
        #expect(style == nil)
    }

    @Test("rowStyle(for:as:) returns nil when the stored type does not match the requested type")
    func rowStyleHelperReturnsNilForTypeMismatch() {
        var theme = FormTheme()
        theme["field"] = NumberInputRowStyle(titleColor: .green)

        // Requesting a different type for the same key should return nil
        let style = theme.rowStyle(for: "field", as: TextInputRowStyle.self)
        #expect(style == nil)
    }

    // MARK: Row overrides

    @Test("TextInputRowStyle override is stored and retrieved correctly")
    func textInputRowStyleOverride() {
        var theme = FormTheme()
        theme["email"] = TextInputRowStyle(titleColor: .blue, titleFont: .headline)

        let style = theme["email"] as? TextInputRowStyle
        #expect(style != nil)
        #expect(style?.titleColor == .blue)
        #expect(style?.titleFont == .headline)
        #expect(style?.subtitleColor == nil)
        #expect(style?.subtitleFont == nil)
        #expect(style?.placeholderColor == nil)
    }

    @Test("MultiValueRowStyle override carries type-specific properties")
    func multiValueRowStyleOverride() {
        var theme = FormTheme()
        theme["tags"] = MultiValueRowStyle(
            optionTextColor: .purple,
            selectionIndicatorColor: .green,
            selectionIcon: "star.fill"
        )

        let style = theme["tags"] as? MultiValueRowStyle
        #expect(style?.optionTextColor == .purple)
        #expect(style?.selectionIndicatorColor == .green)
        #expect(style?.selectionIcon == "star.fill")
    }

    @Test("InfoRowStyle override carries value font and color properties")
    func infoRowStyleOverride() {
        var theme = FormTheme()
        theme["status"] = InfoRowStyle(valueFont: .body, valueColor: .blue)

        let style = theme["status"] as? InfoRowStyle
        #expect(style?.valueFont == .body)
        #expect(style?.valueColor == .blue)
    }

    @Test("CollapsibleSectionStyle override carries disclosure icon and duration")
    func collapsibleSectionStyleOverride() {
        var theme = FormTheme()
        theme["advanced"] = CollapsibleSectionStyle(
            disclosureIcon: "chevron.down",
            animationDuration: 0.4
        )

        let style = theme["advanced"] as? CollapsibleSectionStyle
        #expect(style?.disclosureIcon == "chevron.down")
        #expect(style?.animationDuration == 0.4)
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
            icon: "exclamationmark.triangle.fill"
        )

        #expect(theme.validationErrorStyle?.color == .orange)
        #expect(theme.validationErrorStyle?.icon == "exclamationmark.triangle.fill")
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
        let style = ValidationErrorStyle(color: .orange, icon: "exclamationmark.triangle")
        let theme = FormTheme(validationErrorStyle: style)
        #expect(theme.validationErrorStyle?.color == .orange)
        #expect(theme.validationErrorStyle?.icon == "exclamationmark.triangle")
    }

    @Test("wrong override type returns nil on cast")
    func wrongTypeCastReturnsNil() {
        var theme = FormTheme()
        theme["name"] = TextInputRowStyle(titleColor: .blue)

        // Casting to the wrong concrete type yields nil
        let style = theme["name"] as? InfoRowStyle
        #expect(style == nil)
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

    @Test("NumberInputRowStyle override is stored and retrieved correctly")
    func numberInputRowStyleOverride() {
        var theme = FormTheme()
        theme["age"] = NumberInputRowStyle(titleColor: .green, titleFont: .callout)

        let style = theme["age"] as? NumberInputRowStyle
        #expect(style != nil)
        #expect(style?.titleColor == .green)
        #expect(style?.titleFont == .callout)
        #expect(style?.subtitleColor == nil)
        #expect(style?.subtitleFont == nil)
    }

    @Test("BooleanSwitchRowStyle override is stored and retrieved correctly")
    func booleanSwitchRowStyleOverride() {
        var theme = FormTheme()
        theme["notifications"] = BooleanSwitchRowStyle(
            subtitleColor: .gray,
            subtitleFont: .footnote
        )

        let style = theme["notifications"] as? BooleanSwitchRowStyle
        #expect(style != nil)
        #expect(style?.titleColor == nil)
        #expect(style?.subtitleColor == .gray)
        #expect(style?.subtitleFont == .footnote)
    }

    @Test("SingleValueRowStyle override is stored and retrieved correctly")
    func singleValueRowStyleOverride() {
        var theme = FormTheme()
        theme["country"] = SingleValueRowStyle(
            titleColor: .purple,
            titleFont: .body
        )

        let style = theme["country"] as? SingleValueRowStyle
        #expect(style != nil)
        #expect(style?.titleColor == .purple)
        #expect(style?.titleFont == .body)
        #expect(style?.subtitleColor == nil)
    }

    @Test("ButtonRowStyle override is stored and retrieved correctly")
    func buttonRowStyleOverride() {
        var theme = FormTheme()
        theme["logout"] = ButtonRowStyle(
            titleColor: .red,
            subtitleColor: .secondary
        )

        let style = theme["logout"] as? ButtonRowStyle
        #expect(style != nil)
        #expect(style?.titleColor == .red)
        #expect(style?.subtitleColor == .secondary)
        #expect(style?.titleFont == nil)
    }

    @Test("NavigationRowStyle override is stored and retrieved correctly")
    func navigationRowStyleOverride() {
        var theme = FormTheme()
        theme["advanced"] = NavigationRowStyle(
            titleFont: .headline,
            subtitleFont: .caption2
        )

        let style = theme["advanced"] as? NavigationRowStyle
        #expect(style != nil)
        #expect(style?.titleFont == .headline)
        #expect(style?.subtitleFont == .caption2)
        #expect(style?.titleColor == nil)
    }

    @Test("row override entry can be overwritten with a new value")
    func rowOverrideOverwrite() {
        var theme = FormTheme()
        theme["email"] = TextInputRowStyle(titleColor: .blue)

        // Overwrite with a new style for the same key
        theme["email"] = TextInputRowStyle(titleColor: .red, titleFont: .headline)

        let style = theme["email"] as? TextInputRowStyle
        #expect(style?.titleColor == .red)
        #expect(style?.titleFont == .headline)
    }

    @Test("multiple row overrides with different types coexist independently")
    func multipleRowOverridesCoexist() {
        var theme = FormTheme()
        theme["email"] = TextInputRowStyle(titleColor: .blue)
        theme["tags"] = MultiValueRowStyle(selectionIcon: "star.fill")
        theme["status"] = InfoRowStyle(valueFont: .body)

        #expect((theme["email"] as? TextInputRowStyle)?.titleColor == .blue)
        #expect((theme["tags"] as? MultiValueRowStyle)?.selectionIcon == "star.fill")
        #expect((theme["status"] as? InfoRowStyle)?.valueFont == .body)
    }

    // MARK: Subscript access (String and RawRepresentable)

    @Test("string subscript sets and retrieves a row override")
    func stringSubscriptSetAndGet() {
        var theme = FormTheme()
        theme["email"] = TextInputRowStyle(titleColor: .blue, titleFont: .headline)

        let style = theme["email"] as? TextInputRowStyle
        #expect(style != nil)
        #expect(style?.titleColor == .blue)
        #expect(style?.titleFont == .headline)
    }

    @Test("string subscript is equivalent to direct rowOverrides access")
    func stringSubscriptEquivalentToDirectAccess() {
        var themeA = FormTheme()
        themeA["email"] = TextInputRowStyle(titleColor: .red)

        var themeB = FormTheme()
        themeB["email"] = TextInputRowStyle(titleColor: .red)

        let styleA = themeA["email"] as? TextInputRowStyle
        let styleB = themeB["email"] as? TextInputRowStyle
        #expect(styleA?.titleColor == styleB?.titleColor)
    }

    @Test("string subscript set to nil removes the override")
    func stringSubscriptSetToNilRemovesOverride() {
        var theme = FormTheme()
        theme["email"] = TextInputRowStyle(titleColor: .blue)
        theme["email"] = nil

        #expect(theme["email"] == nil)
    }

    @Test("string subscript and RawRepresentable subscript share the same storage")
    func stringAndTypedSubscriptShareStorage() {
        enum Row: String { case email }
        var theme = FormTheme()
        theme["email"] = TextInputRowStyle(titleColor: .blue)

        // Reading via typed subscript sees the value set via string subscript
        let style = theme[Row.email] as? TextInputRowStyle
        #expect(style?.titleColor == .blue)

        // Writing via typed subscript is visible via string subscript
        theme[Row.email] = TextInputRowStyle(titleColor: .green)
        let updated = theme["email"] as? TextInputRowStyle
        #expect(updated?.titleColor == .green)
    }

    @Test("typed subscript sets and retrieves a row override via RawRepresentable key")
    func typedSubscriptSetAndGet() {
        enum Row: String { case email }
        var theme = FormTheme()
        theme[Row.email] = TextInputRowStyle(titleColor: .blue, titleFont: .headline)

        let style = theme[Row.email] as? TextInputRowStyle
        #expect(style != nil)
        #expect(style?.titleColor == .blue)
        #expect(style?.titleFont == .headline)
    }

    @Test("typed subscript is equivalent to direct rowOverrides access")
    func typedSubscriptEquivalentToDirectAccess() {
        enum Row: String { case name }
        var themeA = FormTheme()
        themeA[Row.name] = TextInputRowStyle(titleColor: .red)

        var themeB = FormTheme()
        themeB["name"] = TextInputRowStyle(titleColor: .red)

        let styleA = themeA["name"] as? TextInputRowStyle
        let styleB = themeB["name"] as? TextInputRowStyle
        #expect(styleA?.titleColor == styleB?.titleColor)
    }

    @Test("typed subscript overwrites existing value for the same key")
    func typedSubscriptOverwrite() {
        enum Row: String { case email }
        var theme = FormTheme()
        theme[Row.email] = TextInputRowStyle(titleColor: .blue)
        theme[Row.email] = TextInputRowStyle(titleColor: .green, titleFont: .body)

        let style = theme[Row.email] as? TextInputRowStyle
        #expect(style?.titleColor == .green)
        #expect(style?.titleFont == .body)
    }

    @Test("typed subscript returns nil for unset key")
    func typedSubscriptMissingKeyReturnsNil() {
        enum Row: String { case email, name }
        var theme = FormTheme()
        theme[Row.email] = TextInputRowStyle(titleColor: .blue)

        #expect(theme[Row.name] == nil)
    }

    @Test("typed subscript set to nil removes the override")
    func typedSubscriptSetToNilRemovesOverride() {
        enum Row: String { case email }
        var theme = FormTheme()
        theme[Row.email] = TextInputRowStyle(titleColor: .blue)
        theme[Row.email] = nil

        #expect(theme[Row.email] == nil)
        #expect(theme["email"] == nil)
    }

    @Test("typed subscript uses rawValue as the underlying key")
    func typedSubscriptStringRawValue() {
        // Demonstrate that String-backed enums work regardless of naming
        enum FormField: String { case firstName = "first_name", lastName = "last_name" }
        var theme = FormTheme()
        theme[FormField.firstName] = TextInputRowStyle(titleColor: .blue)

        // The underlying key is the rawValue — readable via the string subscript
        let style = theme["first_name"] as? TextInputRowStyle
        #expect(style?.titleColor == .blue)
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
        // No overrides on the default theme
        #expect(theme["email"] == nil)
        #expect(theme["name"] == nil)
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
            "age": NumberInputRowStyle(titleFont: .callout)
        ]
        let theme = FormTheme(rowOverrides: overrides)
        #expect((theme["email"] as? TextInputRowStyle)?.titleColor == .blue)
        #expect((theme["age"] as? NumberInputRowStyle)?.titleFont == .callout)
        // Keys not in the overrides return nil
        #expect(theme["name"] == nil)
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
        let a = CollapsibleSectionStyle(disclosureIcon: "chevron.down", animationDuration: 0.4)
        let b = CollapsibleSectionStyle(disclosureIcon: "chevron.down", animationDuration: 0.4)
        #expect(a == b)
    }

    @Test("CollapsibleSectionStyle Equatable detects disclosureIcon difference")
    func collapsibleSectionStyleIconNotEquatable() {
        let a = CollapsibleSectionStyle(disclosureIcon: "chevron.down")
        let b = CollapsibleSectionStyle(disclosureIcon: "chevron.right")
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
            selectionIcon: "star.fill"
        )
        let b = MultiValueRowStyle(
            optionTextColor: .purple,
            selectionIndicatorColor: .green,
            selectionIcon: "star.fill"
        )
        #expect(a == b)
    }

    @Test("MultiValueRowStyle Equatable detects selectionIcon difference")
    func multiValueRowStyleIconNotEquatable() {
        let a = MultiValueRowStyle(selectionIcon: "checkmark")
        let b = MultiValueRowStyle(selectionIcon: "star.fill")
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

    @Test("TextInputRowStyle override with placeholderColor is stored and retrieved from theme")
    func textInputRowStylePlaceholderColorInTheme() {
        var theme = FormTheme()
        theme["email"] = TextInputRowStyle(placeholderColor: .indigo)

        let style = theme["email"] as? TextInputRowStyle
        #expect(style?.placeholderColor == .indigo)
        #expect(style?.titleColor == nil)
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

    @Test("per-row placeholderColor takes precedence over global token")
    func placeholderColorResolutionPrecedence() {
        // Both global token and per-row override set — per-row wins
        var theme = FormTheme(colors: .init(placeholder: .secondary))
        theme["email"] = TextInputRowStyle(placeholderColor: .blue)

        let globalColor = theme.colors.placeholder   // .secondary
        let rowColor = (theme["email"] as? TextInputRowStyle)?.placeholderColor  // .blue
        let resolved = rowColor ?? globalColor
        #expect(resolved == .blue)
    }

    @Test("global placeholder token is used when no per-row override is set")
    func placeholderColorFallsBackToGlobalToken() {
        let theme = FormTheme(colors: .init(placeholder: .secondary))
        // No per-row override for "name"
        let rowColor = (theme["name"] as? TextInputRowStyle)?.placeholderColor  // nil
        let resolved = rowColor ?? theme.colors.placeholder
        #expect(resolved == .secondary)
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
