import SwiftUI

// MARK: - MultiValueRowView

/// Renders a MultiValueRowRepresentable as a list of checkmark-toggled options.
/// Works without knowing the generic type T — operates on string descriptions only.
struct MultiValueRowView: View {
    let row: any MultiValueRowRepresentable
    let rowId: String
    @Bindable var viewModel: FormViewModel
    @Environment(\.formTheme) private var theme

    private var style: MultiValueRowStyle? { row.rowStyle as? MultiValueRowStyle }

    private var selectedDescriptions: Set<String> {
        guard case let .array(arr) = viewModel.rawValue(for: rowId) else {
            return Set(row.selectedDescriptions)
        }
        let strings = arr.compactMap { val -> String? in
            if case let .string(s) = val { return s }
            return nil
        }
        return Set(strings)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.rowContentSpacing) {
            headerView

            // Snapshot to avoid ambiguous ForEach overload resolution.
            let options = row.optionDescriptions
            let selected = selectedDescriptions

            ForEach(options, id: \.self) { description in
                optionRow(description: description, isSelected: selected.contains(description))
                    .padding(.vertical, theme.spacing.optionRowVerticalPadding)
            }

            ValidationErrorView(errors: viewModel.errorsForRow(rowId), rowId: rowId)
        }
    }

    @ViewBuilder
    private var headerView: some View {
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

    private func optionRow(description: String, isSelected: Bool) -> some View {
        let optionColor = style?.optionTextColor ?? theme.colors.optionText
        let indicatorColor = style?.selectionIndicatorColor ?? theme.colors.selectionIndicator
        let indicatorIcon = style?.selectionIcon ?? theme.icons.selectionCheckmark

        return Button {
            viewModel.toggleArrayValue(.string(description), for: rowId)
        } label: {
            HStack {
                Text(description)
                    .foregroundStyle(optionColor)
                Spacer()
                if isSelected {
                    indicatorIcon.image()
                        .foregroundStyle(indicatorColor)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
