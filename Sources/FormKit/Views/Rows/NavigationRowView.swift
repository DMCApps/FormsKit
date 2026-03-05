import SwiftUI

// MARK: - NavigationRowView

/// Renders a NavigationRow as a NavigationLink to a sub-form.
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
    }
}
