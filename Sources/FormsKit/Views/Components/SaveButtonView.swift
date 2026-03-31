import SwiftUI

// MARK: - SaveButtonView

/// A prominent save button rendered inside a Form list row, with an optional loading indicator.
struct SaveButtonView: View {
    let title: String
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .fontWeight(.semibold)
                }
                Spacer()
            }
        }
        .disabled(isDisabled)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 10)
                .fill(isDisabled ? Color.secondary : Color.accentColor)
        )
        .foregroundStyle(.white)
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

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: action) {
                HStack {
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(title)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .disabled(isDisabled)
            .background(isDisabled ? Color.secondary : Color.accentColor)
            .foregroundStyle(.white)
        }
        .background(.background)
    }
}
