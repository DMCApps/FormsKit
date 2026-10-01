@testable import FormsKit
import Testing

// MARK: - Unknown Referenced Row ID Detection

/// A condition, action or validator that points at a row ID which doesn't exist in the
/// form silently does nothing at runtime. `FormViewModel.unknownReferencedRowIDs(in:)` is
/// the pure check that finds these — `FormViewModel.init` wires it to an
/// `assertionFailure`, which is trivial glue not covered here.
@Suite("FormViewModel Unknown Referenced Row ID Detection")
struct FormViewModelUnknownRowIDTests {
    private func unknownIDs(_ rows: [AnyFormRow]) -> [String] {
        FormViewModel.unknownReferencedRowIDs(in: FormViewModel.allRows(in: rows))
    }

    @Test("Valid references across actions, conditions and validators report nothing")
    func validReferencesReportNothing() {
        let rows: [AnyFormRow] = [
            AnyFormRow(BooleanSwitchRow(id: "toggle", title: "Toggle", onChange: [
                .showRow(id: "name", when: [.isTrue(rowId: "toggle")]),
                .clearValue(id: "confirm", when: [.and([.isFalse(rowId: "toggle"), .not(.isEmpty(rowId: "name"))])]),
                .setValue(on: "name") { _ in nil },
            ])),
            AnyFormRow(FormSection(id: "sec", title: "Section") {
                TextInputRow(id: "name", title: "Name")
                TextInputRow(id: "confirm", title: "Confirm",
                             validators: [.matches(rowId: "name", errorPosition: .belowRow(id: "name"))])
            }),
        ]
        #expect(unknownIDs(rows).isEmpty)
    }

    @Test("Unknown action target is detected")
    func unknownActionTarget() {
        let rows: [AnyFormRow] = [
            AnyFormRow(BooleanSwitchRow(id: "toggle", title: "Toggle", onChange: [
                .hideRow(id: "missing"),
            ])),
        ]
        #expect(unknownIDs(rows) == ["missing"])
    }

    @Test("Unknown setValue target is detected")
    func unknownSetValueTarget() {
        let rows: [AnyFormRow] = [
            AnyFormRow(TextInputRow(id: "name", title: "Name", onChange: [
                .setValue(on: "missing") { _ in nil },
            ])),
        ]
        #expect(unknownIDs(rows) == ["missing"])
    }

    @Test("Unknown row ID nested inside composed conditions is detected")
    func unknownNestedConditionRowID() {
        let rows: [AnyFormRow] = [
            AnyFormRow(BooleanSwitchRow(id: "toggle", title: "Toggle", onChange: [
                .showRow(id: "toggle", when: [.or([.isTrue(rowId: "toggle"), .not(.equals(rowId: "typo", value: .int(1)))])]),
            ])),
        ]
        #expect(unknownIDs(rows) == ["typo"])
    }

    @Test("Unknown .matches row ID is detected")
    func unknownMatchesRowID() {
        let rows: [AnyFormRow] = [
            AnyFormRow(TextInputRow(id: "confirm", title: "Confirm", validators: [.matches(rowId: "password")])),
        ]
        #expect(unknownIDs(rows) == ["password"])
    }

    @Test("Unknown .belowRow(id:) error position is detected")
    func unknownErrorPositionRowID() {
        let rows: [AnyFormRow] = [
            AnyFormRow(TextInputRow(id: "name", title: "Name",
                                    validators: [.required(errorPosition: .belowRow(id: "elsewhere"))])),
        ]
        #expect(unknownIDs(rows) == ["elsewhere"])
    }

    @Test("Multiple unknown IDs are reported once each, sorted")
    func multipleUnknownIDsSortedAndDeduplicated() {
        let rows: [AnyFormRow] = [
            AnyFormRow(BooleanSwitchRow(id: "toggle", title: "Toggle", onChange: [
                .showRow(id: "b", when: [.isTrue(rowId: "a")]),
                .hideRow(id: "b"),
            ])),
        ]
        #expect(unknownIDs(rows) == ["a", "b"])
    }

    @Test("Opaque .custom conditions and actions are not checked")
    func customReferencesIgnored() {
        let rows: [AnyFormRow] = [
            AnyFormRow(BooleanSwitchRow(id: "toggle", title: "Toggle", onChange: [
                .showRow(id: "toggle", when: [.custom { $0["anything"] != nil }]),
                .custom { _, _ in },
            ])),
        ]
        #expect(unknownIDs(rows).isEmpty)
    }
}
