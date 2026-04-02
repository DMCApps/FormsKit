import SwiftUI

/// Renders a `FormSection` as a SwiftUI `Section` with a title header,
/// dispatching each visible child row through `FormRowContainer`.
struct FormSectionView: View {
    let section: FormSection
    @Bindable var viewModel: FormViewModel
    @Environment(\.formTheme) private var theme

    var body: some View {
        Section {
            ForEach(section.rows) { row in
                if viewModel.isRowVisible(row) {
                    FormRowContainer(row: row, viewModel: viewModel)
                        .animation(.default, value: viewModel.isRowVisible(row))
                }
            }
        } header: {
            Text(section.title)
                .font(theme.fonts.sectionHeader)
                .foregroundStyle(theme.colors.sectionHeader)
        }
    }
}
