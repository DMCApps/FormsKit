import FormKit

// MARK: - ConditionsForm

/// Demonstrates FormCondition — show, hide, and compare rows based on values.
enum ConditionsForm {
    static let definition = FormDefinition(
        id: "conditions",
        title: "Conditions",
        saveBehaviour: .buttonNavigationBar()
    ) {
        // MARK: isTrue / isFalse

        FormSection(id: "boolSection", title: "isTrue / isFalse") {
            BooleanSwitchRow(
                id: "boolToggle",
                title: "Toggle me",
                subtitle: "Controls the two rows below",
                onChange: [
                    .showRow(id: "shownWhenTrue", when: [.isTrue(rowId: "boolToggle")]),
                    .showRow(id: "shownWhenFalse", when: [.isFalse(rowId: "boolToggle")])
                ]
            )

            TextInputRow(
                id: "shownWhenTrue",
                title: "Shown when toggle is ON",
                subtitle: "Condition: .isTrue(rowId:)",
                placeholder: "Visible only when toggled on"
            )

            TextInputRow(
                id: "shownWhenFalse",
                title: "Shown when toggle is OFF",
                subtitle: "Condition: .isFalse(rowId:)",
                placeholder: "Visible only when toggled off"
            )
        }

        // MARK: equals / notEquals

        FormSection(id: "equalsSection", title: "equals / notEquals") {
            SingleValueRow<StatusOption>(
                id: "statusPicker",
                title: "Status",
                subtitle: "Pick a status to see conditions react",
                defaultValue: .active,
                onChange: [
                    .showRow(id: "activeNote", when: [.equals(rowId: "statusPicker", string: "Active")]),
                    .showRow(id: "inactiveNote", when: [.notEquals(rowId: "statusPicker", string: "Active")])
                ]
            )

            InfoRow(id: "equalsHint", title: "equals") {
                "Row below appears only when status == Active"
            }

            TextInputRow(
                id: "activeNote",
                title: "Active-only note",
                subtitle: "Hidden unless status == Active",
                placeholder: "This account is active"
            )

            InfoRow(id: "notEqualsHint", title: "notEquals") {
                "Row below appears for any status except Active"
            }

            TextInputRow(
                id: "inactiveNote",
                title: "Non-active note",
                subtitle: "Hidden when status == Active",
                placeholder: "Account is not active"
            )
        }

        // MARK: isEmpty / isNotEmpty

        FormSection(id: "emptySection", title: "isEmpty / isNotEmpty") {
            TextInputRow(
                id: "sourceField",
                title: "Source field",
                subtitle: "Type something to see the rows below react",
                placeholder: "Type here…",
                onChange: [
                    .showRow(id: "emptyPlaceholder", when: [.isEmpty(rowId: "sourceField")]),
                    .showRow(id: "notEmptyPlaceholder", when: [.isNotEmpty(rowId: "sourceField")])
                ]
            )

            InfoRow(id: "emptyPlaceholder", title: "isEmpty is true") {
                "← Start typing to hide this"
            }

            InfoRow(id: "notEmptyPlaceholder", title: "isNotEmpty is true") {
                "← Clear the field to hide this"
            }
        }

        // MARK: contains (multi-value)

        FormSection(id: "containsSection", title: "contains (MultiValueRow)") {
            MultiValueRow<FruitOption>(
                id: "fruitPicker",
                title: "Pick fruits",
                subtitle: "Select Banana to reveal the note below",
                onChange: [
                    .showRow(id: "bananaNote", when: [.contains(rowId: "fruitPicker", value: .string("Banana"))])
                ]
            )

            TextInputRow(
                id: "bananaNote",
                title: "Banana note",
                subtitle: "Visible only when Banana is selected",
                placeholder: "Bananas are great!"
            )
        }

        // MARK: Numeric comparisons

        FormSection(id: "numericSection", title: "Numeric Comparisons") {
            NumberInputRow(
                id: "ageField",
                title: "Age",
                subtitle: "Controls rows below via greaterThanOrEqual / lessThan",
                placeholder: "e.g. 18",
                kind: .int(defaultValue: nil),
                onChange: [
                    .showRow(id: "adultRow", when: [.greaterThanOrEqual(rowId: "ageField", value: .int(18))]),
                    .showRow(id: "minorRow", when: [.lessThan(rowId: "ageField", value: .int(18))])
                ]
            )

            TextInputRow(
                id: "adultRow",
                title: "Adult content (18+)",
                subtitle: "Shown when age ≥ 18",
                placeholder: "You're old enough"
            )

            TextInputRow(
                id: "minorRow",
                title: "Under 18 notice",
                subtitle: "Shown when age < 18",
                placeholder: "Guardian consent required"
            )
        }

        // MARK: Logical combinators

        FormSection(id: "combinatorsSection", title: "and / or / not") {
            BooleanSwitchRow(
                id: "condA",
                title: "Condition A",
                onChange: [
                    .showRow(id: "andRow", when: [.and([.isTrue(rowId: "condA"), .isTrue(rowId: "condB")])]),
                    .showRow(id: "orRow", when: [.or([.isTrue(rowId: "condA"), .isTrue(rowId: "condB")])]),
                    .showRow(id: "notRow", when: [.not(.isTrue(rowId: "condA"))])
                ]
            )

            BooleanSwitchRow(
                id: "condB",
                title: "Condition B",
                onChange: [
                    .showRow(id: "andRow", when: [.and([.isTrue(rowId: "condA"), .isTrue(rowId: "condB")])]),
                    .showRow(id: "orRow", when: [.or([.isTrue(rowId: "condA"), .isTrue(rowId: "condB")])])
                ]
            )

            InfoRow(id: "andRow", title: "A AND B are both ON") { "Both toggles are on" }

            InfoRow(id: "orRow", title: "A OR B is ON") { "At least one toggle is on" }

            InfoRow(id: "notRow", title: "NOT A (A is OFF)") { "Condition A is off" }
        }
    }
}

// MARK: - Support types

private enum StatusOption: String, CaseIterable, CustomStringConvertible, Hashable, Sendable, Codable {
    case active, inactive, pending
    var description: String { rawValue.capitalized }
}

private enum FruitOption: String, CaseIterable, CustomStringConvertible, Hashable, Sendable, Codable {
    case apple, banana, cherry, mango
    var description: String { rawValue.capitalized }
}
