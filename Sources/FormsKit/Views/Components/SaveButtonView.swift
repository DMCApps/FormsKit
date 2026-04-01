import SwiftUI

// MARK: - SaveButtonView

/// A prominent save button rendered inside a Form list row, with an optional loading indicator.
struct SaveButtonView: View {
    let title: String
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    @Environment(\.formTheme) private var theme

    private var style: SaveButtonStyle? { theme.saveButtonStyle }

    var body: some View {
        let bgColor = isDisabled
            ? (style?.disabledBackgroundColor ?? theme.colors.saveButtonDisabledBackground)
            : (style?.backgroundColor ?? theme.colors.saveButtonBackground)
        let fgColor = style?.foregroundColor ?? theme.colors.saveButtonForeground
        let radius = style?.cornerRadius ?? theme.spacing.saveButtonCornerRadius
        let font = style?.font ?? theme.fonts.saveButton

        Button(action: action) {
            HStack {
                Spacer()
                if isLoading {
                    ProgressView()
                        .tint(fgColor)
                } else {
                    Text(title)
                        .font(font)
                }
                Spacer()
            }
        }
        .disabled(isDisabled)
        .listRowBackground(
            RoundedRectangle(cornerRadius: radius)
                .fill(bgColor)
        )
        .foregroundStyle(fgColor)
    }
}

// MARK: - StickyBottomSaveButtonView

/// A save button pinned to the bottom of the screen, outside the scroll area.
/// Used with `FormSaveBehaviour.buttonStickyBottom`.
@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
struct StickyBottomSaveButtonView: View {
    let title: String
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    @Environment(\.formTheme) private var theme

    private var style: SaveButtonStyle? { theme.saveButtonStyle }

    var body: some View {
        let bgColor = isDisabled
            ? (style?.disabledBackgroundColor ?? theme.colors.saveButtonDisabledBackground)
            : (style?.backgroundColor ?? theme.colors.saveButtonBackground)
        let fgColor = style?.foregroundColor ?? theme.colors.saveButtonForeground
        let font = style?.font ?? theme.fonts.saveButton
        let vertPadding = theme.spacing.stickyButtonVerticalPadding

        VStack(spacing: 0) {
            Divider()
            Button(action: action) {
                HStack {
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .tint(fgColor)
                    } else {
                        Text(title)
                            .font(font)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, vertPadding)
            }
            .disabled(isDisabled)
            .background(bgColor)
            .foregroundStyle(fgColor)
        }
        .background(.background)
    }
}
