import SwiftUI

// MARK: - MultiValueRowView

/// Renders a MultiValueRowRepresentable as a list of checkmark-toggled options.
/// Works without knowing the generic type T — operates on string descriptions only.
@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
struct MultiValueRowView: View {
    let row: any MultiValueRowRepresentable
    let rowId: String
    @Bindable var viewModel: FormViewModel

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
        VStack(alignment: .leading, spacing: 4) {
            headerView

            // Snapshot to avoid ambiguous ForEach overload resolution.
            let options = row.optionDescriptions
            let selected = selectedDescriptions

            ForEach(options, id: \.self) { description in
                optionRow(description: description, isSelected: selected.contains(description))
            }

            ValidationErrorView(errors: viewModel.errorsForRow(rowId))
        }
    }

    @ViewBuilder
    private var headerView: some View {
        if let subtitle = row.subtitle {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            Text(row.title)
        }
    }

    private func optionRow(description: String, isSelected: Bool) -> some View {
        Button {
            viewModel.toggleArrayValue(.string(description), for: rowId)
        } label: {
            HStack {
                Text(description)
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
