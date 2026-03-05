import SwiftUI

// MARK: - EmailInputRowView

/// Renders an EmailInputRow as a TextField configured for email input.
struct EmailInputRowView: View {
    let row: EmailInputRow
    @Bindable var viewModel: FormViewModel

    private var text: String {
        viewModel.value(for: row.id) ?? row.defaultEmail ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            rowHeader
            TextField(row.placeholder ?? "email@example.com", text: Binding(
                get: { text },
                set: { viewModel.setString($0, for: row.id) }
            ))
            .textContentType(.emailAddress)
#if os(iOS)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
#endif
                .autocorrectionDisabled()

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
}
