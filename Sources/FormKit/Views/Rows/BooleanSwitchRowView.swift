import SwiftUI

// MARK: - BooleanSwitchRowView

/// Renders a BooleanSwitchRow as a SwiftUI Toggle.
struct BooleanSwitchRowView: View {
    let row: BooleanSwitchRow
    @Bindable var viewModel: FormViewModel

    private var isOn: Bool {
        viewModel.value(for: row.id) ?? row.defaultIsOn
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(isOn: Binding(
                get: { isOn },
                set: { viewModel.setBool($0, for: row.id) }
            )) {
                rowLabel
            }

            ValidationErrorView(errors: viewModel.errorsForRow(row.id))
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
