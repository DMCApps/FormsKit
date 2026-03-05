@testable import FormKit
import Testing

// MARK: - ActionTiming Tests

@Suite("ActionTiming")
struct ActionTimingTests {
    @Test(".immediate has nil debounce")
    func immediateHasNilDebounce() {
        #expect(ActionTiming.immediate.debounce == nil)
    }

    @Test(".debounced stores the delay")
    func debouncedStoresDelay() {
        let timing = ActionTiming.debounced(0.5)
        #expect(timing.debounce == 0.5)
    }

    @Test(".debounced stores a custom delay value")
    func debouncedStoresCustomDelay() {
        let timing = ActionTiming.debounced(1.5)
        #expect(timing.debounce == 1.5)
    }
}

// MARK: - FormRowAction Tests

@Suite("FormRowAction")
struct FormRowActionTests {
    // MARK: - isOnChangeAction

    @Test(".showRow is an onChange action")
    func showRowIsOnChangeAction() {
        let action = FormRowAction.showRow(id: "target")
        #expect(action.isOnChangeAction == true)
    }

    @Test(".setValue is an onChange action")
    func setValueIsOnChangeAction() {
        let action = FormRowAction.setValue(on: "target") { _ in nil }
        #expect(action.isOnChangeAction == true)
    }

    @Test(".runValidation is an onChange action")
    func runValidationIsOnChangeAction() {
        let action = FormRowAction.runValidation()
        #expect(action.isOnChangeAction == true)
    }

    @Test(".custom is an onChange action")
    func customIsOnChangeAction() {
        let action = FormRowAction.custom { _, _ in }
        #expect(action.isOnChangeAction == true)
    }

    @Test(".onSave is NOT an onChange action")
    func onSaveIsNotOnChangeAction() {
        let action = FormRowAction.onSave { _ in }
        #expect(action.isOnChangeAction == false)
    }

    // MARK: - timing

    @Test(".showRow returns its timing")
    func showRowReturnsTiming() {
        let immediate = FormRowAction.showRow(id: "t", timing: .immediate)
        let debounced = FormRowAction.showRow(id: "t", timing: .debounced(0.3))
        #expect(immediate.timing?.debounce == nil)
        #expect(debounced.timing?.debounce == 0.3)
    }

    @Test(".setValue returns its timing")
    func setValueReturnsTiming() {
        let action = FormRowAction.setValue(on: "t", timing: .debounced(0.2)) { _ in nil }
        #expect(action.timing?.debounce == 0.2)
    }

    @Test(".runValidation returns its timing")
    func runValidationReturnsTiming() {
        let action = FormRowAction.runValidation(timing: .debounced(0.1))
        #expect(action.timing?.debounce == 0.1)
    }

    @Test(".custom returns its timing")
    func customReturnsTiming() {
        let action = FormRowAction.custom(timing: .immediate) { _, _ in }
        #expect(action.timing?.debounce == nil)
    }

    @Test(".onSave returns nil timing")
    func onSaveReturnsNilTiming() {
        let action = FormRowAction.onSave { _ in }
        #expect(action.timing == nil)
    }

    // MARK: - Row type storage

    @Test("TextInputRow stores actions")
    func textInputRowStoresActions() {
        nonisolated(unsafe) var callCount = 0
        let row = TextInputRow(
            id: "lat",
            title: "Latitude",
            onChange: [
                .custom { _, _ in callCount += 1 },
                .runValidation(timing: .debounced(0.5))
            ]
        )
        #expect(row.onChange.count == 2)
        #expect(row.onChange[0].isOnChangeAction == true)
        #expect(row.onChange[1].timing?.debounce == 0.5)
    }

    @Test("BooleanSwitchRow stores showRow actions")
    func booleanSwitchRowStoresShowRowActions() {
        let row = BooleanSwitchRow(
            id: "toggle",
            title: "Toggle",
            onChange: [
                .showRow(id: "other", when: [.isTrue(rowId: "toggle")])
            ]
        )
        #expect(row.onChange.count == 1)
        guard case let .showRow(targetId, conditions, timing) = row.onChange[0] else {
            Issue.record("Expected .showRow action")
            return
        }
        #expect(targetId == "other")
        #expect(conditions.count == 1)
        #expect(timing.debounce == nil)
    }

