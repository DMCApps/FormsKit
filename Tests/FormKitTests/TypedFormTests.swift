@testable import FormKit
import Testing

// MARK: - Test Row ID Enums

private enum SettingsRowID: String, Sendable {
    case username
    case email
    case notifications
    case count
    case score
    case tags
}

/// Used for MultiValueRow tests — requires CaseIterable and supporting protocols.
private enum TagOption: String, CaseIterable, CustomStringConvertible, Hashable, Sendable, Codable {
    case ios, swift, android
    var description: String { rawValue }
}

private enum TagRowID: String, Sendable {
    case tags
}

// MARK: - TypedFormDefinition Tests

@Suite("TypedFormDefinition")
struct TypedFormDefinitionTests {
    @Test("Builder DSL produces correct definition")
    func builderDSLProducesDefinition() {
        let form = TypedFormDefinition<SettingsRowID>(
            id: "settings",
            title: "Settings",
            saveBehaviour: .onChange
        ) {
            TextInputRow(id: SettingsRowID.username.rawValue, title: "Username")
            BooleanSwitchRow(id: SettingsRowID.notifications.rawValue, title: "Notifications")
        }

        #expect(form.definition.id == "settings")
        #expect(form.definition.title == "Settings")
        #expect(form.definition.rows.count == 2)
        if case .onChange = form.definition.saveBehaviour {
            // correct
        } else {
            Issue.record("Expected .onChange saveBehaviour")
        }
    }

    @Test("Array-based init produces correct definition")
    func arrayInitProducesDefinition() {
        let rows: [AnyFormRow] = [
            AnyFormRow(TextInputRow(id: SettingsRowID.email.rawValue, title: "Email"))
        ]
        let form = TypedFormDefinition<SettingsRowID>(
            id: "profile",
            title: "Profile",
            rows: rows,
            saveBehaviour: .buttonNavigationBar(title: "Save")
        )

        #expect(form.definition.id == "profile")
        #expect(form.definition.rows.count == 1)
        if case let .buttonNavigationBar(title) = form.definition.saveBehaviour {
            #expect(title == "Save")
        } else {
            Issue.record("Expected .buttonNavigationBar saveBehaviour")
        }
    }

    @Test("Default saveBehaviour is .buttonBottomForm")
    func defaultSaveBehaviourIsButtonBottomForm() {
        let form = TypedFormDefinition<SettingsRowID>(id: "x", title: "X") {
            BooleanSwitchRow(id: SettingsRowID.notifications.rawValue, title: "N")
        }
        if case .buttonBottomForm = form.definition.saveBehaviour {
            // correct
        } else {
            Issue.record("Expected default .buttonBottomForm saveBehaviour")
        }
    }

    @Test("definition is accessible for use with DynamicFormView")
    func definitionIsPubliclyAccessible() {
        let form = TypedFormDefinition<SettingsRowID>(id: "test", title: "Test") { }
        // Verify we can use .definition where FormDefinition is expected.
        let def: FormDefinition = form.definition
        #expect(def.id == "test")
    }

    @Test("Persistence is threaded to definition")
    func persistenceThreadedToDefinition() {
        let persistence = FormPersistenceMemory()
        let form = TypedFormDefinition<SettingsRowID>(
            id: "p",
            title: "P",
            persistence: persistence
        ) { }
        // Underlying definition should hold the same persistence instance.
        #expect(form.definition.persistence != nil)
    }
}

// MARK: - TypedFormViewModel Tests

@Suite("TypedFormViewModel")
struct TypedFormViewModelTests {
    private func makeTypedForm(saveBehaviour: FormSaveBehaviour = .buttonBottomForm(),
                               persistence: (any FormPersistence)? = nil) -> TypedFormDefinition<SettingsRowID> {
        TypedFormDefinition<SettingsRowID>(
            id: "typed-test",
            title: "Typed Test",
            persistence: persistence,
            saveBehaviour: saveBehaviour
        ) {
            TextInputRow(id: SettingsRowID.username.rawValue, title: "Username", defaultValue: "alice")
            BooleanSwitchRow(id: SettingsRowID.notifications.rawValue, title: "Notifications", defaultValue: true)
            NumberInputRow(id: SettingsRowID.count.rawValue, title: "Count", kind: .int(defaultValue: nil))
            NumberInputRow(id: SettingsRowID.score.rawValue, title: "Score", kind: .decimal(defaultValue: nil))
        }
    }

