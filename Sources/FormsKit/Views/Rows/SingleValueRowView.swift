import SwiftUI

// MARK: - SingleValueRowView

/// Renders a SingleValueRowRepresentable as a Picker.
/// Works without knowing the generic type T — operates on string descriptions only.
@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
struct SingleValueRowView: View {
    let row: any SingleValueRowRepresentable
    let rowId: String
    @Bindable var viewModel: FormViewModel
    @Environment(\.formTheme) private var theme

    private var style: SingleValueRowStyle? { theme.rowStyle(for: rowId, as: SingleValueRowStyle.self) }

    /// The stored value of the currently selected option, or `nil` when nothing is selected.
    private var currentStoredValue: String? {
        viewModel.value(for: rowId) ?? row.defaultStoredValue
    }

    var body: some View {
        let subtitleColor = style?.subtitleColor ?? theme.colors.subtitle
        let subtitleFont = style?.subtitleFont ?? theme.fonts.subtitle

        VStack(alignment: .leading, spacing: theme.spacing.rowContentSpacing) {
            if row.pickerStyle == .segmented {
                // .segmented picker style suppresses the Picker's built-in label,
                // so we render the title (and optional subtitle) explicitly above the control.
                VStack(alignment: .leading, spacing: theme.spacing.rowContentSpacing) {
                    Text(row.title)
                    if let subtitle = row.subtitle {
                        Text(subtitle)
                            .font(subtitleFont)
                            .foregroundStyle(subtitleColor)
                    }
                    styledPicker
                }
            } else if let subtitle = row.subtitle {
                VStack(alignment: .leading, spacing: theme.spacing.headerSpacing) {
                    styledPicker
                    Text(subtitle)
                        .font(subtitleFont)
                        .foregroundStyle(subtitleColor)
                }
            } else {
                styledPicker
            }
            ValidationErrorView(errors: viewModel.errorsForRow(rowId), rowId: rowId)
        }
    }

    // MARK: - Picker construction

    /// The resolved label for the current selection, or the placeholder when nothing is selected.
    /// Used by `currentValueLabel` to drive the inline display without needing a nil-tagged entry.
    private var currentValueText: String {
        let options = row.pickerOptions
        return currentStoredValue
            .flatMap { sv in options.first(where: { $0.storedValue == sv })?.label }
            ?? row.placeholder
            ?? ""
    }

    /// A single picker using `Binding<String?>` with every option tagged as `String?`.
    /// Following Apple's canonical pattern: all tags match the binding's type, and
    /// `currentValueLabel` handles the nil/"no selection" display — no nil-tagged entry needed.
    ///
    /// On iOS 18+ we use `currentValueLabel:` to show the placeholder text when nothing is
    /// selected. On iOS 17 we fall back to the standard initialiser; the picker will show
    /// the row title when nothing is selected, which is the best available behaviour.
    @ViewBuilder
    private var pickerContent: some View {
        let options = row.pickerOptions
        let binding = Binding<String?>(
            get: { currentStoredValue },
            set: { newValue in
                if let newValue {
                    viewModel.setString(newValue, for: rowId)
                } else {
                    viewModel.setValue(nil, for: rowId)
                }
            }
        )
        let content = {
            ForEach(options.indices, id: \.self) { index in
                Text(options[index].label).tag(options[index].storedValue as String?)
            }
        }
        if #available(iOS 18, tvOS 18, macOS 15, visionOS 2, *) {
            Picker(row.title, selection: binding, content: content) {
                Text(currentValueText)
            }
            .accessibilityIdentifier("formkit.picker.\(rowId)")
        } else {
            Picker(row.title, selection: binding, content: content)
                .accessibilityIdentifier("formkit.picker.\(rowId)")
        }
    }

    /// `pickerContent` with the appropriate platform style applied.
    @ViewBuilder
    private var styledPicker: some View {
        switch row.pickerStyle {
        case .segmented:
            pickerContent.pickerStyle(.segmented)
        case .menu:
#if os(tvOS)
            pickerContent.pickerStyle(.automatic)
#else
            pickerContent.pickerStyle(.menu)
#endif
        case .navigationLink:
#if os(tvOS) || os(macOS)
            pickerContent.pickerStyle(.automatic)
#else
            pickerContent.pickerStyle(.navigationLink)
#endif
        case .automatic:
            pickerContent.pickerStyle(.automatic)
        }
    }
}
