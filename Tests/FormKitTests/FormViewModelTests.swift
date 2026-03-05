@testable import FormKit
import Foundation
import Testing

// MARK: - Helpers

private enum Env: String, CaseIterable, CustomStringConvertible, Hashable, Sendable, Codable {
    case dev, staging, prod
    var description: String { rawValue }
}

private func makeForm(rows: [AnyFormRow],
                      persistence: (any FormPersistence)? = nil,
                      saveBehaviour: FormSaveBehaviour = .buttonBottomForm()) -> FormDefinition {
    FormDefinition(id: "test-form", title: "Test", rows: rows, persistence: persistence, saveBehaviour: saveBehaviour)
}

// MARK: - FormViewModel Tests

@Suite("FormViewModel")
struct FormViewModelTests {
    @Test("Default values are loaded on init")
    func defaultValuesLoaded() {
        let form = makeForm(rows: [
            AnyFormRow(BooleanSwitchRow(id: "toggle", title: "T", defaultValue: true)),
            AnyFormRow(TextInputRow(id: "name", title: "N", defaultValue: "Alice"))
        ])
        let vm = FormViewModel(formDefinition: form)

        let toggle: Bool? = vm.value(for: "toggle")
        let name: String? = vm.value(for: "name")

        #expect(toggle == true)
        #expect(name == "Alice")
    }

    @Test("Setting a value marks the form dirty")
    func setValueMarksDirty() {
        let form = makeForm(rows: [AnyFormRow(BooleanSwitchRow(id: "t", title: "T"))])
        let vm = FormViewModel(formDefinition: form)

        #expect(vm.isDirty == false)
        vm.setBool(true, for: "t")
        #expect(vm.isDirty == true)
    }

    @Test("Typed value setters")
    func typedValueSetters() {
        let form = makeForm(rows: [
            AnyFormRow(TextInputRow(id: "text", title: "Text")),
            AnyFormRow(NumberInputRow(id: "int", title: "Int", kind: .integer)),
            AnyFormRow(NumberInputRow(id: "dbl", title: "Dbl", defaultValue: nil)),
            AnyFormRow(BooleanSwitchRow(id: "bool", title: "Bool"))
        ])
        let vm = FormViewModel(formDefinition: form)

        vm.setString("hello", for: "text")
        vm.setInt(42, for: "int")
        vm.setDouble(3.14, for: "dbl")
        vm.setBool(true, for: "bool")

        let text: String? = vm.value(for: "text")
        let int: Int? = vm.value(for: "int")
        let dbl: Double? = vm.value(for: "dbl")
        let bool: Bool? = vm.value(for: "bool")

        #expect(text == "hello")
        #expect(int == 42)
        #expect(dbl == 3.14)
        #expect(bool == true)
    }

    @Test("toggleArrayValue adds and removes")
    func toggleArrayValue() {
        let form = makeForm(rows: [AnyFormRow(MultiValueRow<Env>(id: "envs", title: "Envs"))])
        let vm = FormViewModel(formDefinition: form)

        vm.toggleArrayValue(.string("dev"), for: "envs")
        #expect(vm.rawValue(for: "envs") == .array([.string("dev")]))

        vm.toggleArrayValue(.string("staging"), for: "envs")
        #expect(vm.rawValue(for: "envs") == .array([.string("dev"), .string("staging")]))

        vm.toggleArrayValue(.string("dev"), for: "envs")
        #expect(vm.rawValue(for: "envs") == .array([.string("staging")]))
    }

    // MARK: - Visibility

    @Test("Row without conditions is always visible")
    func rowAlwaysVisible() {
        let form = makeForm(rows: [AnyFormRow(BooleanSwitchRow(id: "t", title: "T"))])
        let vm = FormViewModel(formDefinition: form)
        let row = form.rows.first!
        #expect(vm.isRowVisible(row) == true)
    }

