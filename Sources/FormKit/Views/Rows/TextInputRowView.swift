import SwiftUI

// MARK: - TextInputRowView

/// Renders a TextInputRow as a TextField or SecureField.
struct TextInputRowView: View {
    let row: TextInputRow
    @Bindable var viewModel: FormViewModel

    private var text: String {
        viewModel.value(for: row.id) ?? row.defaultText ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            rowHeader
            inputField
            ValidationErrorView(errors: viewModel.errorsForRow(row.id))
        }
    }

    @ViewBuilder
    private var rowHeader: some View {
        if let subtitle = row.subtitle {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            Text(row.title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var inputField: some View {
        let binding = Binding(
            get: { text },
            set: { viewModel.setString($0, for: row.id) }
        )

        if row.isSecure {
            SecureField(row.placeholder ?? "", text: binding)
        } else {
            TextField(row.placeholder ?? "", text: binding)
                .textContentType(.none)
                .autocorrectionDisabled()
#if os(iOS)
                .textInputAutocapitalization(.never)
#endif
        }
    }
}
