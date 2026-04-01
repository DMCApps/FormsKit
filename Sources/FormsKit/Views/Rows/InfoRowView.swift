import SwiftUI

/// Renders an `InfoRow` as a read-only label/value pair inside a Form.
/// The label is shown in the secondary style on the leading side;
/// the value is shown in caption style on the trailing side.
struct InfoRowView: View {
    let row: InfoRow
    @Environment(\.formTheme) private var theme

    private var style: InfoRowStyle? { theme.rowStyle(for: row.id, as: InfoRowStyle.self) }

    var body: some View {
        let labelColor = style?.titleColor ?? theme.colors.rowTitle
        let labelFont = style?.titleFont ?? theme.fonts.rowTitle
        let valueFont = style?.valueFont ?? theme.fonts.infoValue
        let valueColor = style?.valueColor ?? theme.colors.rowTitle

        HStack {
            Text(row.title)
                .font(labelFont)
                .foregroundStyle(labelColor)
            Spacer()
            Text(row.value())
                .font(valueFont)
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
    }
}