    @Test("Row with condition is hidden/shown correctly")
    func conditionalVisibility() {
        let conditionalRow = BooleanSwitchRow(
            id: "advanced",
            title: "Advanced",
            conditions: [.isTrue(rowId: "showAdvanced")]
        )
        let form = makeForm(rows: [
            AnyFormRow(BooleanSwitchRow(id: "showAdvanced", title: "Show Advanced")),
            AnyFormRow(conditionalRow)
        ])
        let vm = FormViewModel(formDefinition: form)
        let advancedRow = form.rows[1]

        // Initially showAdvanced is false (default).
        #expect(vm.isRowVisible(advancedRow) == false)

        // Turn showAdvanced on.
        vm.setBool(true, for: "showAdvanced")
        #expect(vm.isRowVisible(advancedRow) == true)

        // Turn it off again.
        vm.setBool(false, for: "showAdvanced")
        #expect(vm.isRowVisible(advancedRow) == false)
    }

    // MARK: - Validation

    @Test("validateAll catches required fields")
    func validateAllRequired() {
        let form = makeForm(rows: [
            AnyFormRow(TextInputRow(id: "name", title: "Name", isRequired: true))
        ])
        let vm = FormViewModel(formDefinition: form)

        let isValid = vm.validateAll()
        #expect(isValid == false)
        #expect(vm.errorsForRow("name").isEmpty == false)
    }

    @Test("validateAll passes when required field is filled")
    func validateAllPassesWhenFilled() {
        let form = makeForm(rows: [
            AnyFormRow(TextInputRow(id: "name", title: "Name", isRequired: true))
        ])
        let vm = FormViewModel(formDefinition: form)
        vm.setString("Alice", for: "name")

        let isValid = vm.validateAll()
        #expect(isValid == true)
        #expect(vm.errorsForRow("name").isEmpty == true)
    }

    @Test("validateAll skips hidden rows")
    func validateAllSkipsHiddenRows() {
        let hiddenRow = TextInputRow(
            id: "secret",
            title: "Secret",
            isRequired: true,
            conditions: [.isTrue(rowId: "show")]
        )
        let form = makeForm(rows: [
            AnyFormRow(BooleanSwitchRow(id: "show", title: "Show", defaultValue: false)),
            AnyFormRow(hiddenRow)
        ])
        let vm = FormViewModel(formDefinition: form)

        // "show" is false, so "secret" is hidden — should not be validated.
        let isValid = vm.validateAll()
        #expect(isValid == true)
    }

    @Test("User-supplied onSave validators fire on validateAll")
    func onSaveValidatorsFire() {
        let form = makeForm(rows: [
            AnyFormRow(EmailInputRow(id: "email", title: "Email", isRequired: false))
        ])
        let vm = FormViewModel(formDefinition: form)
        vm.setString("notanemail", for: "email")

        let isValid = vm.validateAll()
        #expect(isValid == false)
        #expect(vm.errorsForRow("email").isEmpty == false)
    }

    @Test("onChange validators fire immediately on setValue")
    func onChangeValidators() {
        let row = TextInputRow(
            id: "text",
            title: "Text",
            validators: [.minLength(5, trigger: .onChange)]
        )
        let form = makeForm(rows: [AnyFormRow(row)])
        let vm = FormViewModel(formDefinition: form)

        vm.setString("hi", for: "text") // triggers onChange
        #expect(vm.errorsForRow("text").isEmpty == false)

        vm.setString("hello world", for: "text")
        #expect(vm.errorsForRow("text").isEmpty == true)
    }

    // MARK: - Save

    @Test("Save with invalid form returns false")
    func saveInvalidReturnsFalse() async {
        let form = makeForm(rows: [
            AnyFormRow(TextInputRow(id: "name", title: "Name", isRequired: true))
        ])
        let vm = FormViewModel(formDefinition: form)
        let result = await vm.save()
        #expect(result == false)
    }

    @Test("Save with valid form (no persistence) returns true")
    func saveValidNoPersistence() async {
        let form = makeForm(rows: [
            AnyFormRow(TextInputRow(id: "name", title: "Name", isRequired: true))
        ])
        let vm = FormViewModel(formDefinition: form)
        vm.setString("Alice", for: "name")

        let result = await vm.save()
        #expect(result == true)
        #expect(vm.isDirty == false)
    }

