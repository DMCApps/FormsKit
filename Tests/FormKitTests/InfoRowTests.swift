@testable import FormKit
import Testing

// MARK: - InfoRow Tests

@Suite("InfoRow")
struct InfoRowTests {
    // MARK: - Construction

    @Test("InfoRow stores id and title")
    func infoRowStoresIdAndTitle() {
        let row = InfoRow(id: "my-info", title: "My Label", value: { "some value" })
        #expect(row.id == "my-info")
        #expect(row.title == "My Label")
    }

    @Test("InfoRow value closure is evaluated at call time")
    func infoRowValueClosureEvaluatedAtCallTime() {
        nonisolated(unsafe) var counter = 0
        let row = InfoRow(id: "counter", title: "Counter", value: {
            counter += 1
            return "call \(counter)"
        })
        #expect(row.value() == "call 1")
        #expect(row.value() == "call 2")
        #expect(counter == 2)
    }

    @Test("InfoRow value closure captures mutable state")
    func infoRowValueClosureCapturesMutableState() {
        nonisolated(unsafe) var state = "initial"
        let row = InfoRow(id: "state", title: "State", value: { state })
        #expect(row.value() == "initial")
        state = "updated"
        #expect(row.value() == "updated")
    }

    @Test("InfoRow RawRepresentable id overload")
    func infoRowRawRepresentableId() {
        enum RowID: String { case token = "privacy_token" }
        let row = InfoRow(id: RowID.token, title: "Token", value: { "abc123" })
        #expect(row.id == "privacy_token")
        #expect(row.value() == "abc123")
    }

    // MARK: - FormRow protocol defaults

    @Test("InfoRow has nil subtitle")
    func infoRowHasNilSubtitle() {
        let row = InfoRow(id: "r", title: "T", value: { "" })
        #expect(row.subtitle == nil)
    }

    @Test("InfoRow has no onChange actions")
    func infoRowHasNoOnChangeActions() {
        let row = InfoRow(id: "r", title: "T", value: { "" })
        #expect(row.onChange.isEmpty)
    }

    @Test("InfoRow has no validators")
    func infoRowHasNoValidators() {
        let row = InfoRow(id: "r", title: "T", value: { "" })
        #expect(row.validators.isEmpty)
    }

    @Test("InfoRow has nil defaultValue")
    func infoRowHasNilDefaultValue() {
        let row = InfoRow(id: "r", title: "T", value: { "" })
        #expect(row.defaultValue == nil)
    }

    // MARK: - AnyFormRow wrapping

    @Test("AnyFormRow wraps InfoRow and casts back correctly")
    func anyFormRowWrapsInfoRow() {
        let row = InfoRow(id: "info", title: "Status", value: { "ok" })
        let anyRow = AnyFormRow(row)
        let cast = anyRow.asType(InfoRow.self)
        #expect(cast != nil)
        #expect(cast?.id == "info")
        #expect(cast?.title == "Status")
        #expect(cast?.value() == "ok")
    }

    @Test("AnyFormRow wrapping InfoRow carries id and title")
    func anyFormRowInfoRowCarriesMetadata() {
        let row = InfoRow(id: "meta", title: "Meta", value: { "v" })
        let anyRow = AnyFormRow(row)
        #expect(anyRow.id == "meta")
        #expect(anyRow.title == "Meta")
    }

    @Test("InfoRow does not appear in FormViewModel value store")
    func infoRowNotInValueStore() {
        let form = FormDefinition(
            id: "test",
            title: "Test",
            rows: [AnyFormRow(InfoRow(id: "status", title: "Status", value: { "ok" }))]
        )
        let vm = FormViewModel(formDefinition: form)
        let value: String? = vm.value(for: "status")
        #expect(value == nil)
    }
}

// MARK: - FormSaveBehaviour.none Tests

@Suite("FormSaveBehaviour.none")
struct FormSaveBehaviourNoneTests {
    @Test("saveBehaviour .none is stored on FormDefinition")
    func saveBehaviourNoneStored() {
        let form = FormDefinition(id: "test", title: "Test", rows: [], saveBehaviour: .none)
        #expect({
            if case .none = form.saveBehaviour { return true }
            return false
        }())
    }

    @Test("FormSaveBehaviour.none saveButtonTitle returns nil")
    func saveBehaviourNoneSaveButtonTitleIsNil() {
        #expect(FormSaveBehaviour.none.saveButtonTitle == nil)
    }

    @Test("setValue with .none saveBehaviour does NOT auto-save")
    func setValueWithNoneBehaviourDoesNotAutoSave() async {
        let persistence = FormPersistenceMemory()
        let form = FormDefinition(
            id: "test",
            title: "Test",
            rows: [AnyFormRow(BooleanSwitchRow(id: "flag", title: "Flag"))],
            persistence: persistence,
            saveBehaviour: .none
        )
        let vm = FormViewModel(formDefinition: form)

        vm.setBool(true, for: "flag")

        // Allow a tick for any Task to run
        await Task.yield()
        await Task.yield()

        let stored = try? await persistence.load(formId: "test")
        #expect(stored?["flag"] == nil)
    }

    @Test("FormSaveBehaviour.none can be used with InfoRow-only form")
    func noneWithInfoRowOnlyForm() {
        let form = FormDefinition(
            id: "info-only",
            title: "Info",
            saveBehaviour: .none
        ) {
            FormSection(id: "status", title: "Status") {
                InfoRow(id: "status-value", title: "Value", value: { "ok" })
            }
        }
        #expect({
            if case .none = form.saveBehaviour { return true }
            return false
        }())
        #expect(form.rows.count == 1)
    }
}
