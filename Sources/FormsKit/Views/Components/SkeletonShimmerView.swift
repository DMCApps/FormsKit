import SwiftUI

// MARK: - SkeletonShimmerView

/// A shimmering rectangle that animates between two grey tones, matching the
/// app's `SUISkeletonBaseView` appearance. Used as the building block for
/// row-level skeleton placeholders in `FormSkeletonView`.
///
/// Colours are taken from the same defaults as `SkeletonViewAppearance`:
/// - dark:  RGB(30, 30, 30) @ 40 % opacity
/// - light: RGB(64, 64, 64) @ 40 % opacity
@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
struct SkeletonShimmerView: View {
    @State private var isLight = false
    @Environment(\.formTheme) private var theme

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(isLight ? theme.colors.skeletonLight : theme.colors.skeletonDark)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: theme.animations.skeletonDuration).repeatForever(autoreverses: true)
                ) {
                    isLight.toggle()
                }
            }
    }
}