    @Test("Save with memory persistence saves and loads")
    func saveAndLoadMemory() async {
        let persistence = FormPersistenceMemory()
        let form = makeForm(rows: [
            AnyFormRow(TextInputRow(id: "name", title: "Name"))
        ], persistence: persistence)

        let vm = FormViewModel(formDefinition: form)
        vm.setString("Bob", for: "name")
        let saved = await vm.save()
        #expect(saved == true)

        // Create a new VM and load from same persistence.
        let vm2 = FormViewModel(formDefinition: form, persistence: persistence)
        await vm2.loadFromPersistence()
        let name: String? = vm2.value(for: "name")
        #expect(name == "Bob")
    }

    // MARK: - onSave Closure

    @Test("onSave closure fires after successful save with no persistence")
    func onSaveFiresWithNoPersistence() async {
        let form = makeForm(rows: [
            AnyFormRow(TextInputRow(id: "name", title: "Name"))
        ])
        var capturedValues: FormValueStore?
        let vm = FormViewModel(formDefinition: form, onSave: { values in
            capturedValues = values
        })
        vm.setString("Alice", for: "name")

        let result = await vm.save()

        #expect(result == true)
        #expect(capturedValues != nil)
        let name: String? = capturedValues?.value(for: "name")
        #expect(name == "Alice")
    }

    @Test("onSave closure fires after successful save with persistence")
    func onSaveFiresWithPersistence() async {
        let persistence = FormPersistenceMemory()
        let form = makeForm(rows: [
            AnyFormRow(TextInputRow(id: "city", title: "City"))
        ], persistence: persistence)

        var capturedValues: FormValueStore?
        let vm = FormViewModel(formDefinition: form, onSave: { values in
            capturedValues = values
        })
        vm.setString("NYC", for: "city")

        let result = await vm.save()

        #expect(result == true)
        #expect(capturedValues != nil)
        let city: String? = capturedValues?.value(for: "city")
        #expect(city == "NYC")
    }

    @Test("onSave closure does NOT fire when validation fails")
    func onSaveDoesNotFireOnValidationFailure() async {
        let form = makeForm(rows: [
            AnyFormRow(TextInputRow(id: "name", title: "Name", isRequired: true))
        ])
        var onSaveCalled = false
        let vm = FormViewModel(formDefinition: form, onSave: { _ in
            onSaveCalled = true
        })
        // name is required but not set — validation will fail.

        let result = await vm.save()

        #expect(result == false)
        #expect(onSaveCalled == false)
    }

    @Test("onSave can be assigned after init")
    func onSaveAssignedAfterInit() async {
        let form = makeForm(rows: [
            AnyFormRow(TextInputRow(id: "val", title: "Val"))
        ])
        let vm = FormViewModel(formDefinition: form)
        var called = false
        vm.onSave = { _ in called = true }
        vm.setString("hello", for: "val")

        await vm.save()

        #expect(called == true)
    }

    // MARK: - FormSaveBehaviour

