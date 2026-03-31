import FormsKit
import SwiftUI

// MARK: - Catalogue Entry

struct CatalogueEntry: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let destination: FormDefinition
}

// MARK: - ContentView

struct ContentView: View {
    private let entries: [CatalogueEntry] = [
        CatalogueEntry(
            id: "rowTypes",
            title: "Row Types",
            subtitle: "Text, Number, Boolean, Picker, Button, Info, Section, Navigation, Collapsible",
            destination: RowTypesForm.definition
        ),
        CatalogueEntry(
            id: "collapsibleSections",
            title: "Collapsible Sections",
            subtitle: "Expandable/collapsible section containers with animated arrows",
            destination: CollapsibleSectionForm.definition
        ),
        CatalogueEntry(
            id: "validation",
            title: "Validation",
            subtitle: "Built-in validators and validation triggers",
            destination: ValidationForm.definition
        ),
        CatalogueEntry(
            id: "conditions",
            title: "Conditions",
            subtitle: "Show, hide, and compare rows based on values",
            destination: ConditionsForm.definition
        ),
        CatalogueEntry(
            id: "actions",
            title: "Row Actions",
            subtitle: "Show/hide, disable, clear, set value, custom",
            destination: ActionsForm.definition
        ),
        CatalogueEntry(
            id: "saveBehaviour",
            title: "Save Behaviour",
            subtitle: "Navigation bar, bottom button, sticky, auto-save",
            destination: SaveBehaviourForm.definition
        ),
        CatalogueEntry(
            id: "errorPositions",
            title: "Error Positions",
            subtitle: "Below row, form top, form bottom, alert",
            destination: ErrorPositionsForm.definition
        ),
        CatalogueEntry(
            id: "inputMasks",
            title: "Input Masks",
            subtitle: "Phone, date, and custom pattern masks",
            destination: InputMasksForm.definition
        ),
        CatalogueEntry(
            id: "persistence",
            title: "Persistence",
            subtitle: "Memory, UserDefaults, and file-based storage",
            destination: PersistenceForm.definition
        ),
        CatalogueEntry(
            id: "settings",
            title: "Settings Form",
            subtitle: "Full example with UserDefaults persistence",
            destination: SettingsForm.definition
        ),
        CatalogueEntry(
            id: "debugMenu",
            title: "Debug Menu",
            subtitle: "Sub-form navigation and file-based persistence",
            destination: DebugMenuForm.definition
        )
    ]

    var body: some View {
        List(entries) { entry in
            NavigationLink {
                DynamicFormView(formDefinition: entry.destination)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title)
                        .font(.body)
                    Text(entry.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .navigationTitle("FormKit")
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
