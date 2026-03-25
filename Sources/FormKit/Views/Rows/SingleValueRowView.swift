import SwiftUI

// MARK: - SingleValueRowView

/// Renders a SingleValueRowRepresentable as a Picker.
/// Works without knowing the generic type T — operates on string descriptions only.
@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
struct SingleValueRowView: View {
    let row: any SingleValueRowRepresentable
    let rowId: String
    @Bindable var viewModel: FormViewModel

    /// The stored value of the currently selected option.
    private var currentStoredValue: String {
        viewModel.value(for: rowId) ?? row.defaultStoredValue ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if row.pickerStyle == .segmented {
                // .segmented picker style suppresses the Picker's built-in label,
                // so we render the title (and optional subtitle) explicitly above the control.
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.title)
                    if let subtitle = row.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    pickerView
                }
            } else if let subtitle = row.subtitle {
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
        let options = row.pickerOptions
        let picker = Picker(row.title, selection: Binding(
            get: { currentStoredValue },
            set: { viewModel.setString($0, for: rowId) }
        )) {
            ForEach(options.indices, id: \.self) { index in
                Text(options[index].label).tag(options[index].storedValue)
            }
        }
        .accessibilityIdentifier("formkit.picker.\(rowId)")

        return Group {
            switch row.pickerStyle {
            case .segmented:
                picker.pickerStyle(.segmented)
            case .menu:
#if os(tvOS)
                // .menu is unavailable on tvOS — fall back to automatic
                picker.pickerStyle(.automatic)
#else
                picker.pickerStyle(.menu)
#endif
            case .navigationLink:
#if os(tvOS) || os(macOS)
                // .navigationLink is unavailable on tvOS and macOS — fall back to automatic
                picker.pickerStyle(.automatic)
#else
                picker.pickerStyle(.navigationLink)
#endif
            case .automatic:
                picker.pickerStyle(.automatic)
            }
        }
    }
}
