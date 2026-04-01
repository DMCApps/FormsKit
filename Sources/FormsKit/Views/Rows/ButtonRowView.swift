import SwiftUI

/// Renders a `ButtonRow` as a full-width tappable button inside a Form.
struct ButtonRowView: View {
    let row: ButtonRow
    @Environment(\.formTheme) private var theme

    private var style: ButtonRowStyle? { theme.rowStyle(for: row.id, as: ButtonRowStyle.self) }

    var body: some View {
        let titleColor = style?.titleColor ?? theme.colors.rowTitle
        let titleFont = style?.titleFont ?? theme.fonts.rowTitle
        let subtitleColor = style?.subtitleColor ?? theme.colors.subtitle
        let subtitleFont = style?.subtitleFont ?? theme.fonts.subtitle

        Button(action: row.action) {
            VStack(alignment: .leading, spacing: theme.spacing.headerSpacing) {
                Text(row.title)
                    .font(titleFont)
                    .foregroundStyle(titleColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let subtitle = row.subtitle {
                    Text(subtitle)
                        .font(subtitleFont)
                        .foregroundStyle(subtitleColor)
                }
            }
        }
    }
}
