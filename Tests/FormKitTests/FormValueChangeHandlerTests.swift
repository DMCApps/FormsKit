@testable import FormKit
import Testing

// MARK: - FormValueChangeHandler Tests

@Suite("FormValueChangeHandler")
struct FormValueChangeHandlerTests {
    // MARK: - Init

    @Test("init with nil debounce creates immediate handler")
    func initNilDebounceIsImmediate() {
        let handler = FormValueChangeHandler(debounce: nil) { _ in }
        #expect(handler.debounce == nil)
    }

    @Test("init with debounce stores delay")
    func initDebounceStoresDelay() {
        let handler = FormValueChangeHandler(debounce: 0.5) { _ in }
        #expect(handler.debounce == 0.5)
    }

    // MARK: - Factory methods

    @Test(".immediate creates handler with nil debounce")
    func immediateFactoryHasNilDebounce() {
        let handler = FormValueChangeHandler.immediate { _ in }
        #expect(handler.debounce == nil)
    }

    @Test(".debounced creates handler with specified delay")
    func debouncedFactoryStoresDelay() {
        let handler = FormValueChangeHandler.debounced(1.0) { _ in }
        #expect(handler.debounce == 1.0)
    }

    // MARK: - Closure invocation

    @Test(".immediate run closure receives correct value")
    func immediateRunReceivesValue() {
        nonisolated(unsafe) var received: AnyCodableValue?
        let handler = FormValueChangeHandler.immediate { received = $0 }
        handler.run(.string("hello"))
        #expect(received == .string("hello"))
    }

    @Test(".immediate run closure receives nil when value is nil")
    func immediateRunReceivesNil() {
        nonisolated(unsafe) var called = false
        let handler = FormValueChangeHandler.immediate { value in
            called = true
            #expect(value == nil)
        }
        handler.run(nil)
        #expect(called)
    }

    @Test(".debounced run closure receives correct value when called directly")
    func debouncedRunReceivesValue() {
        nonisolated(unsafe) var received: AnyCodableValue?
        let handler = FormValueChangeHandler.debounced(0.3) { received = $0 }
        handler.run(.bool(true))
        #expect(received == .bool(true))
    }

    // MARK: - Inline declaration on row types

    @Test("TextInputRow stores onChange handlers")
    func textInputRowStoresOnChange() {
        nonisolated(unsafe) var callCount = 0
        let row = TextInputRow(
            id: "lat",
            title: "Latitude",
            onChange: [
                .immediate { _ in callCount += 1 },
                .debounced(0.5) { _ in callCount += 1 }
            ]
        )
        #expect(row.onChange.count == 2)
        #expect(row.onChange[0].debounce == nil)
        #expect(row.onChange[1].debounce == 0.5)

        row.onChange[0].run(.string("37.7"))
        #expect(callCount == 1)
    }

    @Test("BooleanSwitchRow stores onChange handlers")
    func booleanSwitchRowStoresOnChange() {
        nonisolated(unsafe) var received: AnyCodableValue?
        let row = BooleanSwitchRow(
            id: "flag",
            title: "Flag",
            onChange: [.immediate { received = $0 }]
        )
        #expect(row.onChange.count == 1)
        row.onChange[0].run(.bool(true))
        #expect(received == .bool(true))
    }

    @Test("SingleValueRow stores onChange handlers")
    func singleValueRowStoresOnChange() {
        nonisolated(unsafe) var callCount = 0
        let row = SingleValueRow<MockOption>(
            id: "pick",
            title: "Pick",
            onChange: [.immediate { _ in callCount += 1 }]
        )
        #expect(row.onChange.count == 1)
        row.onChange[0].run(.string("a"))
        #expect(callCount == 1)
    }

    @Test("MultiValueRow stores onChange handlers")
    func multiValueRowStoresOnChange() {
        nonisolated(unsafe) var callCount = 0
        let row = MultiValueRow<MockOption>(
            id: "multi",
            title: "Multi",
            onChange: [.immediate { _ in callCount += 1 }]
        )
        #expect(row.onChange.count == 1)
        row.onChange[0].run(.array([.string("a")]))
        #expect(callCount == 1)
    }

    @Test("NumberInputRow stores onChange handlers")
    func numberInputRowStoresOnChange() {
        nonisolated(unsafe) var received: AnyCodableValue?
        let row = NumberInputRow(
            id: "count",
            title: "Count",
            onChange: [.immediate { received = $0 }]
        )
        #expect(row.onChange.count == 1)
        row.onChange[0].run(.int(42))
        #expect(received == .int(42))
    }

    @Test("EmailInputRow stores onChange handlers")
    func emailInputRowStoresOnChange() {
        nonisolated(unsafe) var callCount = 0
        let row = EmailInputRow(
            id: "email",
            title: "Email",
            onChange: [.immediate { _ in callCount += 1 }]
        )
        #expect(row.onChange.count == 1)
        row.onChange[0].run(.string("a@b.com"))
        #expect(callCount == 1)
    }

    // MARK: - Default (empty) onChange

    @Test("Row with no onChange defaults to empty array")
    func rowDefaultsToEmptyOnChange() {
        let row = TextInputRow(id: "text", title: "Text")
        #expect(row.onChange.isEmpty)
    }

    // MARK: - AnyFormRow propagation

    @Test("AnyFormRow carries onChange handlers from wrapped row")
    func anyFormRowCarriesOnChange() {
        nonisolated(unsafe) var callCount = 0
        let row = TextInputRow(
            id: "t",
            title: "T",
            onChange: [
                .immediate { _ in callCount += 1 },
                .debounced(1.0) { _ in callCount += 1 }
            ]
        )
        let anyRow = AnyFormRow(row)
        #expect(anyRow.onChange.count == 2)
        anyRow.onChange[0].run(.string("x"))
        #expect(callCount == 1)
    }

    @Test("AnyFormRow with no onChange has empty array")
    func anyFormRowNoOnChangeIsEmpty() {
        let row = BooleanSwitchRow(id: "b", title: "B")
        let anyRow = AnyFormRow(row)
        #expect(anyRow.onChange.isEmpty)
    }

    // MARK: - RawRepresentable overload

    @Test("TextInputRow RawRepresentable overload stores onChange")
    func textInputRowRawRepresentableOnChange() {
        nonisolated(unsafe) var called = false
        let row = TextInputRow(
            id: MockRowID.field,
            title: "Field",
            onChange: [.immediate { _ in called = true }]
        )
        #expect(row.id == MockRowID.field.rawValue)
        #expect(row.onChange.count == 1)
        row.onChange[0].run(nil)
        #expect(called)
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
            // Verify round-trip through AnyFormRow
            let concreteRow = AnyFormRow(row).asType(TextInputRow.self)
            #expect(concreteRow != nil)
        }
    }
}

// MARK: - Test Helpers

private enum MockOption: String, CaseIterable, CustomStringConvertible, Hashable, Sendable, Codable {
    case a, b, c
    var description: String { rawValue }
}

private enum MockRowID: String {
    case field
}
