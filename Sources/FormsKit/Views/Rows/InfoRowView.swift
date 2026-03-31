import SwiftUI

/// Renders an `InfoRow` as a read-only label/value pair inside a Form.
/// The label is shown in the secondary style on the leading side;
/// the value is shown in caption style on the trailing side.
struct InfoRowView: View {
    let row: InfoRow

    var body: some View {
        HStack {
            Text(row.title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(row.value())
                .font(.caption)
                .multilineTextAlignment(.trailing)
        }
    }
}
