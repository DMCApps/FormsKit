import SwiftUI

// MARK: - ValidationErrorView

/// Displays inline validation error messages below a form row.
/// Renders nothing if `errors` is empty.
struct ValidationErrorView: View {
    let errors: [String]
    var rowId: String = ""
    @Environment(\.formTheme) private var theme

    private var style: ValidationErrorStyle? { theme.validationErrorStyle }

    var body: some View {
        if !errors.isEmpty {
            let color = style?.color ?? theme.colors.error
            let font = style?.font ?? theme.fonts.error
            let icon = style?.icon ?? theme.icons.validationError

            VStack(alignment: .leading, spacing: theme.spacing.errorSpacing) {
                ForEach(errors, id: \.self) { error in
                    Label {
                        Text(error)
                            .font(font)
                            .foregroundStyle(color)
                    } icon: {
                        icon.image()
                            .foregroundStyle(color)
                            .font(font)
                    }
                }
            }
            .accessibilityIdentifier(rowId.isEmpty ? "formkit.errors" : "formkit.errors.\(rowId)")
        }
    }
}
