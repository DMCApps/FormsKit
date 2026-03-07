import SwiftUI

// MARK: - BooleanSwitchRowView

/// Renders a BooleanSwitchRow as a SwiftUI Toggle.
@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
struct BooleanSwitchRowView: View {
    let row: BooleanSwitchRow
    @Bindable var viewModel: FormViewModel

    private var isOn: Bool {
        if let stored: Bool = viewModel.value(for: row.id) { return stored }
        if case let .bool(b) = row.defaultValue { return b }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(isOn: Binding(
                get: { isOn },
                set: { viewModel.setBool($0, for: row.id) }
            )) {
                rowLabel
            }
            .accessibilityIdentifier("formkit.toggle.\(row.id)")

            ValidationErrorView(errors: viewModel.errorsForRow(row.id), rowId: row.id)
        }
    }

    @ViewBuilder
    private var rowLabel: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(row.title)
            if let subtitle = row.subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
