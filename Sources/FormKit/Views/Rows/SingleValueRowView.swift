import SwiftUI

// MARK: - SingleValueRowView

/// Renders a SingleValueRowRepresentable as a Picker.
/// Works without knowing the generic type T — operates on string descriptions only.
@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
struct SingleValueRowView: View {
    let row: any SingleValueRowRepresentable
    let rowId: String
    @Bindable var viewModel: FormViewModel

    private var selectedDescription: String {
        viewModel.value(for: rowId) ?? row.selectedDescription ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let subtitle = row.subtitle {
                VStack(alignment: .leading, spacing: 2) {
                    pickerView
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                pickerView
            }
            ValidationErrorView(errors: viewModel.errorsForRow(rowId), rowId: rowId)
        }
    }

    private var pickerView: some View {
        Picker(row.title, selection: Binding(
            get: { selectedDescription },
            set: { viewModel.setString($0, for: rowId) }
        )) {
            ForEach(row.optionDescriptions, id: \.self) { description in
                Text(description).tag(description)
            }
        }
    }
}
