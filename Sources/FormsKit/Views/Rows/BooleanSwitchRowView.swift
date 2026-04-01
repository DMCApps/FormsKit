import SwiftUI

// MARK: - BooleanSwitchRowView

/// Renders a BooleanSwitchRow as a SwiftUI Toggle.
@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
struct BooleanSwitchRowView: View {
    let row: BooleanSwitchRow
    @Bindable var viewModel: FormViewModel
    @Environment(\.formTheme) private var theme

    private var style: BooleanSwitchRowStyle? { theme.rowStyle(for: row.id, as: BooleanSwitchRowStyle.self) }

    private var isOn: Bool {
        if let stored: Bool = viewModel.value(for: row.id) { return stored }
        if case let .bool(b) = row.defaultValue { return b }
        return false
    }

    var body: some View {
        let tint = style?.tintColor ?? theme.colors.switchTint
        VStack(alignment: .leading, spacing: theme.spacing.rowContentSpacing) {
            let toggle = Toggle(isOn: Binding(
                get: { isOn },
                set: { viewModel.setBool($0, for: row.id) }
            )) {
                rowLabel
            }
            .accessibilityIdentifier("formkit.toggle.\(row.id)")

            if let tint {
                toggle.tint(tint)
            } else {
                toggle
            }

            ValidationErrorView(errors: viewModel.errorsForRow(row.id), rowId: row.id)
        }
    }

    @ViewBuilder
    private var rowLabel: some View {
        let titleColor = style?.titleColor ?? theme.colors.rowTitle
        let titleFont = style?.titleFont ?? theme.fonts.rowTitle
        let subtitleColor = style?.subtitleColor ?? theme.colors.subtitle
        let subtitleFont = style?.subtitleFont ?? theme.fonts.subtitle

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
}