    @Test("SingleValueRow stores setValue actions")
    func singleValueRowStoresSetValueActions() {
        nonisolated(unsafe) var wasCalled = false
        let row = SingleValueRow<MockActionOption>(
            id: "pick",
            title: "Pick",
            onChange: [
                .setValue(on: "target") { _ in
                    wasCalled = true
                    return .string("filled")
                }
            ]
        )
        #expect(row.onChange.count == 1)

        // Verify closure can be invoked
        var store = FormValueStore()
        store["pick"] = .string("a")
        if case let .setValue(targetId, _, valueFactory) = row.onChange[0] {
            let result = valueFactory(store)
            #expect(targetId == "target")
            #expect(result == .string("filled"))
            #expect(wasCalled)
        } else {
            Issue.record("Expected .setValue action")
        }
    }

    @Test("Row with no actions defaults to empty array")
    func rowDefaultsToEmptyActions() {
        let row = TextInputRow(id: "text", title: "Text")
        #expect(row.onChange.isEmpty)
    }

    // MARK: - AnyFormRow propagation

    @Test("AnyFormRow carries actions from wrapped row")
    func anyFormRowCarriesActions() {
        nonisolated(unsafe) var callCount = 0
        let row = TextInputRow(
            id: "t",
            title: "T",
            onChange: [
                .custom { _, _ in callCount += 1 },
                .showRow(id: "other")
            ]
        )
        let anyRow = AnyFormRow(row)
        #expect(anyRow.onChange.count == 2)
    }

    @Test("AnyFormRow with no actions has empty array")
    func anyFormRowNoActionsIsEmpty() {
        let row = BooleanSwitchRow(id: "b", title: "B")
        let anyRow = AnyFormRow(row)
        #expect(anyRow.onChange.isEmpty)
    }

    // MARK: - RawRepresentable overloads

    @Test("FormRowAction.showRow RawRepresentable overload sets correct targetId")
    func showRowRawRepresentableOverload() {
        let action = FormRowAction.showRow(id: MockActionRowID.target)
        guard case let .showRow(id, _, _) = action else {
            Issue.record("Expected .showRow")
            return
        }
        #expect(id == MockActionRowID.target.rawValue)
    }

    @Test("FormRowAction.setValue RawRepresentable overload sets correct targetId")
    func setValueRawRepresentableOverload() {
        let action = FormRowAction.setValue(on: MockActionRowID.target) { _ in nil }
        guard case let .setValue(id, _, _) = action else {
            Issue.record("Expected .setValue")
            return
        }
        #expect(id == MockActionRowID.target.rawValue)
    }

    @Test("TextInputRow RawRepresentable overload stores actions")
    func textInputRowRawRepresentableActions() {
        nonisolated(unsafe) var called = false
        let row = TextInputRow(
            id: MockActionRowID.field,
            title: "Field",
            onChange: [.custom { _, _ in called = true }]
        )
        #expect(row.id == MockActionRowID.field.rawValue)
        #expect(row.onChange.count == 1)
    }
}

// MARK: - FormKeyboardType Tests

@Suite("FormKeyboardType")
struct FormKeyboardTypeTests {
    @Test("TextInputRow defaults to .default keyboard type")
    func defaultKeyboardType() {
        let row = TextInputRow(id: "t", title: "T")
        if case .default = row.keyboardType {
            // correct
        } else {
            Issue.record("Expected .default keyboard type")
        }
    }

    @Test("TextInputRow stores specified keyboard type")
    func specifiedKeyboardType() {
        let row = TextInputRow(id: "lat", title: "Lat", keyboardType: .decimalPad)
        if case .decimalPad = row.keyboardType {
            // correct
        } else {
            Issue.record("Expected .decimalPad keyboard type")
        }
    }

    @Test("All FormKeyboardType cases can be assigned and compared")
    func allCasesAssignable() {
        let cases: [FormKeyboardType] = [.default, .decimalPad, .numberPad, .emailAddress, .url, .phonePad]
        for keyboardType in cases {
            let row = TextInputRow(id: "t", title: "T", keyboardType: keyboardType)
            let concreteRow = AnyFormRow(row).asType(TextInputRow.self)
            #expect(concreteRow != nil)
        }
    }
}

// MARK: - Test Helpers

private enum MockActionOption: String, CaseIterable, CustomStringConvertible, Hashable, Sendable, Codable {
    case a, b, c
    var description: String { rawValue }
}

private enum MockActionRowID: String {
    case field
    case target
}
