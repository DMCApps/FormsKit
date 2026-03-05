import FormKit
import SwiftUI

struct ContentView: View {
    // Hold these externally so we can read values after save.
    @State private var settingsViewModel = FormViewModel(formDefinition: SettingsForm.definition)
    @State private var debugViewModel = FormViewModel(formDefinition: DebugMenuForm.definition)

    var body: some View {
        List {
            Section("Examples") {
                NavigationLink("Settings Form") {
                    DynamicFormView(
                        formDefinition: SettingsForm.definition,
                        viewModel: settingsViewModel
                    )
                }

                NavigationLink("Debug Menu (with sub-forms)") {
                    DynamicFormView(
                        formDefinition: DebugMenuForm.definition,
                        viewModel: debugViewModel
                    )
                }
            }

            Section("Current Settings Values") {
                valueRow("Theme", settingsViewModel.value(for: "theme") ?? "—")
                valueRow("Display Name", settingsViewModel.value(for: "displayName") ?? "—")
                valueRow("Notifications", String(settingsViewModel.value(for: "notifications") ?? false))
                valueRow("Font Size", String(describing: settingsViewModel.value(for: "fontSize") as Int? ?? 0))
            }
        }
        .navigationTitle("FormKit Examples")
    }

    private func valueRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(.primary)
        }
        .font(.caption)
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
