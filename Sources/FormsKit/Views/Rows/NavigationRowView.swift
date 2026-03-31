import SwiftUI

// MARK: - NavigationRowView

/// Renders a NavigationRow as a NavigationLink to a sub-form.
@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
struct NavigationRowView: View {
    let row: NavigationRow
    @Bindable var viewModel: FormViewModel

    var body: some View {
        NavigationLink {
            DynamicFormView(formDefinition: row.destination)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                if let subtitle = row.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityIdentifier("formkit.navrow.\(row.id)")
    }
}
