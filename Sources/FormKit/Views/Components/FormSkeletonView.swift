import SwiftUI

// MARK: - FormSkeletonView

/// Renders shimmer placeholder shapes for each row in a `FormDefinition` while
/// the form's values are loading from persistence.
///
/// Each row type maps to a shape that approximates its real layout:
/// - Text / number inputs → title bar + text field rectangle
/// - Toggle → title bar + trailing toggle chip
/// - Picker (single/multi) → label + trailing value chip
/// - Button → full-width button bar
/// - Info → leading label + trailing value
/// - Navigation → title bar + trailing chevron placeholder
/// - Section → section header bar + skeleton children
///
/// The view is fully non-interactive.
@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
struct FormSkeletonView: View {
    let formDefinition: FormDefinition

    var body: some View {
        Form {
            ForEach(formDefinition.rows) { row in
                AnyView(skeletonRow(for: row))
            }
        }
        .disabled(true)
        .allowsHitTesting(false)
    }

    // MARK: - Row Dispatch

    // Returns AnyView to avoid the opaque-return-type-inference loop that arises
    // when a @ViewBuilder function calls itself recursively with `some View`.
    private func skeletonRow(for row: AnyFormRow) -> AnyView {
        if let section = row.asType(FormSection.self) {
            return AnyView(
                Section(header: SkeletonSectionHeader()) {
                    ForEach(section.rows) { child in
                        AnyView(skeletonRow(for: child))
                    }
                }
            )
        } else if row.asType(BooleanSwitchRow.self) != nil {
            return AnyView(SkeletonToggleRow())
        } else if row.asType(TextInputRow.self) != nil || row.asType(NumberInputRow.self) != nil {
            return AnyView(SkeletonTextInputRow())
        } else if row.asSingleValueRepresentable != nil || row.asMultiValueRepresentable != nil {
            return AnyView(SkeletonPickerRow())
        } else if row.asType(ButtonRow.self) != nil {
            return AnyView(SkeletonButtonRow())
        } else if row.asType(InfoRow.self) != nil {
            return AnyView(SkeletonInfoRow())
        } else if row.asType(NavigationRow.self) != nil {
            return AnyView(SkeletonNavigationRow())
        } else {
            // Generic fallback for any future row types.
            return AnyView(SkeletonTextInputRow())
        }
    }
}

// MARK: - Section Header

@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
private struct SkeletonSectionHeader: View {
    var body: some View {
        SkeletonShimmerView()
            .frame(width: 100, height: 10)
    }
}

// MARK: - Text / Number Input

@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
private struct SkeletonTextInputRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SkeletonShimmerView()
                .frame(width: 80, height: 12)
            SkeletonShimmerView()
                .frame(maxWidth: .infinity)
                .frame(height: 36)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Toggle / Boolean Switch

@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
private struct SkeletonToggleRow: View {
    var body: some View {
        HStack {
            SkeletonShimmerView()
                .frame(width: 120, height: 14)
            Spacer()
            SkeletonShimmerView()
                .frame(width: 50, height: 28)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Picker (Single / Multi)

@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
private struct SkeletonPickerRow: View {
    var body: some View {
        HStack {
            SkeletonShimmerView()
                .frame(width: 100, height: 14)
            Spacer()
            SkeletonShimmerView()
                .frame(width: 80, height: 14)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Button

@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
private struct SkeletonButtonRow: View {
    var body: some View {
        SkeletonShimmerView()
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .padding(.vertical, 4)
    }
}

// MARK: - Info

@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
private struct SkeletonInfoRow: View {
    var body: some View {
        HStack {
            SkeletonShimmerView()
                .frame(width: 100, height: 14)
            Spacer()
            SkeletonShimmerView()
                .frame(width: 60, height: 12)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Navigation

@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
private struct SkeletonNavigationRow: View {
    var body: some View {
        HStack {
            SkeletonShimmerView()
                .frame(width: 120, height: 14)
            Spacer()
            SkeletonShimmerView()
                .frame(width: 8, height: 14)
        }
        .padding(.vertical, 4)
    }
}
