import SwiftUI

// MARK: - LongFormTextRowView

struct LongFormTextRowView: View {
    let row: LongFormTextRow
    @Bindable var viewModel: FormViewModel
    @FocusState private var isFocused: Bool
    @Environment(\.formTheme) private var theme

    private var style: LongFormTextRowStyle? { row.rowStyle as? LongFormTextRowStyle }

    private var text: String {
        if let stored: String = viewModel.value(for: row.id) {
            return stored
        }
        if case let .string(s) = row.defaultValue { return s }
        return ""
    }

    private func placeholderPrompt(for placeholder: String) -> Text {
        if let color = style?.placeholderColor ?? theme.colors.placeholder {
            return Text(placeholder).foregroundColor(color)
        }
        return Text(placeholder)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.rowContentSpacing) {
            rowHeader
            inputField
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

    @ViewBuilder
    private var inputField: some View {
        let binding = Binding(
            get: { text },
            set: { newValue in
                guard newValue != text else { return }
                viewModel.setString(newValue, for: row.id)
            }
        )
        let prompt = placeholderPrompt(for: row.placeholder ?? "")
        TextField(text: binding, prompt: prompt, axis: .vertical) { EmptyView() }
            .lineLimit(row.minLineCount...row.maxLineCount)
            .focused($isFocused)
            .textContentType(.none)
            .accessibilityLabel(row.title)
            .accessibilityIdentifier("formkit.field.\(row.id)")
            #if os(iOS)
            .textInputAutocapitalization(.sentences)
            #endif
    }
}
