import SwiftUI

// MARK: - NumberInputRowView

/// Renders a NumberInputRow as a TextField with numeric keyboard.
@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
struct NumberInputRowView: View {
    let row: NumberInputRow
    @Bindable var viewModel: FormViewModel

    // Use a local string buffer so the user can type freely.
    @State private var textBuffer: String = ""
    @State private var didInitialise = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            rowHeader
            TextField(row.placeholder ?? "", text: $textBuffer)
#if os(iOS)
                .keyboardType(row.isDecimal ? .decimalPad : .numberPad)
#endif
                .onChange(of: textBuffer) { _, newValue in
                    commitText(newValue)
                }
                .onAppear {
                    guard !didInitialise else { return }
                    didInitialise = true
                    if let raw = viewModel.rawValue(for: row.id) {
                        textBuffer = raw.displayString
                    }
                }
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

    private func commitText(_ text: String) {
        if row.isDecimal {
            if let double = Double(text) {
                viewModel.setDouble(double, for: row.id)
            } else if text.isEmpty {
                viewModel.setValue(nil, for: row.id)
            }
        } else {
            if let int = Int(text) {
                viewModel.setInt(int, for: row.id)
            } else if text.isEmpty {
                viewModel.setValue(nil, for: row.id)
            }
        }
    }
}
