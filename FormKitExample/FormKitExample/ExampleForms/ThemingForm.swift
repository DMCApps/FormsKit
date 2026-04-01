import FormsKit
import SwiftUI

// MARK: - ThemingForm

/// Demonstrates form-level theming and per-row-ID style overrides.
///
/// Shows two examples side-by-side via a `SingleValueRow` picker:
/// - **Brand Theme**: A custom global theme (indigo palette, rounded save button).
/// - **Per-Row Overrides**: Same form with individual row overrides on top of the default theme.
enum ThemingForm {

    // MARK: Row ID enum

    /// Typed row IDs for the brand form — enables enum-case subscript access on `FormTheme`.
    enum RowID: String {
        case name  = "themingName"
        case email = "themingEmail"
    }

    // MARK: Brand theme

    /// A custom theme using an indigo/teal brand palette.
    static let brandTheme: FormTheme = {
        var theme = FormTheme(
            colors: .init(
                error: .orange,
                saveButtonBackground: .indigo,
                saveButtonDisabledBackground: Color.indigo.opacity(0.4),
                saveButtonForeground: .white,
                selectionIndicator: .teal,
                placeholder: Color.indigo.opacity(0.4)
            ),
            fonts: .init(
                rowTitle: .body.weight(.medium),
                subtitle: .footnote,
                saveButton: .headline
            ),
            spacing: .init(
                saveButtonCornerRadius: 16
            ),
            icons: .init(
                collapsibleDisclosure: "chevron.down",
                selectionCheckmark: "checkmark.circle.fill"
            ),
            saveButtonStyle: SaveButtonStyle(
                backgroundColor: .indigo,
                cornerRadius: 16
            ),
            validationErrorStyle: ValidationErrorStyle(
                color: .orange,
                icon: "exclamationmark.triangle.fill"
            )
        )
        // Highlight the email field using the typed subscript (no string literal needed)
        theme[RowID.email] = TextInputRowStyle(
            titleColor: .blue,
            titleFont: .headline,
            placeholderColor: .blue.opacity(0.5)
        )
        // Per-row overrides for other row types
        theme["themingNotifications"] = BooleanSwitchRowStyle(titleColor: .indigo)
        theme["themingTags"] = MultiValueRowStyle(
            optionTextColor: .indigo,
            selectionIndicatorColor: .teal
        )
        return theme
    }()

    // MARK: Form definitions

    /// The themed form — theme injected via `FormDefinition(theme:)`.
    static let brandDefinition = FormDefinition(
        id: "theming.brand",
        title: "Brand Theme",
        saveBehaviour: .buttonStickyBottom(),
        theme: brandTheme
    ) {
        FormSection(id: "themingProfileSection", title: "Profile") {
            TextInputRow(
                id: "themingName",
                title: "Full Name",
                subtitle: "Indigo placeholder via global colors.placeholder token",
                placeholder: "Jane Doe",
                validators: [.required(message: "Name is required")]
            )
            TextInputRow(
                id: "themingEmail",
                title: "Email",
                subtitle: "Blue placeholder via TextInputRowStyle override (beats global token)",
                keyboardType: .emailAddress,
                placeholder: "jane@example.com",
                validators: [.required(message: "Email is required")]
            )
            NumberInputRow(
                id: "themingAge",
                title: "Age",
                subtitle: "Indigo placeholder via global colors.placeholder token",
                placeholder: "30"
            )
        }

        FormSection(id: "themingPrefsSection", title: "Preferences") {
            BooleanSwitchRow(
                id: "themingNotifications",
                title: "Push Notifications",
                subtitle: "Title in indigo via BooleanSwitchRowStyle per-row override",
                defaultValue: true
            )
            MultiValueRow<ThemingTag>(
                id: "themingTags",
                title: "Interests",
                subtitle: "Option text and checkmark colored via MultiValueRowStyle per-row override"
            )
        }

        CollapsibleSection(
            id: "themingAdvanced",
            title: "Advanced (uses chevron.down icon)",
            isExpandedByDefault: false
        ) {
            InfoRow(id: "themingVersion", title: "Theme") { "Brand Theme" }
            SingleValueRow<ThemingSize>(
                id: "themingSize",
                title: "Text Size",
                defaultValue: .medium
            )
        }
    }

    /// Default theme form — demonstrates the `.formTheme(_:)` view modifier path.
    static let defaultDefinition = FormDefinition(
        id: "theming.default",
        title: "Default Theme",
        saveBehaviour: .buttonBottomForm()
    ) {
        FormSection(id: "themingDefaultSection", title: "Default Styling") {
            TextInputRow(
                id: "themingDefaultName",
                title: "Full Name",
                placeholder: "Jane Doe"
            )
            BooleanSwitchRow(
                id: "themingDefaultToggle",
                title: "Enable Feature",
                subtitle: "Uses the default theme tokens",
                defaultValue: false
            )
            MultiValueRow<ThemingTag>(
                id: "themingDefaultTags",
                title: "Interests"
            )
        }
    }
}

// MARK: - Support types

private enum ThemingSize: String, CaseIterable, CustomStringConvertible, Hashable, Sendable, Codable {
    case small, medium, large
    var description: String { rawValue.capitalized }
}

enum ThemingTag: String, CaseIterable, CustomStringConvertible, Hashable, Sendable, Codable {
    case swift, swiftui, ios, design, ux
    var description: String { rawValue.capitalized }
}

// MARK: - ThemingShowcaseView

/// Root view for the theming showcase — lets the user switch between the themed and default forms.
struct ThemingShowcaseView: View {
    var body: some View {
        List {
            Section("Using FormDefinition(theme:)") {
                NavigationLink("Brand Theme") {
                    DynamicFormView(formDefinition: ThemingForm.brandDefinition)
                }
            }
            Section("Using .formTheme(_:) modifier") {
                NavigationLink("Brand Theme via modifier") {
                    DynamicFormView(formDefinition: ThemingForm.defaultDefinition)
                        .formTheme(ThemingForm.brandTheme)
                }
                NavigationLink("Default Theme (baseline)") {
                    DynamicFormView(formDefinition: ThemingForm.defaultDefinition)
                }
            }
        }
        .navigationTitle("Theming")
    }
}