    @Test("saveBehaviour .onChange is stored on FormDefinition")
    func saveBehaviourOnChangeStored() {
        let form = makeForm(rows: [], saveBehaviour: .onChange)
        #expect({
            if case .onChange = form.saveBehaviour { return true }
            return false
        }())
    }

    @Test("saveBehaviour .buttonNavigationBar is stored with custom title")
    func saveBehaviourButtonNavigationBar() {
        let form = makeForm(rows: [], saveBehaviour: .buttonNavigationBar(title: "Apply"))
        if case let .buttonNavigationBar(title) = form.saveBehaviour {
            #expect(title == "Apply")
        } else {
            Issue.record("Expected .buttonNavigationBar saveBehaviour")
        }
    }

    @Test("saveBehaviour .buttonBottomForm is stored with default title")
    func saveBehaviourButtonBottomFormDefault() {
        let form = makeForm(rows: [], saveBehaviour: .buttonBottomForm())
        if case let .buttonBottomForm(title) = form.saveBehaviour {
            #expect(title == "Save")
        } else {
            Issue.record("Expected .buttonBottomForm saveBehaviour")
        }
    }

    @Test("FormSaveBehaviour saveButtonTitle returns nil for .onChange")
    func saveButtonTitleOnChange() {
        let behaviour = FormSaveBehaviour.onChange
        #expect(behaviour.saveButtonTitle == nil)
    }

    @Test("FormSaveBehaviour saveButtonTitle returns title for button cases")
    func saveButtonTitleForButtonCases() {
        #expect(FormSaveBehaviour.buttonNavigationBar(title: "Go").saveButtonTitle == "Go")
        #expect(FormSaveBehaviour.buttonBottomForm(title: "Done").saveButtonTitle == "Done")
        #expect(FormSaveBehaviour.buttonNavigationBar().saveButtonTitle == "Save")
        #expect(FormSaveBehaviour.buttonBottomForm().saveButtonTitle == "Save")
    }

    @Test("setValue with .onChange saveBehaviour schedules a save Task")
    func setValueWithOnChangeBehaviourSchedulesSave() async {
        let persistence = FormPersistenceMemory()
        let form = makeForm(
            rows: [AnyFormRow(BooleanSwitchRow(id: "flag", title: "Flag"))],
            persistence: persistence,
            saveBehaviour: .onChange
        )
        let vm = FormViewModel(formDefinition: form)

        vm.setBool(true, for: "flag")

        // Yield to allow the spawned save Task to run.
        await Task.yield()
        await Task.yield()

        // Confirm data was persisted by loading it through a fresh vm.
        let vm2 = FormViewModel(formDefinition: form, persistence: persistence)
        await vm2.loadFromPersistence()
        let flag: Bool? = vm2.value(for: "flag")
        #expect(flag == true)
    }

    @Test("setValue with button saveBehaviour does NOT auto-save")
    func setValueWithButtonBehaviourDoesNotAutoSave() async {
        let persistence = FormPersistenceMemory()
        let form = makeForm(
            rows: [AnyFormRow(TextInputRow(id: "text", title: "Text"))],
            persistence: persistence,
            saveBehaviour: .buttonBottomForm()
        )
        let vm = FormViewModel(formDefinition: form)

        vm.setString("unsaved", for: "text")

        // Yield to prove no background task persists anything.
        await Task.yield()
        await Task.yield()

        // Nothing should be in persistence yet.
        let loaded = try? await persistence.load(formId: "test-form")
        #expect(loaded?.isEmpty ?? true)
    }

    // MARK: - Synchronous Persistence Load at Init

    @Test("Persisted values win over row defaults at init (UserDefaults)")
    func persistedValuesWinOverDefaultsAtInit() async throws {
        let suiteName = "FormKitTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let persistence = FormPersistenceUserDefaults(defaults: defaults)

        // Save a value to persistence before the VM is created.
        var store = FormValueStore()
        store["toggle"] = .bool(false) // row default is true, persisted is false
        try await persistence.save(store, formId: "test-form")

        // Create the VM — it should synchronously load from UserDefaults.
        let form = makeForm(
            rows: [AnyFormRow(BooleanSwitchRow(id: "toggle", title: "T", defaultValue: true))],
            persistence: persistence
        )
        let vm = FormViewModel(formDefinition: form)

        // The persisted false should win over the row default of true.
        let toggle: Bool? = vm.value(for: "toggle")
        #expect(toggle == false)
    }

    @Test("Row defaults are used when no persisted data exists (UserDefaults)")
    func rowDefaultsUsedWhenNoPersistedData() {
        let suiteName = "FormKitTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let persistence = FormPersistenceUserDefaults(defaults: defaults)
        let form = makeForm(
            rows: [AnyFormRow(BooleanSwitchRow(id: "toggle", title: "T", defaultValue: true))],
            persistence: persistence
        )
        let vm = FormViewModel(formDefinition: form)

        // No persisted data — row default should apply.
        let toggle: Bool? = vm.value(for: "toggle")
        #expect(toggle == true)
    }

    @Test("Non-synchronous persistence does NOT pre-load at init (Memory)")
    func nonSyncPersistenceDoesNotPreLoadAtInit() async {
        let persistence = FormPersistenceMemory()

        // Save a value.
        var store = FormValueStore()
        store["name"] = .string("Stored")
        try? await persistence.save(store, formId: "test-form")

        let form = makeForm(
            rows: [AnyFormRow(TextInputRow(id: "name", title: "N", defaultValue: "Default"))],
            persistence: persistence
        )
        // Memory persistence is not FormSynchronousPersistence, so init does not load.
        let vm = FormViewModel(formDefinition: form)

        // Should see the row default, not the stored value.
        let name: String? = vm.value(for: "name")
        #expect(name == "Default")

        // After explicit async load, stored value should appear.
        await vm.loadFromPersistence()
        let nameAfterLoad: String? = vm.value(for: "name")
        #expect(nameAfterLoad == "Stored")
    }

    // MARK: - Reset

    @Test("Reset restores default values")
    func resetRestoresDefaults() {
        let form = makeForm(rows: [
            AnyFormRow(BooleanSwitchRow(id: "t", title: "T", defaultValue: true))
        ])
        let vm = FormViewModel(formDefinition: form)

        vm.setBool(false, for: "t")
        vm.reset()

        let value: Bool? = vm.value(for: "t")
        #expect(value == true)
        #expect(vm.isDirty == false)
        #expect(vm.errors.isEmpty)
    }

    // MARK: - onChange Handlers

    @Test("Immediate onChange handler fires on setValue")
    func immediateOnChangeHandlerFires() {
        nonisolated(unsafe) var received: AnyCodableValue?
        let row = TextInputRow(
            id: "text",
            title: "Text",
            onChange: [.immediate { received = $0 }]
        )
        let form = makeForm(rows: [AnyFormRow(row)])
        let vm = FormViewModel(formDefinition: form)

        vm.setString("hello", for: "text")

        #expect(received == .string("hello"))
    }

    @Test("Immediate onChange handler fires with nil when value is cleared")
    func immediateOnChangeHandlerFiresWithNil() {
        nonisolated(unsafe) var callCount = 0
        let row = BooleanSwitchRow(
            id: "flag",
            title: "Flag",
            onChange: [.immediate { _ in callCount += 1 }]
        )
        let form = makeForm(rows: [AnyFormRow(row)])
        let vm = FormViewModel(formDefinition: form)

        vm.setValue(nil, for: "flag")

        #expect(callCount == 1)
    }

    @Test("Multiple onChange handlers on one row all fire")
    func multipleOnChangeHandlersFire() {
        nonisolated(unsafe) var countA = 0
        nonisolated(unsafe) var countB = 0
        let row = TextInputRow(
            id: "text",
            title: "Text",
            onChange: [
                .immediate { _ in countA += 1 },
                .immediate { _ in countB += 1 }
            ]
        )
        let form = makeForm(rows: [AnyFormRow(row)])
        let vm = FormViewModel(formDefinition: form)

        vm.setString("test", for: "text")

        #expect(countA == 1)
        #expect(countB == 1)
    }

    @Test("onChange handler receives the new value, not the old")
    func onChangeHandlerReceivesNewValue() {
        nonisolated(unsafe) var values: [AnyCodableValue?] = []
        let row = TextInputRow(
            id: "text",
            title: "Text",
            onChange: [.immediate { values.append($0) }]
        )
        let form = makeForm(rows: [AnyFormRow(row)])
        let vm = FormViewModel(formDefinition: form)

        vm.setString("first", for: "text")
        vm.setString("second", for: "text")

        #expect(values.count == 2)
        #expect(values[0] == .string("first"))
        #expect(values[1] == .string("second"))
    }

    @Test("onChange handler does not fire for a different row's changes")
    func onChangeHandlerNotFiredForOtherRow() {
        nonisolated(unsafe) var callCount = 0
        let watchedRow = TextInputRow(
            id: "watched",
            title: "Watched",
            onChange: [.immediate { _ in callCount += 1 }]
        )
        let otherRow = TextInputRow(id: "other", title: "Other")
        let form = makeForm(rows: [AnyFormRow(watchedRow), AnyFormRow(otherRow)])
        let vm = FormViewModel(formDefinition: form)

        vm.setString("change other", for: "other")

        #expect(callCount == 0)
    }

    @Test("Row without onChange handlers — setValue does not crash")
    func noOnChangeHandlersDoesNotCrash() {
        let row = TextInputRow(id: "text", title: "Text") // no onChange
        let form = makeForm(rows: [AnyFormRow(row)])
        let vm = FormViewModel(formDefinition: form)

        // Should not crash.
        vm.setString("hello", for: "text")
        #expect(vm.value(for: "text") as String? == "hello")
    }

    @Test("Debounced onChange handler fires after delay")
    func debouncedOnChangeHandlerFiresAfterDelay() async {
        nonisolated(unsafe) var received: AnyCodableValue?
        let row = TextInputRow(
            id: "text",
            title: "Text",
            onChange: [.debounced(0.05) { received = $0 }]
        )
        let form = makeForm(rows: [AnyFormRow(row)])
        let vm = FormViewModel(formDefinition: form)

        vm.setString("debounced", for: "text")

        // Should not have fired yet.
        #expect(received == nil)

        // Wait for debounce to complete.
        try? await Task.sleep(for: .milliseconds(150))

        #expect(received == .string("debounced"))
    }

    @Test("Debounced onChange handler fires with the latest value after rapid updates")
    func debouncedOnChangeHandlerUsesLatestValue() async {
        nonisolated(unsafe) var receivedValues: [AnyCodableValue?] = []
        let row = TextInputRow(
            id: "text",
            title: "Text",
            onChange: [.debounced(0.05) { receivedValues.append($0) }]
        )
        let form = makeForm(rows: [AnyFormRow(row)])
        let vm = FormViewModel(formDefinition: form)

        // Rapid updates — only the last should fire.
        vm.setString("a", for: "text")
        vm.setString("b", for: "text")
        vm.setString("c", for: "text")

        // Wait for debounce.
        try? await Task.sleep(for: .milliseconds(150))

        // Only one handler invocation with the final value.
        #expect(receivedValues.count == 1)
        #expect(receivedValues[0] == .string("c"))
    }

    @Test("Both immediate and debounced handlers on same row both fire")
    func immediateAndDebouncedHandlersBothFire() async {
        nonisolated(unsafe) var immediateCount = 0
        nonisolated(unsafe) var debouncedCount = 0
        let row = TextInputRow(
            id: "text",
            title: "Text",
            onChange: [
                .immediate { _ in immediateCount += 1 },
                .debounced(0.05) { _ in debouncedCount += 1 }
            ]
        )
        let form = makeForm(rows: [AnyFormRow(row)])
        let vm = FormViewModel(formDefinition: form)

        vm.setString("hello", for: "text")

        // Immediate fires synchronously.
        #expect(immediateCount == 1)
        #expect(debouncedCount == 0)

        // Wait for debounce.
        try? await Task.sleep(for: .milliseconds(150))

        #expect(immediateCount == 1)
        #expect(debouncedCount == 1)
    }

    @Test("reset cancels pending debounced onChange handlers")
    func resetCancelsPendingDebouncedHandlers() async {
        nonisolated(unsafe) var debouncedCallCount = 0
        let row = TextInputRow(
            id: "text",
            title: "Text",
            onChange: [.debounced(0.05) { _ in debouncedCallCount += 1 }]
        )
        let form = makeForm(rows: [AnyFormRow(row)])
        let vm = FormViewModel(formDefinition: form)

        vm.setString("trigger", for: "text")
        vm.reset() // cancels the pending debounce task

        try? await Task.sleep(for: .milliseconds(150))

        // Handler should not have fired since it was cancelled.
        #expect(debouncedCallCount == 0)
    }

    // MARK: - visibleRows

    @Test("visibleRows filters by conditions")
    func visibleRowsFiltered() {
        let form = makeForm(rows: [
            AnyFormRow(BooleanSwitchRow(id: "show", title: "Show", defaultValue: false)),
            AnyFormRow(TextInputRow(
                id: "hidden",
                title: "Hidden",
                conditions: [.isTrue(rowId: "show")]
            ))
        ])
        let vm = FormViewModel(formDefinition: form)

        #expect(vm.visibleRows.count == 1)
        vm.setBool(true, for: "show")
        #expect(vm.visibleRows.count == 2)
    }
}