    // MARK: - Typed value read/write

    @Test("Enum-typed value read returns row default")
    func enumTypedReadReturnsDefault() {
        let form = makeTypedForm()
        let vm = TypedFormViewModel(form: form)

        let username: String? = vm.value(for: .username)
        let notifications: Bool? = vm.value(for: .notifications)

        #expect(username == "alice")
        #expect(notifications == true)
    }

    @Test("Enum-typed value write and read round-trip")
    func enumTypedWriteReadRoundTrip() {
        let form = makeTypedForm()
        let vm = TypedFormViewModel(form: form)

        vm.setString("bob", for: .username)
        vm.setBool(false, for: .notifications)
        vm.setInt(42, for: .count)
        vm.setDouble(9.9, for: .score)

        let username: String? = vm.value(for: .username)
        let notifications: Bool? = vm.value(for: .notifications)
        let count: Int? = vm.value(for: .count)
        let score: Double? = vm.value(for: .score)

        #expect(username == "bob")
        #expect(notifications == false)
        #expect(count == 42)
        #expect(score == 9.9)
    }

    @Test("rawValue(for:) returns the AnyCodableValue")
    func rawValueForEnumID() {
        let form = makeTypedForm()
        let vm = TypedFormViewModel(form: form)

        vm.setString("charlie", for: .username)
        let raw = vm.rawValue(for: .username)
        #expect(raw == .string("charlie"))
    }

    @Test("toggleArrayValue adds and removes elements")
    func toggleArrayValueAddsAndRemoves() {
        let form = TypedFormDefinition<TagRowID>(id: "t", title: "T") {
            MultiValueRow<TagOption>(id: TagRowID.tags.rawValue, title: "Tags")
        }
        let vm = TypedFormViewModel(form: form)

        vm.toggleArrayValue(.string("ios"), for: .tags)
        #expect(vm.rawValue(for: .tags) == .array([.string("ios")]))

        vm.toggleArrayValue(.string("swift"), for: .tags)
        #expect(vm.rawValue(for: .tags) == .array([.string("ios"), .string("swift")]))

        vm.toggleArrayValue(.string("ios"), for: .tags)
        #expect(vm.rawValue(for: .tags) == .array([.string("swift")]))
    }

    // MARK: - Validation

    @Test("validateAll returns false for missing required field")
    func validateAllFailsForRequired() {
        let form = TypedFormDefinition<SettingsRowID>(id: "v", title: "V") {
            TextInputRow(id: SettingsRowID.email.rawValue, title: "Email", validators: [.required()])
        }
        let vm = TypedFormViewModel(form: form)

        let valid = vm.validateAll()
        #expect(valid == false)
        #expect(vm.errorsForRow(.email).isEmpty == false)
    }

    @Test("rowHasError returns true when errors exist")
    func rowHasErrorReturnsTrueWhenErrors() {
        let form = TypedFormDefinition<SettingsRowID>(id: "v", title: "V") {
            TextInputRow(id: SettingsRowID.email.rawValue, title: "Email", validators: [.required()])
        }
        let vm = TypedFormViewModel(form: form)
        vm.validateAll()

        #expect(vm.rowHasError(.email) == true)
    }

    // MARK: - Save

    @Test("save() returns true with no persistence")
    func saveReturnsTrueNoPersistence() async {
        let form = makeTypedForm()
        let vm = TypedFormViewModel(form: form)
        let result = await vm.save()
        #expect(result == true)
    }

