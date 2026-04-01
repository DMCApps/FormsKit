import SwiftUI

// MARK: - SingleValueRowView

/// Renders a SingleValueRowRepresentable as a Picker.
/// Works without knowing the generic type T — operates on string descriptions only.
@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
struct SingleValueRowView: View {
    let row: any SingleValueRowRepresentable
    let rowId: String
    @Bindable var viewModel: FormViewModel

    /// The stored value of the currently selected option, or `nil` when nothing is selected.
    private var currentStoredValue: String? {
        viewModel.value(for: rowId) ?? row.defaultStoredValue
    }

    /// True when this row should use a nil-capable binding with a placeholder entry.
    /// Only meaningful for non-segmented styles; segmented requires all tags to be non-nil.
    private var showsPlaceholder: Bool {
        row.placeholder != nil && row.pickerStyle != .segmented
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
                    styledPicker
                }
            } else if let subtitle = row.subtitle {
                VStack(alignment: .leading, spacing: 2) {
                    styledPicker
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                styledPicker
            }
            ValidationErrorView(errors: viewModel.errorsForRow(rowId), rowId: rowId)
        }
    }

    // MARK: - Picker construction

    /// A picker using `Binding<String?>` with a nil-tagged placeholder entry.
    /// Only used when `showsPlaceholder` is true, ensuring nil is always matched by a tag.
    @ViewBuilder
    private var placeholderPicker: some View {
        let options = row.pickerOptions
        Picker(row.title, selection: Binding<String?>(
            get: { currentStoredValue },
            set: { newValue in
                if let newValue {
                    viewModel.setString(newValue, for: rowId)
                } else {
                    viewModel.setValue(nil, for: rowId)
                }
            }
        )) {
            // Only include the placeholder entry while nothing is selected yet.
            // Once a value is chosen the entry is omitted — no invisible tappable slot.
            if currentStoredValue == nil, let placeholder = row.placeholder {
                Text(placeholder).tag(nil as String?)
            }
            ForEach(options.indices, id: \.self) { index in
                Text(options[index].label).tag(String?.some(options[index].storedValue))
            }
        }
        .accessibilityIdentifier("formkit.picker.\(rowId)")
    }

    /// A picker using `Binding<String>` where the selection is always a valid stored value.
    /// Used for all cases where no placeholder is needed, avoiding nil-tag warnings.
    @ViewBuilder
    private var plainPicker: some View {
        let options = row.pickerOptions
        let selection = currentStoredValue ?? options.first?.storedValue ?? ""
        Picker(row.title, selection: Binding<String>(
            get: { selection },
            set: { viewModel.setString($0, for: rowId) }
        )) {
            ForEach(options.indices, id: \.self) { index in
                Text(options[index].label).tag(options[index].storedValue)
            }
        }
        .accessibilityIdentifier("formkit.picker.\(rowId)")
    }

    /// The picker with the appropriate style applied for the current platform.
    @ViewBuilder
    private var styledPicker: some View {
        let base = showsPlaceholder ? AnyView(placeholderPicker) : AnyView(plainPicker)
        switch row.pickerStyle {
        case .segmented:
            base.pickerStyle(.segmented)
        case .menu:
#if os(tvOS)
            base.pickerStyle(.automatic)
#else
            base.pickerStyle(.menu)
#endif
        case .navigationLink:
#if os(tvOS) || os(macOS)
            base.pickerStyle(.automatic)
#else
            base.pickerStyle(.navigationLink)
#endif
        case .automatic:
            base.pickerStyle(.automatic)
        }
    }
}
