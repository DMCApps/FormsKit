import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - FormKeyboardType + UIKeyboardType

#if os(iOS)
extension FormKeyboardType {
    var uiKeyboardType: UIKeyboardType {
        switch self {
        case .default: return .default
        case .decimalPad: return .decimalPad
        case .numberPad: return .numberPad
        case .emailAddress: return .emailAddress
        case .url: return .URL
        case .phonePad: return .phonePad
        }
    }
}
#endif

// MARK: - TextInputRowView

/// Renders a TextInputRow as a TextField or SecureField.
@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
struct TextInputRowView: View {
    let row: TextInputRow
    @Bindable var viewModel: FormViewModel

    private var text: String {
        if let mask = row.mask,
           let fromStorable = mask.fromStorable,
           let stored = viewModel.values[row.id],
           let chars = fromStorable(stored) {
            // Mask has a fromStorable converter — use it to recover raw slot chars.
            return chars
        } else if let stored: String = viewModel.value(for: row.id) {
            return stored
        }
        if case let .string(s) = row.defaultValue { return s }
        return ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            rowHeader
            inputField
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

    @ViewBuilder
    private var inputField: some View {
        if let mask = row.mask {
            // Masked input: display string has literals inserted. Masks with a `toStorable`
            // closure store a typed value; all others store the raw slot chars as `.string`.
            let binding = Binding(
                get: { mask.apply(to: text) },
                set: { newFormatted in
                    let raw = mask.strip(from: newFormatted)
                    let clamped = String(raw.prefix(mask.maxInputLength))
                    if let toStorable = mask.toStorable,
                       clamped.count == mask.maxInputLength,
                       let typed = toStorable(clamped) {
                        // Mask has a toStorable converter and the input is complete — store typed value.
                        viewModel.setValue(typed, for: row.id)
                    } else {
                        // No converter, or input is incomplete — store raw chars as a string.
                        viewModel.setString(clamped, for: row.id)
                    }
                }
            )
            TextField(mask.pattern, text: binding)
                .textContentType(.none)
                .autocorrectionDisabled()
#if os(iOS)
                .keyboardType(row.keyboardType.uiKeyboardType)
                .textInputAutocapitalization(.never)
#endif
        } else {
            let binding = Binding(
                get: { text },
                set: { viewModel.setString($0, for: row.id) }
            )
            if row.isSecure {
                SecureField(row.placeholder ?? "", text: binding)
            } else {
                TextField(row.placeholder ?? "", text: binding)
                    .textContentType(.none)
                    .autocorrectionDisabled()
#if os(iOS)
                    .keyboardType(row.keyboardType.uiKeyboardType)
                    .textInputAutocapitalization(.never)
#endif
            }
        }
    }
}
