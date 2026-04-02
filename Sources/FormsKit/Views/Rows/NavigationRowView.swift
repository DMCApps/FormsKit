import SwiftUI

// MARK: - NavigationRowView

/// Renders a NavigationRow as a NavigationLink to a sub-form.
struct NavigationRowView: View {
    let row: NavigationRow
    @Bindable var viewModel: FormViewModel
    @Environment(\.formTheme) private var theme

    private var style: NavigationRowStyle? { row.rowStyle as? NavigationRowStyle }

    var body: some View {
        let titleColor = style?.titleColor ?? theme.colors.rowTitle
        let titleFont = style?.titleFont ?? theme.fonts.rowTitle
        let subtitleColor = style?.subtitleColor ?? theme.colors.subtitle
        let subtitleFont = style?.subtitleFont ?? theme.fonts.subtitle

        NavigationLink {
            DynamicFormView(formDefinition: row.destination)
        } label: {
            VStack(alignment: .leading, spacing: theme.spacing.headerSpacing) {
                Text(row.title)
                    .font(titleFont)
                    .foregroundStyle(titleColor)
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
