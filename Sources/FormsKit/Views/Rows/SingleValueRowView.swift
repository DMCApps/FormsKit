import SwiftUI

// MARK: - SingleValueRowView

/// Renders a SingleValueRowRepresentable as a Picker.
/// Works without knowing the generic type T — operates on string descriptions only.
struct SingleValueRowView: View {
    let row: any SingleValueRowRepresentable
    let rowId: String
    @Bindable var viewModel: FormViewModel
    @Environment(\.formTheme) private var theme

    private var style: SingleValueRowStyle? { row.rowStyle as? SingleValueRowStyle }

    /// The stored value of the currently selected option, or `nil` when nothing is selected.
    ///
    /// Reads the raw `AnyCodableValue` and converts to `displayString` so the result matches
    /// the `storedValue` format used by `pickerOptions` regardless of the backing type
    /// (e.g. `.int(1)` → `"1"` for Int-backed enums, `.string("stage")` → `"stage"` for
    /// String-backed enums). Falling back to `typed(String.self)` would return `nil` for
    /// non-String-backed types after the value is stored with its correct `AnyCodableValue` case.
    private var currentStoredValue: String? {
        guard let raw = viewModel.rawValue(for: rowId), raw != .null else {
            return row.defaultStoredValue
        }
        return raw.displayString
    }

    /// The effective picker style after platform remapping.
    /// On tvOS, .menu and .automatic are remapped to .navigationLink for focusability.
    private var effectivePickerStyle: FormPickerStyle {
        #if os(tvOS)
        switch row.pickerStyle {
        case .menu, .automatic: return .navigationLink
        default: return row.pickerStyle
        }
        #else
        return row.pickerStyle
        #endif
    }

    var body: some View {
        let tint = style?.tintColor ?? theme.colors.pickerTint

        VStack(alignment: .leading, spacing: theme.spacing.rowContentSpacing) {
            switch effectivePickerStyle {
            case .segmented:
                // .segmented fills the full width — label sits above the control.
                VStack(alignment: .leading, spacing: theme.spacing.headerSpacing) {
                    rowLabel
                    styledPickerView(tint: tint)
                }
            case .navigationLink:
                // .navigationLink ignores .labelsHidden() and renders its own full-row
                // layout (label left, value + chevron right). Pass rowLabel directly as
                // the Picker label so title and subtitle both appear natively.
                styledPickerView(tint: tint)
            default:
                // .menu and .automatic: explicit HStack so title+subtitle are always
                // vertically centred against the picker value regardless of label length.
                HStack(alignment: .center) {
                    rowLabel
                    Spacer()
                    styledPickerView(tint: tint).labelsHidden()
                }
            }
            ValidationErrorView(errors: viewModel.errorsForRow(rowId), rowId: rowId)
        }
    }

    /// Title + subtitle stack — the left side of the HStack for non-segmented styles,
    /// and the explicit header for .segmented pickers.
    @ViewBuilder
    private var rowLabel: some View {
        let titleColor = style?.titleColor ?? theme.colors.rowTitle
        let titleFont = style?.titleFont ?? theme.fonts.rowTitle
        let subtitleColor = style?.subtitleColor ?? theme.colors.subtitle
        let subtitleFont = style?.subtitleFont ?? theme.fonts.subtitle

        VStack(alignment: .leading, spacing: theme.spacing.headerSpacing) {
            Text(row.title)
                .font(titleFont)
                .foregroundStyle(titleColor)
            if let subtitle = row.subtitle {
                Text(subtitle)
                    .font(subtitleFont)
                    .foregroundStyle(subtitleColor)
            }
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

    @ViewBuilder
    private func styledPickerView(tint: Color?) -> some View {
        if let tint {
            styledPicker.tint(tint)
        } else {
            styledPicker
        }
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
                    // Resolve the storedValue string back to the correctly-typed AnyCodableValue
                    // (e.g. .int(2) for Int-backed enums, not .string("2")). Falls back to
                    // setString only when anyCodableValue(for:) returns nil, which should not
                    // occur for any valid option produced by pickerOptions.
                    if let codable = row.anyCodableValue(for: newValue) {
                        viewModel.setValue(codable, for: rowId)
                    } else {
                        viewModel.setString(newValue, for: rowId)
                    }
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
            Picker(selection: binding, content: content) {
                rowLabel
            } currentValueLabel: {
                Text(currentValueText)
            }
            .accessibilityIdentifier("formkit.picker.\(rowId)")
        } else {
            Picker(selection: binding, content: content) {
                rowLabel
            }
            .accessibilityIdentifier("formkit.picker.\(rowId)")
        }
    }

    /// `pickerContent` with the appropriate platform style applied.
    @ViewBuilder
    private var styledPicker: some View {
        switch effectivePickerStyle {
        case .segmented:
            pickerContent.pickerStyle(.segmented)
        case .menu:
            pickerContent.pickerStyle(.menu)
        case .navigationLink:
#if os(macOS)
            pickerContent.pickerStyle(.automatic)
#else
            pickerContent.pickerStyle(.navigationLink)
#endif
        case .automatic:
            pickerContent.pickerStyle(.automatic)
        }
    }
}
