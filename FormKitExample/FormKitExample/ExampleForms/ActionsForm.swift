import FormKit

// MARK: - ActionsForm

/// Demonstrates every FormRowAction case and ActionTiming.
enum ActionsForm {
    static let definition = FormDefinition(
        id: "actions",
        title: "Row Actions",
        saveBehaviour: .buttonNavigationBar()
    ) {
        // MARK: showRow / hideRow

        FormSection(id: "showHideSection", title: "showRow / hideRow") {
            BooleanSwitchRow(
                id: "showHideToggle",
                title: "Toggle visibility",
                subtitle: "Controls the two rows below",
                onChange: [
                    .showRow(id: "showTarget", when: [.isTrue(rowId: "showHideToggle")]),
                    .hideRow(id: "hideTarget", when: [.isTrue(rowId: "showHideToggle")])
                ]
            )

            TextInputRow(
                id: "showTarget",
                title: ".showRow — appears when ON",
                placeholder: "I appear when the toggle is on"
            )

            TextInputRow(
                id: "hideTarget",
                title: ".hideRow — disappears when ON",
                placeholder: "I disappear when the toggle is on"
            )
        }

        // MARK: disableRow

        FormSection(id: "disableSection", title: "disableRow") {
            BooleanSwitchRow(
                id: "disableToggle",
                title: "Disable the field below",
                onChange: [
                    .disableRow(id: "disableTarget", when: [.isTrue(rowId: "disableToggle")])
                ]
            )

            TextInputRow(
                id: "disableTarget",
                title: ".disableRow — disabled when toggle is ON",
                subtitle: "Row is visible but cannot be interacted with",
                placeholder: "Try toggling the switch above"
            )
        }

        // MARK: clearValue

        FormSection(id: "clearSection", title: "clearValue") {
            BooleanSwitchRow(
                id: "clearToggle",
                title: "Clear the field below when toggled off",
                onChange: [
                    .clearValue(id: "clearTarget", when: [.isFalse(rowId: "clearToggle")])
                ]
            )

            TextInputRow(
                id: "clearTarget",
                title: ".clearValue — cleared when toggle is OFF",
                subtitle: "Type something, then turn the toggle off",
                placeholder: "Type something here"
            )
        }

        // MARK: setValue

        FormSection(id: "setValueSection", title: "setValue") {
            SingleValueRow<TemplateOption>(
                id: "templatePicker",
                title: "Message template",
                subtitle: "Selecting a template fills the field below",
                onChange: [
                    .setValue(on: "messageField") { store in
                        guard case let .string(raw) = store["templatePicker"],
                              let option = TemplateOption(rawValue: raw.lowercased()) else { return nil }
                        return .string(option.message)
                    }
                ]
            )

            TextInputRow(
                id: "messageField",
                title: ".setValue — auto-filled by template",
                subtitle: "Value is set programmatically from the picker above",
                placeholder: "Pick a template to fill this"
            )
        }

        // MARK: runValidation

        FormSection(id: "runValidationSection", title: "runValidation") {
            TextInputRow(
                id: "liveEmailField",
                title: "Email with live validation",
                subtitle: ".runValidation() fires validators on every change",
                placeholder: "you@example.com",
                keyboardType: .emailAddress,
                validators: [.email(trigger: .onChange)],
                onChange: [.runValidation()]
            )
        }

        // MARK: ActionTiming — debounced

        FormSection(id: "timingSection", title: "ActionTiming.debounced") {
            TextInputRow(
                id: "debouncedSource",
                title: "Source (debounced 1 s)",
                subtitle: "The action below fires 1 s after you stop typing",
                placeholder: "Type something…",
                onChange: [
                    .setValue(on: "debouncedTarget", timing: .debounced(1.0)) { store in
                        guard case let .string(text) = store["debouncedSource"] else { return nil }
                        return .string(text.uppercased())
                    }
                ]
            )

            TextInputRow(
                id: "debouncedTarget",
                title: "Target (uppercased after delay)",
                subtitle: "Updated ~1 s after the source stops changing",
                placeholder: "Appears here uppercased"
            )
        }

        // MARK: custom

        FormSection(id: "customSection", title: "custom") {
            TextInputRow(
                id: "customActionField",
                title: "Custom action",
                subtitle: "Fires a print() whenever this field changes",
                placeholder: "Type to trigger custom action",
                onChange: [
                    .custom { store, rowId in
                        // In a real app this could update external state, log analytics, etc.
                        let value = store[rowId]
                        print("[ActionsForm] custom action fired — rowId: \(rowId), value: \(String(describing: value))")
                    }
                ]
            )
        }
    }
}

// MARK: - Support types

private enum TemplateOption: String, CaseIterable, CustomStringConvertible, Hashable, Sendable, Codable {
    case greeting, reminder, farewell

    var description: String { rawValue.capitalized }

    var message: String {
        switch self {
        case .greeting: return "Hello! Thanks for getting in touch."
        case .reminder: return "Just a friendly reminder about your upcoming appointment."
        case .farewell: return "Thanks for your time. Have a great day!"
        }
    }
}