    @Test("save() with memory persistence persists values")
    func saveWithMemoryPersistence() async {
        let persistence = FormPersistenceMemory()
        let form = makeTypedForm(persistence: persistence)
        let vm = TypedFormViewModel(form: form)

        vm.setString("dave", for: .username)
        let saved = await vm.save()
        #expect(saved == true)

        // Reload via a fresh vm.
        let vm2 = TypedFormViewModel(form: form, persistence: persistence)
        await vm2.loadFromPersistence()
        let username: String? = vm2.value(for: .username)
        #expect(username == "dave")
    }

    // MARK: - onSave closure

    @Test("onSave closure fires after successful save")
    func onSaveClosureFiresAfterSave() async {
        let form = makeTypedForm()
        var capturedValues: FormValueStore?
        let vm = TypedFormViewModel(form: form, onSave: { values in
            capturedValues = values
        })

        vm.setString("eve", for: .username)
        let result = await vm.save()

        #expect(result == true)
        #expect(capturedValues != nil)
        let username: String? = capturedValues?.value(for: SettingsRowID.username.rawValue)
        #expect(username == "eve")
    }

    @Test("onSave closure does NOT fire when validation fails")
    func onSaveClosureDoesNotFireOnFailure() async {
        let form = TypedFormDefinition<SettingsRowID>(id: "fail", title: "Fail") {
            TextInputRow(id: SettingsRowID.email.rawValue, title: "Email", validators: [.required()])
        }
        var called = false
        let vm = TypedFormViewModel(form: form, onSave: { _ in called = true })

        let result = await vm.save()

        #expect(result == false)
        #expect(called == false)
    }

    @Test("onSave closure from TypedFormDefinition init is forwarded to FormViewModel")
    func onSaveFromFormDefInitIsForwarded() async {
        let form = makeTypedForm()
        var called = false
        // Create using the formDefinition-based init.
        let vm = TypedFormViewModel<SettingsRowID>(formDefinition: form.definition, onSave: { _ in
            called = true
        })

        vm.setString("frank", for: .username)
        await vm.save()

        #expect(called == true)
    }

    // MARK: - Reset

    @Test("reset restores row defaults")
    func resetRestoresDefaults() {
        let form = makeTypedForm()
        let vm = TypedFormViewModel(form: form)

        vm.setString("modified", for: .username)
        vm.setBool(false, for: .notifications)
        vm.reset()

        let username: String? = vm.value(for: .username)
        let notifications: Bool? = vm.value(for: .notifications)

        #expect(username == "alice")
        #expect(notifications == true)
    }

    // MARK: - saveBehaviour threading

    @Test("saveBehaviour is threaded from TypedFormDefinition to FormViewModel")
    func saveBehaviourThreaded() {
        let form = TypedFormDefinition<SettingsRowID>(
            id: "sb",
            title: "SB",
            saveBehaviour: .onChange
        ) {
            BooleanSwitchRow(id: SettingsRowID.notifications.rawValue, title: "N")
        }
        let vm = TypedFormViewModel(form: form)

        if case .onChange = vm.viewModel.formDefinition.saveBehaviour {
            // correct
        } else {
            Issue.record("Expected .onChange saveBehaviour on inner FormViewModel")
        }
    }

    @Test("viewModel property exposes the inner FormViewModel")
    func viewModelPropertyExposesInnerVM() {
        let form = makeTypedForm()
        let vm = TypedFormViewModel(form: form)

        // We should be able to access FormViewModel state directly.
        #expect(vm.viewModel.isDirty == false)
        vm.setBool(false, for: .notifications)
        #expect(vm.viewModel.isDirty == true)
    }

    // MARK: - clearPersistence

    @Test("clearPersistence removes stored values")
    func clearPersistenceRemovesValues() async throws {
        let persistence = FormPersistenceMemory()
        let form = makeTypedForm(persistence: persistence)
        let vm = TypedFormViewModel(form: form)

        vm.setString("grace", for: .username)
        await vm.save()

        await vm.clearPersistence()

        let loaded = try await persistence.load(formId: "typed-test")
        #expect(loaded.isEmpty == true)
    }
}
