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
        #expect(theme.colors.saveButtonForeground == .white)
        #expect(theme.colors.optionText == .primary)
    }

    @Test("default theme has expected font tokens")
    func defaultFonts() {
        let theme = FormTheme.default
        #expect(theme.fonts.subtitle == .caption)
        #expect(theme.fonts.error == .caption)
        #expect(theme.fonts.infoValue == .caption)
        #expect(theme.fonts.rowTitle == .subheadline)
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
}
