import SwiftUI

// MARK: - NumberInputRowView

/// Renders a NumberInputRow as a TextField with numeric keyboard.
@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
struct NumberInputRowView: View {
    let row: NumberInputRow
    @Bindable var viewModel: FormViewModel

    // Use a local string buffer so the user can type freely.
    @State private var textBuffer: String = ""
    @FocusState private var isFocused: Bool
    @Environment(\.formTheme) private var theme

    private var style: NumberInputRowStyle? { row.rowStyle as? NumberInputRowStyle }

    var body: some View {
        let placeholderPrompt: Text? = {
            if let color = theme.colors.placeholder {
                return Text(row.placeholder ?? "").foregroundColor(color)
            }
            return nil
        }()
        VStack(alignment: .leading, spacing: theme.spacing.rowContentSpacing) {
            rowHeader
            TextField(row.placeholder ?? "", text: $textBuffer, prompt: placeholderPrompt)
                .focused($isFocused)
                .accessibilityIdentifier("formkit.field.\(row.id)")
#if os(iOS)
                .keyboardType(row.isDecimal ? .decimalPad : .numberPad)
#endif
                .onChange(of: textBuffer) { _, newValue in
                    commitText(newValue)
                }
                .onAppear {
                    if let raw = viewModel.rawValue(for: row.id) {
                        textBuffer = raw.displayString
                    }
                }
            ValidationErrorView(errors: viewModel.errorsForRow(row.id), rowId: row.id)
        }
        .onChange(of: isFocused) { _, newValue in
            if !newValue {
                viewModel.rowDidBlur(row.id)
            }
        }
    }

    @ViewBuilder
    private var rowHeader: some View {
        let titleColor = style?.titleColor ?? theme.colors.rowTitle
        let titleFont = style?.titleFont ?? theme.fonts.rowTitle
        let subtitleColor = style?.subtitleColor ?? theme.colors.subtitle
        let subtitleFont = style?.subtitleFont ?? theme.fonts.subtitle

        if let subtitle = row.subtitle {
            VStack(alignment: .leading, spacing: theme.spacing.headerSpacing) {
                Text(row.title)
                    .font(titleFont)
                    .foregroundStyle(titleColor)
                Text(subtitle)
                    .font(subtitleFont)
                    .foregroundStyle(subtitleColor)
            }
        } else {
            Text(row.title)
                .font(titleFont)
                .foregroundStyle(titleColor)
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
