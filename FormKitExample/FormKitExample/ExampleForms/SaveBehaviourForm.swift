import FormKit

// MARK: - SaveBehaviourForm

/// Demonstrates every FormSaveBehaviour option via NavigationRow sub-forms.
enum SaveBehaviourForm {
    static let definition = FormDefinition(
        id: "saveBehaviour",
        title: "Save Behaviour",
        saveBehaviour: .none
    ) {
        FormSection(id: "saveBehaviourSection", title: "Tap a row to see each save style") {
            NavigationRow(
                id: "navBarButton",
                title: ".buttonNavigationBar()",
                subtitle: "Save button appears in the navigation bar",
                destination: FormDefinition(
                    id: "saveBehaviour.navBar",
                    title: "Nav Bar Button",
                    saveBehaviour: .buttonNavigationBar(title: "Save")
                ) {
                    InfoRow(id: "hint", title: "Save location") { "Top-right navigation bar" }
                    TextInputRow(id: "field1", title: "Name", placeholder: "Enter your name")
                    TextInputRow(id: "field2", title: "Notes", placeholder: "Optional notes")
                }
            )

            NavigationRow(
                id: "bottomFormButton",
                title: ".buttonBottomForm()",
                subtitle: "Save button is inside the scroll area at the bottom",
                destination: FormDefinition(
                    id: "saveBehaviour.bottomForm",
                    title: "Bottom Form Button",
                    saveBehaviour: .buttonBottomForm(title: "Save")
                ) {
                    InfoRow(id: "hint", title: "Save location") { "Below the last row (scrollable)" }
                    TextInputRow(id: "field1", title: "Name", placeholder: "Enter your name")
                    TextInputRow(id: "field2", title: "Notes", placeholder: "Optional notes")
                }
            )

            NavigationRow(
                id: "stickyBottomButton",
                title: ".buttonStickyBottom()",
                subtitle: "Save button is pinned outside the scroll area",
                destination: FormDefinition(
                    id: "saveBehaviour.stickyBottom",
                    title: "Sticky Bottom Button",
                    saveBehaviour: .buttonStickyBottom(title: "Save")
                ) {
                    InfoRow(id: "hint", title: "Save location") { "Pinned to bottom of screen" }
                    TextInputRow(id: "field1", title: "Name", placeholder: "Enter your name")
                    TextInputRow(id: "field2", title: "Notes", placeholder: "Optional notes")
                }
            )

            NavigationRow(
                id: "autoSave",
                title: ".onChange (auto-save)",
                subtitle: "Values are saved automatically after every change",
                destination: FormDefinition(
                    id: "saveBehaviour.onChange",
                    title: "Auto-save",
                    saveBehaviour: .onChange
                ) {
                    InfoRow(id: "hint", title: "Save trigger") { "Every value change" }
                    BooleanSwitchRow(id: "toggle", title: "A toggle (auto-saved)")
                    TextInputRow(id: "field", title: "A text field (auto-saved)", placeholder: "Type something…")
                }
            )

            NavigationRow(
                id: "noSave",
                title: ".none",
                subtitle: "No save button and no automatic saving",
                destination: FormDefinition(
                    id: "saveBehaviour.none",
                    title: "No Save",
                    saveBehaviour: .none
                ) {
                    InfoRow(id: "hint", title: "Save behaviour") { "None — buttons only" }
                    ButtonRow(id: "action1", title: "Action Button 1", subtitle: "Fires a custom action") {
                        print("[SaveBehaviourForm] Action 1 tapped")
                    }
                    ButtonRow(id: "action2", title: "Action Button 2", subtitle: "Fires another custom action") {
                        print("[SaveBehaviourForm] Action 2 tapped")
                    }
                }
            )
        }

        // MARK: Custom button titles

        FormSection(id: "customTitleSection", title: "Custom button titles") {
            NavigationRow(
                id: "customTitle",
                title: "Custom title: \"Apply\"",
                subtitle: "buttonNavigationBar(title: \"Apply\")",
                destination: FormDefinition(
                    id: "saveBehaviour.customTitle",
                    title: "Custom Title",
                    saveBehaviour: .buttonNavigationBar(title: "Apply")
                ) {
                    TextInputRow(id: "field", title: "Some field", placeholder: "Change this and tap Apply")
                }
            )
        }
    }
}
