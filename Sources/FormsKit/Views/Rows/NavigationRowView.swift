import SwiftUI

// MARK: - NavigationRowView

/// Renders a NavigationRow as a NavigationLink to a sub-form.
@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
struct NavigationRowView: View {
    let row: NavigationRow
    @Bindable var viewModel: FormViewModel
    @Environment(\.formTheme) private var theme

    private var style: NavigationRowStyle? { theme.rowStyle(for: row.id, as: NavigationRowStyle.self) }

    var body: some View {
        let subtitleColor = style?.subtitleColor ?? theme.colors.subtitle
        let subtitleFont = style?.subtitleFont ?? theme.fonts.subtitle

        NavigationLink {
            DynamicFormView(formDefinition: row.destination)
        } label: {
            VStack(alignment: .leading, spacing: theme.spacing.headerSpacing) {
                Text(row.title)
                if let subtitle = row.subtitle {
                    Text(subtitle)
                        .font(subtitleFont)
                        .foregroundStyle(subtitleColor)
                }
            }
        }
        .accessibilityIdentifier("formkit.navrow.\(row.id)")
    }
}
