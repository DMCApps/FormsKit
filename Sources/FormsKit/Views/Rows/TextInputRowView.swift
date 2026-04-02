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

// MARK: - MaskedTextField (UIViewRepresentable)

#if os(iOS)
/// A UIViewRepresentable wrapper around UITextField that applies a FormInputMask.
/// Using UITextFieldDelegate.textField(_:shouldChangeCharactersIn:replacementString:)
/// is the only reliable way to intercept keystrokes and reformat text in UIKit —
/// SwiftUI's TextField ignores programmatic text changes made from within its own binding setter.
@available(iOS 17, *)
struct MaskedTextField: UIViewRepresentable {
    let mask: FormInputMask
    let placeholder: String
    let placeholderColor: Color?
    let keyboardType: UIKeyboardType
    let accessibilityIdentifier: String
    /// Raw slot characters (no literals), clamped to maxInputLength.
    @Binding var rawText: String

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        if let placeholderColor {
            field.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: UIColor(placeholderColor)]
            )
        } else {
            field.placeholder = placeholder
        }
        field.keyboardType = keyboardType
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.textContentType = .none
        field.accessibilityIdentifier = accessibilityIdentifier
        // Seed the initial display value.
        field.text = mask.apply(to: rawText)
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        // Only update if the field is not currently being edited — let the delegate own it while active.
        guard !uiView.isFirstResponder else { return }
        let expected = mask.apply(to: rawText)
        if uiView.text != expected {
            uiView.text = expected
        }
        // Re-sync placeholder appearance in case placeholderColor changed (e.g. theme update).
        if let color = placeholderColor {
            uiView.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: UIColor(color)]
            )
        } else {
            uiView.placeholder = placeholder
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(mask: mask, rawText: $rawText)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UITextFieldDelegate {
        let mask: FormInputMask
        @Binding var rawText: String

        init(mask: FormInputMask, rawText: Binding<String>) {
            self.mask = mask
            _rawText = rawText
        }

        func textField(_ textField: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
            let current = textField.text ?? ""
            guard let swiftRange = Range(range, in: current) else { return false }

            // Compute what the field would contain after the edit.
            let proposed = current.replacingCharacters(in: swiftRange, with: string)

            // Strip literals and clamp to the maximum number of input slots.
            let raw = mask.strip(from: proposed)
            let clamped = String(raw.prefix(mask.maxInputLength))

            // Apply the mask to get the formatted display string.
            let formatted = mask.apply(to: clamped)

            // Update the field text and cursor ourselves — returning false prevents UIKit's default.
            textField.text = formatted

            // Place the cursor at the end of the formatted text.
            if let end = textField.position(from: textField.endOfDocument, offset: 0) {
                textField.selectedTextRange = textField.textRange(from: end, to: end)
            }

            // Propagate the raw (no-literal) characters back to SwiftUI.
            rawText = clamped

            return false
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
    @FocusState private var isFocused: Bool
    /// Tracks whether a secure field is currently revealed via the eye toggle.
    @State private var isRevealed = false
    @Environment(\.formTheme) private var theme

    private var style: TextInputRowStyle? { row.rowStyle as? TextInputRowStyle }

    /// Builds a `Text` prompt for `TextField`/`SecureField`, applying the resolved placeholder color.
    /// Resolution order: per-row override → global token → system default (nil = plain Text).
    private func placeholderPrompt(for placeholder: String) -> Text {
        if let color = style?.placeholderColor ?? theme.colors.placeholder {
            return Text(placeholder).foregroundColor(color)
        }
        return Text(placeholder)
    }

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
        if let mask = row.mask {
// Masked input: use a UIViewRepresentable so the UITextFieldDelegate can intercept
// each keystroke, reformat the display text, and clamp to the mask length reliably.
// SwiftUI's TextField ignores programmatic text changes made from within its own
// binding setter during active editing, making the delegate approach necessary.
#if os(iOS)
            let rawBinding = Binding<String>(
                get: { text },
                set: { newRaw in
                    guard newRaw != text else { return }
                    let clamped = String(newRaw.prefix(mask.maxInputLength))
                    if let toStorable = mask.toStorable,
                       clamped.count == mask.maxInputLength,
                       let typed = toStorable(clamped) {
                        viewModel.setValue(typed, for: row.id)
                    } else {
                        viewModel.setString(clamped, for: row.id)
                    }
                }
            )
            MaskedTextField(
                mask: mask,
                placeholder: row.placeholder ?? mask.pattern,
                placeholderColor: style?.placeholderColor ?? theme.colors.placeholder,
                keyboardType: row.keyboardType.uiKeyboardType,
                accessibilityIdentifier: "formkit.field.\(row.id)",
                rawText: rawBinding
            )
#else
            // Non-iOS fallback: plain SwiftUI TextField with best-effort masking.
            let binding = Binding(
                get: { mask.apply(to: text) },
                set: { newFormatted in
                    let raw = mask.strip(from: newFormatted)
                    let clamped = String(raw.prefix(mask.maxInputLength))
                    guard clamped != text else { return }
                    if let toStorable = mask.toStorable,
                       clamped.count == mask.maxInputLength,
                       let typed = toStorable(clamped) {
                        viewModel.setValue(typed, for: row.id)
                    } else {
                        viewModel.setString(clamped, for: row.id)
                    }
                }
            )
            let maskedPrompt = placeholderPrompt(for: mask.pattern)
            TextField(text: binding, prompt: maskedPrompt) { EmptyView() }
                .textContentType(.none)
                .autocorrectionDisabled()
                .accessibilityLabel(row.title)
                .accessibilityIdentifier("formkit.field.\(row.id)")
#endif
        } else {
            let binding = Binding(
                get: { text },
                set: { newValue in
                    guard newValue != text else { return }
                    viewModel.setString(newValue, for: row.id)
                }
            )
            let prompt = placeholderPrompt(for: row.placeholder ?? "")
            if row.isSecure {
                HStack(spacing: 8) {
                    if isRevealed {
                        TextField(text: binding, prompt: prompt) { EmptyView() }
                            .focused($isFocused)
                            .textContentType(.none)
                            .autocorrectionDisabled()
                            .accessibilityLabel(row.title)
                            .accessibilityIdentifier("formkit.field.\(row.id)")
#if os(iOS)
                            .textInputAutocapitalization(.never)
#endif
                    } else {
                        SecureField("", text: binding, prompt: prompt)
                            .focused($isFocused)
                            .accessibilityIdentifier("formkit.field.\(row.id)")
                    }
                    if row.showSecureToggle {
                        Button {
                            isRevealed.toggle()
                        } label: {
                            (isRevealed ? theme.icons.secureFieldHide : theme.icons.secureFieldReveal).image()
                                .foregroundStyle(theme.colors.secureFieldToggle)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
                    }
                }
            } else {
                TextField(text: binding, prompt: prompt) { EmptyView() }
                    .focused($isFocused)
                    .textContentType(.none)
                    .autocorrectionDisabled()
                    .accessibilityLabel(row.title)
                    .accessibilityIdentifier("formkit.field.\(row.id)")
#if os(iOS)
                    .keyboardType(row.keyboardType.uiKeyboardType)
                    .textInputAutocapitalization(.never)
#endif
            }
        }
    }
}
