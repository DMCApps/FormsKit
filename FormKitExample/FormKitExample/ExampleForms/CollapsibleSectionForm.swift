import FormsKit

// MARK: - CollapsibleSectionForm

/// Demonstrates the `CollapsibleSection` row type.
///
/// Shows:
/// - A section that starts expanded (default behaviour)
/// - A section that starts collapsed
/// - A collapsible section made conditionally visible via a toggle
enum CollapsibleSectionForm {
    static let definition = FormDefinition(
        id: "collapsibleSections",
        title: "Collapsible Sections",
        saveBehaviour: .buttonNavigationBar()
    ) {
        // MARK: Expanded by default

        CollapsibleSection(id: "expandedByDefault", title: "Expanded by Default") {
            TextInputRow(id: "field1", title: "Field 1", placeholder: "Inside expanded section")
            BooleanSwitchRow(id: "toggle1", title: "Toggle 1")
        }

        // MARK: Collapsed by default

        CollapsibleSection(
            id: "collapsedByDefault",
            title: "Collapsed by Default",
            isExpandedByDefault: false
        ) {
            TextInputRow(id: "field2", title: "Field 2", placeholder: "Inside collapsed section")
            NumberInputRow(id: "number1", title: "Number", kind: .int(defaultValue: nil))
        }

        // MARK: Conditionally visible collapsible section

        BooleanSwitchRow(
            id: "showAdvanced",
            title: "Show Advanced Section",
            defaultValue: false,
            onChange: [
                .showRow(id: "advancedCollapsible", when: [.isTrue(rowId: "showAdvanced")])
            ]
        )

        CollapsibleSection(id: "advancedCollapsible", title: "Advanced (Conditional)") {
            TextInputRow(
                id: "advField",
                title: "Advanced Field",
                placeholder: "Only visible when toggle is ON"
            )
            BooleanSwitchRow(id: "advToggle", title: "Advanced Toggle")
        }
    }
}
