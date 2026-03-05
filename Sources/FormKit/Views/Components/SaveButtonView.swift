import SwiftUI

// MARK: - SaveButtonView

/// A prominent save button with an optional loading indicator.
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
