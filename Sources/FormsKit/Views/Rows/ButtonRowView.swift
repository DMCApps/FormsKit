import SwiftUI

/// Renders a `ButtonRow` as a full-width tappable button inside a Form.
struct ButtonRowView: View {
    let row: ButtonRow

    var body: some View {
        Button(action: row.action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let subtitle = row.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
