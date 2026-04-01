import SwiftUI

// MARK: - CollapsibleSectionView

/// Renders a `CollapsibleSection` as a SwiftUI `Section` with a tappable header
/// containing a disclosure arrow that animates between expanded and collapsed states.
///
/// When collapsed, only the header is visible. When expanded, child rows are
/// dispatched through `FormRowContainer` — the same dispatcher used by the top-level form.
@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
struct CollapsibleSectionView: View {
    let section: CollapsibleSection
    @Bindable var viewModel: FormViewModel
    @Environment(\.formTheme) private var theme

    private var style: CollapsibleSectionStyle? { section.rowStyle as? CollapsibleSectionStyle }

    private var isExpanded: Bool {
        viewModel.isSectionExpanded(section.id)
    }

    var body: some View {
        let titleColor = style?.titleColor ?? theme.colors.sectionHeader
        let titleFont = style?.titleFont ?? theme.fonts.sectionHeader
        let disclosureIcon = style?.disclosureIcon ?? theme.icons.collapsibleDisclosure
        let animationDuration = style?.animationDuration ?? theme.animations.collapsibleDuration

        Section {
            if isExpanded {
                ForEach(section.rows) { row in
                    if viewModel.isRowVisible(row) {
                        FormRowContainer(row: row, viewModel: viewModel)
                            .animation(.default, value: viewModel.isRowVisible(row))
                    }
                }
            }
        } header: {
            Button {
                withAnimation(.easeInOut(duration: animationDuration)) {
                    viewModel.toggleSection(section.id)
                }
            } label: {
                HStack {
                    Text(section.title)
                        .font(titleFont)
                        .foregroundStyle(titleColor)
                    Spacer()
                    Image(systemName: disclosureIcon)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: animationDuration), value: isExpanded)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("formkit.collapsible.\(section.id)")
            .accessibilityAddTraits(.isButton)
            .accessibilityValue(isExpanded ? "expanded" : "collapsed")
        }
    }
}
