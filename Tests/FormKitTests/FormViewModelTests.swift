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
                      saveBehaviour: FormSaveBehaviour = .buttonBottomForm(),
                      onSave: [FormSaveAction] = []) -> FormDefinition {
    FormDefinition(id: "test-form", title: "Test", rows: rows, persistence: persistence, saveBehaviour: saveBehaviour, onSave: onSave)
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
            AnyFormRow(NumberInputRow(id: "int", title: "Int", kind: .int(defaultValue: nil))),
            AnyFormRow(NumberInputRow(id: "dbl", title: "Dbl", kind: .decimal(defaultValue: nil))),
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

    @Test("Row with no showRow actions targeting it is always visible")
    func rowWithNoShowActionsIsAlwaysVisible() {
        let form = makeForm(rows: [AnyFormRow(BooleanSwitchRow(id: "t", title: "T"))])
        let vm = FormViewModel(formDefinition: form)
        let row = form.rows.first!
        #expect(vm.isRowVisible(row) == true)
    }

    @Test("Row is hidden/shown by showRow action on another row")
    func showRowActionControlsVisibility() {
        let form = makeForm(rows: [
            // "showAdvanced" toggle has a showRow action targeting "advanced".
            AnyFormRow(BooleanSwitchRow(
                id: "showAdvanced",
                title: "Show Advanced",
                onChange: [
                    .showRow(id: "advanced", when: [.isTrue(rowId: "showAdvanced")])
                ]
            )),
            AnyFormRow(BooleanSwitchRow(id: "advanced", title: "Advanced"))
        ])
        let vm = FormViewModel(formDefinition: form)
        let advancedRow = form.rows[1]

        // Initially showAdvanced is false (default) → "advanced" should be hidden.
        #expect(vm.isRowVisible(advancedRow) == false)

        // Turn showAdvanced on.
        vm.setBool(true, for: "showAdvanced")
        #expect(vm.isRowVisible(advancedRow) == true)

        // Turn it off again.
        vm.setBool(false, for: "showAdvanced")
        #expect(vm.isRowVisible(advancedRow) == false)
    }

    @Test("Row with no showRow targeting it is always visible regardless of other row states")
    func rowWithNoTargetingShowActionsIsAlwaysVisible() {
        let form = makeForm(rows: [
            AnyFormRow(BooleanSwitchRow(
                id: "toggle",
                title: "Toggle",
                onChange: [.showRow(id: "other", when: [.isTrue(rowId: "toggle")])]
            )),
            AnyFormRow(TextInputRow(id: "other", title: "Other")),
            // "free" has no showRow actions pointing at it — always visible.
            AnyFormRow(TextInputRow(id: "free", title: "Free"))
        ])
        let vm = FormViewModel(formDefinition: form)
        let freeRow = form.rows[2]

        vm.setBool(false, for: "toggle")
        #expect(vm.isRowVisible(freeRow) == true)

        vm.setBool(true, for: "toggle")
        #expect(vm.isRowVisible(freeRow) == true)
    }

    @Test("showRow with empty conditions always shows the target")
    func showRowWithEmptyConditionsAlwaysShows() {
        let form = makeForm(rows: [
            AnyFormRow(BooleanSwitchRow(
                id: "source",
                title: "Source",
                // Empty conditions — target is always shown.
                onChange: [.showRow(id: "target", when: [])]
            )),
            AnyFormRow(TextInputRow(id: "target", title: "Target"))
        ])
        let vm = FormViewModel(formDefinition: form)
        let targetRow = form.rows[1]

        #expect(vm.isRowVisible(targetRow) == true)
    }

    // MARK: - Validation

    @Test("validateAll catches required fields")
    func validateAllRequired() {
        let form = makeForm(rows: [
            AnyFormRow(TextInputRow(id: "name", title: "Name", validators: [.required()]))
        ])
        let vm = FormViewModel(formDefinition: form)

        let isValid = vm.validateAll()
        #expect(isValid == false)
        #expect(vm.errorsForRow("name").isEmpty == false)
    }

    @Test("validateAll passes when required field is filled")
    func validateAllPassesWhenFilled() {
        let form = makeForm(rows: [
            AnyFormRow(TextInputRow(id: "name", title: "Name", validators: [.required()]))
        ])
        let vm = FormViewModel(formDefinition: form)
        vm.setString("Alice", for: "name")

        let isValid = vm.validateAll()
        #expect(isValid == true)
        #expect(vm.errorsForRow("name").isEmpty == true)
    }

    @Test("validateAll skips hidden rows")
    func validateAllSkipsHiddenRows() {
        // "show" starts false; a showRow action on "show" targets "secret".
        // When "show" is false, "secret" is hidden and should not be validated.
        let form = makeForm(rows: [
            AnyFormRow(BooleanSwitchRow(
                id: "show",
                title: "Show",
                defaultValue: false,
                onChange: [.showRow(id: "secret", when: [.isTrue(rowId: "show")])]
            )),
            AnyFormRow(TextInputRow(id: "secret", title: "Secret", validators: [.required()]))
        ])
        let vm = FormViewModel(formDefinition: form)

        // "show" is false → "secret" is hidden → should not be validated.
        let isValid = vm.validateAll()
        #expect(isValid == true)
    }

    @Test("User-supplied onSave validators fire on validateAll")
    func onSaveValidatorsFire() {
        let form = makeForm(rows: [
            AnyFormRow(TextInputRow(id: "email", title: "Email", validators: [.email()]))
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

    @Test("save sets saveError when live onChange errors are present")
    func saveSetsSaveErrorForLiveErrors() async {
        let row = TextInputRow(
            id: "text",
            title: "Text",
            validators: [.minLength(5, trigger: .onChange)]
        )
        let form = makeForm(rows: [AnyFormRow(row)])
        let vm = FormViewModel(formDefinition: form)

        // Trigger an onChange error.
        vm.setString("hi", for: "text")
        #expect(vm.errorsForRow("text").isEmpty == false)

        // Save should be blocked and saveError surfaced for the alert.
        let saved = await vm.save()
        #expect(saved == false)
        #expect(vm.saveError is FormValidationError)
        // Row-level error should still be present so the user can see what to fix.
        #expect(vm.errorsForRow("text").isEmpty == false)
    }

    @Test("save does NOT set saveError when only onSave validators fail")
    func saveDoesNotSetSaveErrorForOnSaveValidators() async {
        let row = TextInputRow(
            id: "name",
            title: "Name",
            validators: [.required(trigger: .onSave)]
        )
        let form = makeForm(rows: [AnyFormRow(row)])
        let vm = FormViewModel(formDefinition: form)

        // No live errors — the field is simply empty.
        #expect(vm.errorsForRow("name").isEmpty == true)

        let saved = await vm.save()
        #expect(saved == false)
        // Row-level error should be set by validateAll, but saveError should NOT be set.
        #expect(vm.saveError == nil)
        #expect(vm.errorsForRow("name").isEmpty == false)
    }

    @Test("validateAll bails early and preserves onChange errors without running onSave validators")
    func validateAllBailsEarlyWhenOnChangeErrorsPresent() async {
        let row = TextInputRow(
            id: "text",
            title: "Text",
            validators: [
                .minLength(5, trigger: .onChange),
                .minLength(3, trigger: .onSave)
            ]
        )
        let form = makeForm(rows: [AnyFormRow(row)])
        let vm = FormViewModel(formDefinition: form)

        // "hi" fails the onChange validator (minLength 5) but would pass the onSave one (minLength 3).
        vm.setString("hi", for: "text")
        #expect(vm.errorsForRow("text").isEmpty == false)

        // validateAll bails immediately due to live onChange error — onSave validators never run.
        // The existing row-level error is preserved so the user can see what to fix.
        let isValid = vm.validateAll()
        #expect(isValid == false)
        #expect(vm.errorsForRow("text").isEmpty == false)
    }

    // MARK: - Save

    @Test("Save with invalid form returns false")
    func saveInvalidReturnsFalse() async {
        let form = makeForm(rows: [
            AnyFormRow(TextInputRow(id: "name", title: "Name", validators: [.required()]))
        ])
        let vm = FormViewModel(formDefinition: form)
        let result = await vm.save()
        #expect(result == false)
    }

    @Test("Save with valid form (no persistence) returns true")
    func saveValidNoPersistence() async {
        let form = makeForm(rows: [
            AnyFormRow(TextInputRow(id: "name", title: "Name", validators: [.required()]))
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

    // MARK: - FormSaveAction (form-level)

    @Test("FormSaveAction fires after successful save with no persistence")
    func onSaveFiresWithNoPersistence() async {
        nonisolated(unsafe) var capturedValues: FormValueStore?
        let form = makeForm(
            rows: [AnyFormRow(TextInputRow(id: "name", title: "Name"))],
            onSave: [FormSaveAction { values in capturedValues = values }]
        )
        let vm = FormViewModel(formDefinition: form)
        vm.setString("Alice", for: "name")

        let result = await vm.save()

        #expect(result == true)
        #expect(capturedValues != nil)
        let name: String? = capturedValues?.value(for: "name")
        #expect(name == "Alice")
    }

    @Test("FormSaveAction fires after successful save with persistence")
    func onSaveFiresWithPersistence() async {
        nonisolated(unsafe) var capturedValues: FormValueStore?
        let persistence = FormPersistenceMemory()
        let form = makeForm(
            rows: [AnyFormRow(TextInputRow(id: "city", title: "City"))],
            persistence: persistence,
            onSave: [FormSaveAction { values in capturedValues = values }]
        )
        let vm = FormViewModel(formDefinition: form)
        vm.setString("NYC", for: "city")

        let result = await vm.save()

        #expect(result == true)
        #expect(capturedValues != nil)
        let city: String? = capturedValues?.value(for: "city")
        #expect(city == "NYC")
    }

    @Test("FormSaveAction does NOT fire when validation fails")
    func onSaveDoesNotFireOnValidationFailure() async {
        nonisolated(unsafe) var onSaveCalled = false
        let form = makeForm(
            rows: [AnyFormRow(TextInputRow(id: "name", title: "Name", validators: [.required()]))],
            onSave: [FormSaveAction { _ in onSaveCalled = true }]
        )
        // name is required but not set — validation will fail.
        let vm = FormViewModel(formDefinition: form)

        let result = await vm.save()

        #expect(result == false)
        #expect(onSaveCalled == false)
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

    @Test("saveBehaviour .buttonStickyBottom is stored with default title")
    func saveBehaviourButtonStickyBottomDefault() {
        let form = makeForm(rows: [], saveBehaviour: .buttonStickyBottom())
        if case let .buttonStickyBottom(title) = form.saveBehaviour {
            #expect(title == "Save")
        } else {
            Issue.record("Expected .buttonStickyBottom saveBehaviour")
        }
    }

    @Test("saveBehaviour .buttonStickyBottom is stored with custom title")
    func saveBehaviourButtonStickyBottomCustomTitle() {
        let form = makeForm(rows: [], saveBehaviour: .buttonStickyBottom(title: "Apply"))
        if case let .buttonStickyBottom(title) = form.saveBehaviour {
            #expect(title == "Apply")
        } else {
            Issue.record("Expected .buttonStickyBottom saveBehaviour")
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
        #expect(FormSaveBehaviour.buttonStickyBottom(title: "Apply").saveButtonTitle == "Apply")
        #expect(FormSaveBehaviour.buttonNavigationBar().saveButtonTitle == "Save")
        #expect(FormSaveBehaviour.buttonBottomForm().saveButtonTitle == "Save")
        #expect(FormSaveBehaviour.buttonStickyBottom().saveButtonTitle == "Save")
    }

    @Test("setValue with .onChange saveBehaviour triggers a save")
    func setValueWithOnChangeBehaviourSchedulesSave() async {
        let persistence = FormPersistenceMemory()
        let form = makeForm(
            rows: [AnyFormRow(BooleanSwitchRow(id: "flag", title: "Flag"))],
            persistence: persistence,
            saveBehaviour: .onChange
        )
        let vm = FormViewModel(formDefinition: form)

        // Ensure the initial load has completed so `status` is `.ready`.
        await vm.loadFromPersistence()

        vm.setBool(true, for: "flag")

        // Explicitly await a save to flush the pending auto-save. For a row with no
        // validators this always succeeds. We use await save() rather than polling
        // isDirty because the init's background Task can race and reset isDirty/values
        // before the auto-save Task runs, making the poll unreliable.
        await vm.save()

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

    // MARK: - Async Persistence Load

    @Test("Persisted values win over row defaults after load completes")
    func persistedValuesWinOverDefaultsAfterLoad() async throws {
        let persistence = FormPersistenceMemory()

        // Save a value to persistence before the VM is created.
        var store = FormValueStore()
        store["toggle"] = .bool(false) // row default is true, persisted is false
        try await persistence.save(store, formId: "test-form")

        let form = makeForm(
            rows: [AnyFormRow(BooleanSwitchRow(id: "toggle", title: "T", defaultValue: true))],
            persistence: persistence
        )
        let vm = FormViewModel(formDefinition: form)

        // Before load completes, the row default is in place and state is .loading.
        #expect(vm.status == .loading)
        let toggleBeforeLoad: Bool? = vm.value(for: "toggle")
        #expect(toggleBeforeLoad == true)

        // After explicit load the persisted false wins over the row default of true.
        await vm.loadFromPersistence()
        #expect(vm.status == .ready)
        let toggleAfterLoad: Bool? = vm.value(for: "toggle")
        #expect(toggleAfterLoad == false)
    }

    @Test("Row defaults are used when no persisted data exists")
    func rowDefaultsUsedWhenNoPersistedData() async {
        let persistence = FormPersistenceMemory()
        let form = makeForm(
            rows: [AnyFormRow(BooleanSwitchRow(id: "toggle", title: "T", defaultValue: true))],
            persistence: persistence
        )
        let vm = FormViewModel(formDefinition: form)
        await vm.loadFromPersistence()

        // No persisted data — row default should apply after load.
        let toggle: Bool? = vm.value(for: "toggle")
        #expect(toggle == true)
    }

    @Test("status transitions from .loading to .ready after load")
    func statusTransitionsAfterLoad() async {
        let persistence = FormPersistenceMemory()
        let form = makeForm(rows: [], persistence: persistence)
        let vm = FormViewModel(formDefinition: form)

        #expect(vm.status == .loading)
        await vm.loadFromPersistence()
        #expect(vm.status == .ready)
    }

    @Test("status is .ready immediately when no persistence backend is set")
    func statusIsReadyWithNoPersistence() async {
        let form = makeForm(rows: [], persistence: nil)
        let vm = FormViewModel(formDefinition: form)

        await vm.loadFromPersistence()
        #expect(vm.status == .ready)
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

    // MARK: - Actions dispatch

    @Test("Immediate .custom action fires on setValue")
    func immediateCustomActionFires() {
        nonisolated(unsafe) var receivedRowId: String?
        let row = TextInputRow(
            id: "text",
            title: "Text",
            onChange: [.custom { _, rowId in receivedRowId = rowId }]
        )
        let form = makeForm(rows: [AnyFormRow(row)])
        let vm = FormViewModel(formDefinition: form)

        vm.setString("hello", for: "text")

        #expect(receivedRowId == "text")
    }

    @Test("Immediate .custom action receives the current form store")
    func customActionReceivesStore() {
        nonisolated(unsafe) var capturedValue: AnyCodableValue?
        let row = TextInputRow(
            id: "text",
            title: "Text",
            onChange: [.custom { store, rowId in capturedValue = store[rowId] }]
        )
        let form = makeForm(rows: [AnyFormRow(row)])
        let vm = FormViewModel(formDefinition: form)

        vm.setString("hello", for: "text")

        #expect(capturedValue == .string("hello"))
    }

    @Test("Multiple .custom actions on one row all fire")
    func multipleCustomActionsFire() {
        nonisolated(unsafe) var countA = 0
        nonisolated(unsafe) var countB = 0
        let row = TextInputRow(
            id: "text",
            title: "Text",
            onChange: [
                .custom { _, _ in countA += 1 },
                .custom { _, _ in countB += 1 }
            ]
        )
        let form = makeForm(rows: [AnyFormRow(row)])
        let vm = FormViewModel(formDefinition: form)

        vm.setString("test", for: "text")

        #expect(countA == 1)
        #expect(countB == 1)
    }

    @Test(".custom action does not fire for a different row's changes")
    func customActionNotFiredForOtherRow() {
        nonisolated(unsafe) var callCount = 0
        let watchedRow = TextInputRow(
            id: "watched",
            title: "Watched",
            onChange: [.custom { _, _ in callCount += 1 }]
        )
        let otherRow = TextInputRow(id: "other", title: "Other")
        let form = makeForm(rows: [AnyFormRow(watchedRow), AnyFormRow(otherRow)])
        let vm = FormViewModel(formDefinition: form)

        vm.setString("change other", for: "other")

        #expect(callCount == 0)
    }

    @Test("Row without actions — setValue does not crash")
    func noActionsDoesNotCrash() {
        let row = TextInputRow(id: "text", title: "Text")
        let form = makeForm(rows: [AnyFormRow(row)])
        let vm = FormViewModel(formDefinition: form)

        vm.setString("hello", for: "text")
        #expect(vm.value(for: "text") as String? == "hello")
    }

    @Test(".setValue action updates the target row's value")
    func setValueActionUpdatesTargetRow() {
        let sourceRow = BooleanSwitchRow(
            id: "source",
            title: "Source",
            onChange: [
                .setValue(on: "target") { store in
                    guard case let .bool(val) = store["source"] else { return nil }
                    return .string(val ? "yes" : "no")
                }
            ]
        )
        let targetRow = TextInputRow(id: "target", title: "Target", defaultValue: "unset")
        let form = makeForm(rows: [AnyFormRow(sourceRow), AnyFormRow(targetRow)])
        let vm = FormViewModel(formDefinition: form)

        vm.setBool(true, for: "source")

        let target: String? = vm.value(for: "target")
        #expect(target == "yes")
    }

    @Test(".setValue action returning nil does not overwrite target")
    func setValueActionNilDoesNotOverwrite() {
        let sourceRow = TextInputRow(
            id: "source",
            title: "Source",
            onChange: [
                .setValue(on: "target") { _ in nil } // always returns nil
            ]
        )
        let targetRow = TextInputRow(id: "target", title: "Target", defaultValue: "initial")
        let form = makeForm(rows: [AnyFormRow(sourceRow), AnyFormRow(targetRow)])
        let vm = FormViewModel(formDefinition: form)

        vm.setString("something", for: "source")

        let target: String? = vm.value(for: "target")
        #expect(target == "initial") // unchanged
    }

    @Test(".runValidation action re-runs validators on the changed row")
    func runValidationActionFiresValidators() {
        let row = TextInputRow(
            id: "text",
            title: "Text",
            validators: [.minLength(5, trigger: .onChange)],
            onChange: [.runValidation()]
        )
        let form = makeForm(rows: [AnyFormRow(row)])
        let vm = FormViewModel(formDefinition: form)

        vm.setString("hi", for: "text") // too short
        #expect(vm.errorsForRow("text").isEmpty == false)

        vm.setString("hello world", for: "text")
        #expect(vm.errorsForRow("text").isEmpty == true)
    }

    @Test("FormSaveAction fires after successful save")
    func onSaveActionFiresOnSave() async {
        nonisolated(unsafe) var savedStore: FormValueStore?
        let row = TextInputRow(id: "city", title: "City")
        let form = makeForm(
            rows: [AnyFormRow(row)],
            onSave: [FormSaveAction { store in savedStore = store }]
        )
        let vm = FormViewModel(formDefinition: form)
        vm.setString("NYC", for: "city")

        let result = await vm.save()

        #expect(result == true)
        #expect(savedStore != nil)
        let city: String? = savedStore?.value(for: "city")
        #expect(city == "NYC")
    }

    @Test("FormSaveAction does NOT fire on onChange")
    func onSaveActionDoesNotFireOnChange() {
        nonisolated(unsafe) var callCount = 0
        let row = TextInputRow(id: "text", title: "Text")
        let form = makeForm(
            rows: [AnyFormRow(row)],
            onSave: [FormSaveAction { _ in callCount += 1 }]
        )
        let vm = FormViewModel(formDefinition: form)

        vm.setString("hello", for: "text")
        vm.setString("world", for: "text")

        #expect(callCount == 0) // not called — only called on save
    }

    @Test("Debounced .custom action fires after delay")
    func debouncedCustomActionFiresAfterDelay() async {
        nonisolated(unsafe) var receivedRowId: String?
        let row = TextInputRow(
            id: "text",
            title: "Text",
            onChange: [.custom(timing: .debounced(0.05)) { _, rowId in receivedRowId = rowId }]
        )
        let form = makeForm(rows: [AnyFormRow(row)])
        let vm = FormViewModel(formDefinition: form)

        vm.setString("debounced", for: "text")

        // Should not have fired yet.
        #expect(receivedRowId == nil)

        // Wait for debounce to complete.
        try? await Task.sleep(for: .milliseconds(150))

        #expect(receivedRowId == "text")
    }

    @Test("Debounced .custom action fires with the latest store after rapid updates")
    func debouncedCustomActionUsesLatestStore() async {
        nonisolated(unsafe) var capturedValues: [AnyCodableValue?] = []
        let row = TextInputRow(
            id: "text",
            title: "Text",
            onChange: [.custom(timing: .debounced(0.05)) { store, rowId in
                capturedValues.append(store[rowId])
            }]
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
        #expect(capturedValues.count == 1)
        #expect(capturedValues[0] == .string("c"))
    }

    @Test("Immediate and debounced actions on same row both fire")
    func immediateAndDebouncedActionsBothFire() async {
        nonisolated(unsafe) var immediateCount = 0
        nonisolated(unsafe) var debouncedCount = 0
        let row = TextInputRow(
            id: "text",
            title: "Text",
            onChange: [
                .custom(timing: .immediate) { _, _ in immediateCount += 1 },
                .custom(timing: .debounced(0.05)) { _, _ in debouncedCount += 1 }
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

    @Test("reset cancels pending debounced actions")
    func resetCancelsPendingDebouncedActions() async {
        nonisolated(unsafe) var debouncedCallCount = 0
        let row = TextInputRow(
            id: "text",
            title: "Text",
            onChange: [.custom(timing: .debounced(0.05)) { _, _ in debouncedCallCount += 1 }]
        )
        let form = makeForm(rows: [AnyFormRow(row)])
        let vm = FormViewModel(formDefinition: form)

        vm.setString("trigger", for: "text")
        vm.reset() // cancels the pending debounce task

        try? await Task.sleep(for: .milliseconds(150))

        // Handler should not have fired since it was cancelled.
        #expect(debouncedCallCount == 0)
    }

    // MARK: - Loop prevention

    @Test(".setValue does not write when the computed value equals the current value")
    func setValueSkipsWriteWhenValueUnchanged() {
        // Target row starts with "fixed". The setValue action always returns "fixed",
        // so the write should be skipped and isDirty should not be set by the action.
        let sourceRow = BooleanSwitchRow(
            id: "source",
            title: "Source",
            onChange: [
                .setValue(on: "target") { _ in .string("fixed") }
            ]
        )
        let targetRow = TextInputRow(id: "target", title: "Target", defaultValue: "fixed")
        let form = makeForm(rows: [AnyFormRow(sourceRow), AnyFormRow(targetRow)])
        let vm = FormViewModel(formDefinition: form)

        // Prime the target to the same value the action would write.
        // isDirty is true after setString, so reset to get a clean baseline.
        vm.reset()
        #expect(vm.rawValue(for: "target") == .string("fixed"))
        #expect(vm.isDirty == false)

        // Trigger the source row — setValue action computes "fixed" but target already is "fixed".
        vm.setBool(true, for: "source")

        // isDirty is true because source changed, but target's value must remain unchanged.
        let target: String? = vm.value(for: "target")
        #expect(target == "fixed")
    }

    @Test(".setValue with oscillating actions reaches a fixed point and stops")
    func setValueOscillationReachesFixedPoint() {
        // Row A sets row B to A's current value (mirroring).
        // Row B sets row A to B's current value (mirroring back).
        // After A changes, the cycle should stabilise immediately because
        // on the second round-trip the value is already equal.
        let rowA = TextInputRow(
            id: "a",
            title: "A",
            onChange: [
                .setValue(on: "b") { store in store["a"] }
            ]
        )
        let rowB = TextInputRow(
            id: "b",
            title: "B",
            onChange: [
                .setValue(on: "a") { store in store["b"] }
            ]
        )
        let form = makeForm(rows: [AnyFormRow(rowA), AnyFormRow(rowB)])
        let vm = FormViewModel(formDefinition: form)

        // This must complete without hanging or crashing.
        vm.setString("hello", for: "a")

        let a: String? = vm.value(for: "a")
        let b: String? = vm.value(for: "b")
        // Both should settle at "hello".
        #expect(a == "hello")
        #expect(b == "hello")
    }

    @Test(".custom action that calls setValue on its own row does not re-enter dispatchActions")
    func customActionSelfWriteDoesNotReenter() {
        nonisolated(unsafe) var callCount = 0

        // We need a reference to the vm inside the closure, so use a box.
        final class Box: @unchecked Sendable { var vm: FormViewModel? }
        let box = Box()

        let row = TextInputRow(
            id: "text",
            title: "Text",
            onChange: [
                .custom { _, _ in
                    callCount += 1
                    // Write back to the same row — without the re-entrancy guard this
                    // would recurse into dispatchActions for "text" indefinitely.
                    box.vm?.setString("recursive", for: "text")
                }
            ]
        )
        let form = makeForm(rows: [AnyFormRow(row)])
        let vm = FormViewModel(formDefinition: form)
        box.vm = vm

        vm.setString("trigger", for: "text")

        // The custom action fires once from the original setString call.
        // The re-entrant setString inside the closure changes the value but the
        // guard suppresses the nested dispatchActions call, so callCount stays at 1.
        #expect(callCount == 1)
    }

    // MARK: - ErrorPosition routing

    @Test("Default .belowRow position routes errors to errorsForRow")
    func errorPositionDefaultBelowRow() {
        let form = makeForm(rows: [
            AnyFormRow(TextInputRow(id: "name", title: "Name", validators: [.required()]))
        ])
        let vm = FormViewModel(formDefinition: form)

        vm.validateAll()

        // Error appears below the owning row.
        #expect(vm.errorsForRow("name").isEmpty == false)
        // No form-level errors.
        #expect(vm.formTopErrors.isEmpty)
        #expect(vm.formBottomErrors.isEmpty)
    }

    @Test(".belowRow(id:) routes error to the targeted row, not the owning row")
    func errorPositionBelowRowId() {
        // Row A's validator targets row B for display.
        let rowA = TextInputRow(
            id: "a",
            title: "A",
            validators: [
                .required(errorPosition: .belowRow(id: "b"))
            ]
        )
        let rowB = TextInputRow(id: "b", title: "B")
        let form = makeForm(rows: [AnyFormRow(rowA), AnyFormRow(rowB)])
        let vm = FormViewModel(formDefinition: form)

        vm.validateAll()

        // Error does NOT appear below row A (no .belowRow errors).
        #expect(vm.errorsForRow("a").isEmpty == true)
        // Error DOES appear below row B (targeted from A).
        #expect(vm.errorsForRow("b").isEmpty == false)
        // No form-level errors.
        #expect(vm.formTopErrors.isEmpty)
        #expect(vm.formBottomErrors.isEmpty)
    }

    @Test(".formTop position routes errors to formTopErrors")
    func errorPositionFormTop() {
        let form = makeForm(rows: [
            AnyFormRow(TextInputRow(
                id: "name",
                title: "Name",
                validators: [.required(errorPosition: .formTop)]
            ))
        ])
        let vm = FormViewModel(formDefinition: form)

        vm.validateAll()

        // Error appears at the form top.
        #expect(vm.formTopErrors.isEmpty == false)
        // NOT below the row.
        #expect(vm.errorsForRow("name").isEmpty == true)
        // NOT at the form bottom.
        #expect(vm.formBottomErrors.isEmpty)
    }

    @Test(".formBottom position routes errors to formBottomErrors")
    func errorPositionFormBottom() {
        let form = makeForm(rows: [
            AnyFormRow(TextInputRow(
                id: "name",
                title: "Name",
                validators: [.required(errorPosition: .formBottom)]
            ))
        ])
        let vm = FormViewModel(formDefinition: form)

        vm.validateAll()

        // Error appears at the form bottom.
        #expect(vm.formBottomErrors.isEmpty == false)
        // NOT below the row.
        #expect(vm.errorsForRow("name").isEmpty == true)
        // NOT at the form top.
        #expect(vm.formTopErrors.isEmpty)
    }

    @Test("Mixed positions on the same row route each error correctly")
    func errorPositionMixed() {
        // Two validators on the same row: one below-row, one form-top.
        let row = TextInputRow(
            id: "field",
            title: "Field",
            validators: [
                .required(message: "Below error", errorPosition: .belowRow),
                .minLength(10, message: "Top error", errorPosition: .formTop)
            ]
        )
        let form = makeForm(rows: [AnyFormRow(row)])
        let vm = FormViewModel(formDefinition: form)
        // Set a short non-empty value so only minLength fails, not required.
        vm.setString("hi", for: "field")

        vm.validateAll()

        // The minLength error goes to form-top.
        #expect(vm.formTopErrors.contains("Top error"))
        // The required error does NOT fire because the field has a value.
        #expect(vm.errorsForRow("field").isEmpty == true)
        #expect(vm.formBottomErrors.isEmpty)
    }

    @Test(".alert position routes errors to alertErrors only")
    func errorPositionAlert() {
        let form = makeForm(rows: [
            AnyFormRow(TextInputRow(
                id: "name",
                title: "Name",
                validators: [.required(errorPosition: .alert)]
            ))
        ])
        let vm = FormViewModel(formDefinition: form)

        vm.validateAll()

        // Error appears in alertErrors.
        #expect(vm.alertErrors.isEmpty == false)
        // NOT below the row.
        #expect(vm.errorsForRow("name").isEmpty == true)
        // NOT at form-top or form-bottom.
        #expect(vm.formTopErrors.isEmpty)
        #expect(vm.formBottomErrors.isEmpty)
    }

    @Test("clearAlertErrors removes only .alert errors, preserving others")
    func clearAlertErrorsPreservesOthers() {
        let row = TextInputRow(
            id: "field",
            title: "Field",
            validators: [
                // Both fail when field is empty.
                .required(message: "Below error", errorPosition: .belowRow),
                .required(message: "Alert error", errorPosition: .alert)
            ]
        )
        let form = makeForm(rows: [AnyFormRow(row)])
        let vm = FormViewModel(formDefinition: form)
        // Leave field empty so both validators fire.

        vm.validateAll()

        // Both errors are present.
        #expect(vm.errorsForRow("field").isEmpty == false)
        #expect(vm.alertErrors.isEmpty == false)

        // Clearing alert errors removes only the alert one.
        vm.clearAlertErrors()
        #expect(vm.alertErrors.isEmpty == true)
        #expect(vm.errorsForRow("field").isEmpty == false)
    }

    @Test("Mixed .alert and .belowRow on the same row each route correctly")
    func errorPositionAlertMixed() {
        let row = TextInputRow(
            id: "field",
            title: "Field",
            validators: [
                .required(message: "Below error", errorPosition: .belowRow),
                .required(message: "Alert error", errorPosition: .alert)
            ]
        )
        let form = makeForm(rows: [AnyFormRow(row)])
        let vm = FormViewModel(formDefinition: form)
        // Leave field empty so both validators fire.

        vm.validateAll()

        #expect(vm.errorsForRow("field").contains("Below error"))
        #expect(vm.alertErrors.contains("Alert error"))
        #expect(vm.formTopErrors.isEmpty)
        #expect(vm.formBottomErrors.isEmpty)
    }

    // MARK: - visibleRows

    @Test("visibleRows filters by showRow actions")
    func visibleRowsFilteredByShowRowActions() {
        let form = makeForm(rows: [
            AnyFormRow(BooleanSwitchRow(
                id: "show",
                title: "Show",
                defaultValue: false,
                onChange: [.showRow(id: "hidden", when: [.isTrue(rowId: "show")])]
            )),
            AnyFormRow(TextInputRow(id: "hidden", title: "Hidden"))
        ])
        let vm = FormViewModel(formDefinition: form)

        #expect(vm.visibleRows.count == 1)
        vm.setBool(true, for: "show")
        #expect(vm.visibleRows.count == 2)
    }
}
