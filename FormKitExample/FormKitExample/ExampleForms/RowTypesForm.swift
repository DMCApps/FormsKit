import FormsKit
import Foundation

// MARK: - Support types

enum Colour: String, CaseIterable, CustomStringConvertible, Hashable, Sendable, Codable {
    case red, green, blue, yellow, purple
    var description: String { rawValue.capitalized }
}

enum Size: String, CaseIterable, CustomStringConvertible, Hashable, Sendable, Codable {
    case small, medium, large, extraLarge
    var description: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }
}

// MARK: - RowTypesForm

/// Demonstrates every built-in row type.
enum RowTypesForm {
    static let definition = FormDefinition(
        id: "rowTypes",
        title: "Row Types",
        saveBehaviour: .buttonNavigationBar()
    ) {
        // MARK: Text Input

        FormSection(id: "textInputSection", title: "TextInputRow") {
            TextInputRow(
                id: "plainText",
                title: "Plain Text",
                placeholder: "Type anything…"
            )

            TextInputRow(
                id: "secureText",
                title: "Secure (Password)",
                isSecure: true,
                placeholder: "••••••••"
            )

            TextInputRow(
                id: "secureTextToggle",
                title: "Secure with Toggle",
                subtitle: "showSecureToggle: true",
                isSecure: true,
                showSecureToggle: true,
                placeholder: "Tap eye to reveal"
            )

            TextInputRow(
                id: "emailText",
                title: "Email Keyboard",
                subtitle: "keyboardType: .emailAddress",
                keyboardType: .emailAddress,
                placeholder: "you@example.com"
            )

            TextInputRow(
                id: "urlText",
                title: "URL Keyboard",
                subtitle: "keyboardType: .url",
                keyboardType: .url,
                placeholder: "https://"
            )
        }

        // MARK: Number Input

        FormSection(id: "numberInputSection", title: "NumberInputRow") {
            NumberInputRow(
                id: "intNumber",
                title: "Integer",
                subtitle: "kind: .int",
                placeholder: "0",
                kind: .int(defaultValue: nil)
            )

            NumberInputRow(
                id: "decimalNumber",
                title: "Decimal",
                subtitle: "kind: .decimal",
                placeholder: "0.00",
                kind: .decimal(defaultValue: nil)
            )
        }

        // MARK: Boolean Switch

        FormSection(id: "boolSection", title: "BooleanSwitchRow") {
            BooleanSwitchRow(
                id: "toggle1",
                title: "Default Off",
                defaultValue: false
            )

            BooleanSwitchRow(
                id: "toggle2",
                title: "Default On",
                subtitle: "With a subtitle",
                defaultValue: true
            )
        }

        // MARK: Single Value Picker

        FormSection(id: "singleValueSection", title: "SingleValueRow") {
            SingleValueRow<Colour>(
                id: "colour",
                title: "Favourite Colour",
                subtitle: "No placeholder — picker starts blank"
            )

            SingleValueRow<Colour>(
                id: "colourWithPlaceholder",
                title: "Favourite Colour",
                subtitle: "placeholder: \"Choose a colour…\"",
                placeholder: "Choose a colour…"
            )

            SingleValueRow<Size>(
                id: "size",
                title: "T-Shirt Size",
                subtitle: "pickerStyle: .automatic, defaultValue: .medium",
                defaultValue: .medium
            )

            SingleValueRow<Colour>(
                id: "colourSegmented",
                title: "Colour (Segmented)",
                subtitle: "pickerStyle: .segmented — placeholder never shown",
                pickerStyle: .segmented
            )

            SingleValueRow<Size>(
                id: "sizeMenu",
                title: "Size (Menu)",
                subtitle: "pickerStyle: .menu, placeholder set",
                pickerStyle: .menu,
                placeholder: "Pick a size…"
            )

            SingleValueRow<Colour>(
                id: "colourNavLink",
                title: "Colour (Nav Link)",
                subtitle: "pickerStyle: .navigationLink, placeholder set",
                pickerStyle: .navigationLink,
                placeholder: "Select…"
            )
        }

        // MARK: Multi Value Picker

        FormSection(id: "multiValueSection", title: "MultiValueRow") {
            MultiValueRow<Colour>(
                id: "colours",
                title: "Favourite Colours",
                subtitle: "Pick as many as you like"
            )
        }

        // MARK: Button

        FormSection(id: "buttonSection", title: "ButtonRow") {
            ButtonRow(
                id: "tapMe",
                title: "Tap Me",
                subtitle: "Fires an arbitrary action"
            ) {
                // Action fires here (no side effects in the example).
            }
        }

        // MARK: Info (read-only)

        FormSection(id: "infoSection", title: "InfoRow") {
            InfoRow(id: "buildVersion", title: "Build Version") {
                Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
            }

            InfoRow(id: "bundleId", title: "Bundle ID") {
                Bundle.main.bundleIdentifier ?? "—"
            }
        }

        // MARK: Navigation

        FormSection(id: "navigationSection", title: "NavigationRow") {
            NavigationRow(
                id: "subForm",
                title: "Open Sub-form",
                subtitle: "Pushes a nested FormDefinition",
                destination: FormDefinition(
                    id: "rowTypes.sub",
                    title: "Sub-form",
                    saveBehaviour: .buttonNavigationBar()
                ) {
                    TextInputRow(id: "subField", title: "Sub-form Field", placeholder: "I'm nested!")
                }
            )
        }

        // MARK: Section (nested)

        FormSection(id: "nestedSectionOuter", title: "FormSection (nested rows)") {
            BooleanSwitchRow(id: "nestedA", title: "Row A inside a section")
            BooleanSwitchRow(id: "nestedB", title: "Row B inside the same section")
        }

        // MARK: Collapsible Section

        CollapsibleSection(id: "collapsibleExample", title: "CollapsibleSection (tap to toggle)") {
            BooleanSwitchRow(id: "collapsibleA", title: "Row A inside collapsible")
            BooleanSwitchRow(id: "collapsibleB", title: "Row B inside collapsible")
        }

        CollapsibleSection(
            id: "collapsibleExampleClosed",
            title: "CollapsibleSection (starts collapsed)",
            isExpandedByDefault: false
        ) {
            BooleanSwitchRow(id: "collapsibleC", title: "Row C inside collapsible")
        }
    }
}
