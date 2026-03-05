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
        if let stored: String = viewModel.value(for: row.id) { return stored }
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
