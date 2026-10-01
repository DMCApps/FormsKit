@testable import FormsKit
import Foundation
import Testing

// MARK: - Test Support

/// Collects events on the main actor so persists and onSave calls land on one timeline.
@MainActor
final class OrderLog {
    var events: [String] = []
    func add(_ event: String) { events.append(event) }
}

enum SpyError: Error, LocalizedError {
    case failed
    var errorDescription: String? { "Simulated persistence failure" }
}

/// A persistence backend shared across a family of forms, keyed by formId, that records
/// save order into a shared `OrderLog`.
actor SpyPersistence: FormPersistence {
    let log: OrderLog
    var failingFormIds: Set<String>
    var stored: [String: FormValueStore] = [:]

    init(log: OrderLog, failing: Set<String> = []) {
        self.log = log
        failingFormIds = failing
    }

    func save(_ values: FormValueStore, formId: String) async throws {
        if failingFormIds.contains(formId) { throw SpyError.failed }
        stored[formId] = values
        await log.add("persist:\(formId)")
    }

    func load(formId: String) async throws -> FormValueStore {
        stored[formId] ?? FormValueStore()
    }

    func clear(formId: String) async throws {
        stored[formId] = nil
    }
}

/// Persistence whose `load` always throws, used to drive a child into `.loadFailed`.
private struct LoadFailingPersistence: FormPersistence {
    func save(_ values: FormValueStore, formId: String) async throws {}
    func load(formId: String) async throws -> FormValueStore { throw SpyError.failed }
    func clear(formId: String) async throws {}
}

private enum ChildRowID: String { case name }

// MARK: - SubFormSaveWithParent Tests

@MainActor
@Suite("SubFormSaveWithParent")
struct SubFormSaveWithParentTests {
    // MARK: Phase 1 — model and ownership

    @Test("A .withParent destination gets a child view model")
    func childViewModelCreatedForWithParentDestination() {
        let child = FormDefinition(
            id: "child",
            title: "Child",
            rows: [AnyFormRow(TextInputRow(id: "name", title: "Name"))],
            saveBehaviour: .withParent
        )
        let parent = FormDefinition(
            id: "parent",
            title: "Parent",
            rows: [AnyFormRow(NavigationRow(id: "nav", title: "Nav", destination: child))]
        )
        let vm = FormViewModel(formDefinition: parent)

        #expect(vm.childViewModel(for: "nav") != nil)
    }

    @Test("Child view model identity is stable across repeated lookups")
    func childViewModelIdentityIsStable() {
        let child = FormDefinition(
            id: "child",
            title: "Child",
            rows: [AnyFormRow(TextInputRow(id: "name", title: "Name"))],
            saveBehaviour: .withParent
        )
        let parent = FormDefinition(
            id: "parent",
            title: "Parent",
            rows: [AnyFormRow(NavigationRow(id: "nav", title: "Nav", destination: child))]
        )
        let vm = FormViewModel(formDefinition: parent)

        let first = vm.childViewModel(for: "nav")
        let second = vm.childViewModel(for: "nav")
        #expect(first === second)
    }

    @Test("A non-deferring NavigationRow has no child view model")
    func nonDeferringNavigationRowHasNoChild() {
        let child = FormDefinition(
            id: "child",
            title: "Child",
            rows: [AnyFormRow(TextInputRow(id: "name", title: "Name"))]
        )
        let parent = FormDefinition(
            id: "parent",
            title: "Parent",
            rows: [AnyFormRow(NavigationRow(id: "nav", title: "Nav", destination: child))]
        )
        let vm = FormViewModel(formDefinition: parent)

        #expect(vm.childViewModel(for: "nav") == nil)
    }

    @Test("A grandchild is reachable through the child's own childViewModel(for:)")
    func grandchildReachableThroughChild() {
        let grandchild = FormDefinition(
            id: "grandchild",
            title: "Grandchild",
            rows: [AnyFormRow(TextInputRow(id: "name", title: "Name"))],
            saveBehaviour: .withParent
        )
        let child = FormDefinition(
            id: "child",
            title: "Child",
            rows: [AnyFormRow(NavigationRow(id: "navGrandchild", title: "Nav", destination: grandchild))],
            saveBehaviour: .withParent
        )
        let parent = FormDefinition(
            id: "parent",
            title: "Parent",
            rows: [AnyFormRow(NavigationRow(id: "navChild", title: "Nav", destination: child))]
        )
        let vm = FormViewModel(formDefinition: parent)

        let childVM = vm.childViewModel(for: "navChild")
        #expect(childVM != nil)
        #expect(childVM?.childViewModel(for: "navGrandchild") != nil)
    }

    @Test("The RawRepresentable overload returns the same instance as the String version")
    func rawRepresentableOverloadReturnsSameInstance() {
        let child = FormDefinition(
            id: "child",
            title: "Child",
            rows: [AnyFormRow(TextInputRow(id: ChildRowID.name, title: "Name"))],
            saveBehaviour: .withParent
        )
        enum ParentRowID: String { case nav }
        let parent = FormDefinition(
            id: "parent",
            title: "Parent",
            rows: [AnyFormRow(NavigationRow(id: ParentRowID.nav, title: "Nav", destination: child))]
        )
        let vm = FormViewModel(formDefinition: parent)

        let byString = vm.childViewModel(for: "nav")
        let byEnum = vm.childViewModel(for: ParentRowID.nav)
        #expect(byString === byEnum)
    }

    // MARK: Phase 2 — dirty, reset, clear, awaitReady

    private func makeParentWithChild(childPersistence: (any FormPersistence)? = nil,
                                      parentPersistence: (any FormPersistence)? = nil) -> (parent: FormViewModel, child: FormViewModel) {
        let child = FormDefinition(
            id: "child",
            title: "Child",
            rows: [AnyFormRow(TextInputRow(id: "name", title: "Name", defaultValue: "default"))],
            persistence: childPersistence,
            saveBehaviour: .withParent
        )
        let parent = FormDefinition(
            id: "parent",
            title: "Parent",
            rows: [AnyFormRow(NavigationRow(id: "nav", title: "Nav", destination: child))],
            persistence: parentPersistence
        )
        let vm = FormViewModel(formDefinition: parent)
        return (vm, vm.childViewModel(for: "nav")!)
    }

    @Test("An edit in the child makes the parent dirty")
    func childEditMakesParentDirty() async {
        let (parent, child) = makeParentWithChild()
        await parent.awaitReady()

        #expect(parent.isDirty == false)
        child.setString("changed", for: "name")
        #expect(parent.isDirty == true)
    }

    @Test("reset() cascades to the child")
    func resetCascadesToChild() async {
        let (parent, child) = makeParentWithChild()
        await parent.awaitReady()

        child.setString("changed", for: "name")
        #expect(parent.isDirty == true)

        parent.reset()
        await parent.awaitReady()

        let name: String? = child.value(for: "name")
        #expect(name == "default")
        #expect(parent.isDirty == false)
    }

    @Test("clearPersistence() cascades to the child")
    func clearPersistenceCascadesToChild() async {
        let log = OrderLog()
        let childPersistence = SpyPersistence(log: log)
        let (parent, _) = makeParentWithChild(childPersistence: childPersistence)
        await parent.awaitReady()

        try? await childPersistence.save(FormValueStore(), formId: "child")
        var stored = await childPersistence.stored
        #expect(stored["child"] != nil)

        await parent.clearPersistence()
        stored = await childPersistence.stored
        #expect(stored["child"] == nil)
    }

    // MARK: Phase 3 — save cascade

    @Test("A child edit is persisted only after the parent's save()")
    func childEditPersistedOnlyAfterParentSave() async {
        let log = OrderLog()
        let persistence = SpyPersistence(log: log)
        let child = FormDefinition(
            id: "child",
            title: "Child",
            rows: [AnyFormRow(TextInputRow(id: "name", title: "Name"))],
            persistence: persistence,
            saveBehaviour: .withParent
        )
        let parent = FormDefinition(
            id: "parent",
            title: "Parent",
            rows: [AnyFormRow(NavigationRow(id: "nav", title: "Nav", destination: child))],
            persistence: persistence
        )
        let vm = FormViewModel(formDefinition: parent)
        await vm.awaitReady()

        let childVM = vm.childViewModel(for: "nav")!
        childVM.setString("edited", for: "name")

        var stored = await persistence.stored
        #expect(stored["child"] == nil)

        let result = await vm.save()

        #expect(result == true)
        stored = await persistence.stored
        #expect(stored["child"] != nil)
    }

    @Test("Persist order is child then parent; onSave order is child then parent")
    func persistAndOnSaveOrderIsChildThenParent() async {
        let log = OrderLog()
        let persistence = SpyPersistence(log: log)
        let child = FormDefinition(
            id: "child",
            title: "Child",
            rows: [AnyFormRow(TextInputRow(id: "name", title: "Name"))],
            persistence: persistence,
            saveBehaviour: .withParent,
            onSave: [FormSaveAction { _ in log.add("onSave:child") }]
        )
        let parent = FormDefinition(
            id: "parent",
            title: "Parent",
            rows: [AnyFormRow(NavigationRow(id: "nav", title: "Nav", destination: child))],
            persistence: persistence,
            onSave: [FormSaveAction { _ in log.add("onSave:parent") }]
        )
        let vm = FormViewModel(formDefinition: parent)
        await vm.awaitReady()

        let result = await vm.save()

        #expect(result == true)
        #expect(log.events == ["persist:child", "persist:parent", "onSave:child", "onSave:parent"])
    }

    @Test("An invalid child blocks the save and names itself in saveError")
    func invalidChildBlocksSave() async {
        let log = OrderLog()
        let persistence = SpyPersistence(log: log)
        let child = FormDefinition(
            id: "child",
            title: "Child Screen",
            rows: [AnyFormRow(TextInputRow(id: "name", title: "Name", validators: [.required()]))],
            persistence: persistence,
            saveBehaviour: .withParent
        )
        let parent = FormDefinition(
            id: "parent",
            title: "Parent",
            rows: [AnyFormRow(NavigationRow(id: "nav", title: "Nav", destination: child))],
            persistence: persistence
        )
        let vm = FormViewModel(formDefinition: parent)
        await vm.awaitReady()

        let result = await vm.save()

        #expect(result == false)
        #expect(log.events.isEmpty)
        #expect(vm.saveError?.localizedDescription.contains("Child Screen") == true)
    }

    @Test("A child persistence failure blocks the parent save and leaves it dirty")
    func childPersistenceFailureBlocksSave() async {
        let log = OrderLog()
        let persistence = SpyPersistence(log: log, failing: ["child"])
        let child = FormDefinition(
            id: "child",
            title: "Child",
            rows: [AnyFormRow(TextInputRow(id: "name", title: "Name"))],
            persistence: persistence,
            saveBehaviour: .withParent,
            onSave: [FormSaveAction { _ in log.add("onSave:child") }]
        )
        let parent = FormDefinition(
            id: "parent",
            title: "Parent",
            rows: [AnyFormRow(NavigationRow(id: "nav", title: "Nav", destination: child))],
            persistence: persistence,
            onSave: [FormSaveAction { _ in log.add("onSave:parent") }]
        )
        let vm = FormViewModel(formDefinition: parent)
        await vm.awaitReady()

        let childVM = vm.childViewModel(for: "nav")!
        childVM.setString("edited", for: "name")

        let result = await vm.save()

        #expect(result == false)
        #expect(!log.events.contains("persist:parent"))
        #expect(!log.events.contains("onSave:parent"))
        #expect(vm.saveError != nil)
        #expect(vm.isDirty == true)
    }

    @Test("Parent isDirty is true after a child edit and false after a successful save")
    func parentIsDirtyTracksChildEditThenClearsOnSave() async {
        let log = OrderLog()
        let persistence = SpyPersistence(log: log)
        let (parent, child) = makeParentWithChild(childPersistence: persistence, parentPersistence: persistence)
        await parent.awaitReady()

        #expect(parent.isDirty == false)
        child.setString("changed", for: "name")
        #expect(parent.isDirty == true)

        let result = await parent.save()

        #expect(result == true)
        #expect(parent.isDirty == false)
        #expect(child.isDirty == false)
    }

    @Test("Grandchild persists before child before parent")
    func saveCascadesThroughGrandchild() async {
        let log = OrderLog()
        let persistence = SpyPersistence(log: log)
        let grandchild = FormDefinition(
            id: "grandchild",
            title: "Grandchild",
            rows: [AnyFormRow(TextInputRow(id: "name", title: "Name"))],
            persistence: persistence,
            saveBehaviour: .withParent
        )
        let child = FormDefinition(
            id: "child",
            title: "Child",
            rows: [AnyFormRow(NavigationRow(id: "navGrandchild", title: "Nav", destination: grandchild))],
            persistence: persistence,
            saveBehaviour: .withParent
        )
        let parent = FormDefinition(
            id: "parent",
            title: "Parent",
            rows: [AnyFormRow(NavigationRow(id: "navChild", title: "Nav", destination: child))],
            persistence: persistence
        )
        let vm = FormViewModel(formDefinition: parent)
        await vm.awaitReady()

        let result = await vm.save()

        #expect(result == true)
        #expect(log.events == ["persist:grandchild", "persist:child", "persist:parent"])
    }

    @Test("An invalid grandchild blocks the save")
    func invalidGrandchildBlocksSave() async {
        let log = OrderLog()
        let persistence = SpyPersistence(log: log)
        let grandchild = FormDefinition(
            id: "grandchild",
            title: "Grandchild",
            rows: [AnyFormRow(TextInputRow(id: "name", title: "Name", validators: [.required()]))],
            persistence: persistence,
            saveBehaviour: .withParent
        )
        let child = FormDefinition(
            id: "child",
            title: "Child",
            rows: [AnyFormRow(NavigationRow(id: "navGrandchild", title: "Nav", destination: grandchild))],
            persistence: persistence,
            saveBehaviour: .withParent
        )
        let parent = FormDefinition(
            id: "parent",
            title: "Parent",
            rows: [AnyFormRow(NavigationRow(id: "navChild", title: "Nav", destination: child))],
            persistence: persistence
        )
        let vm = FormViewModel(formDefinition: parent)
        await vm.awaitReady()

        let result = await vm.save()

        #expect(result == false)
        #expect(log.events.isEmpty)
    }

    @Test("A non-deferring NavigationRow's destination is not persisted by the parent's save")
    func nonDeferringDestinationNotPersistedByParent() async {
        let log = OrderLog()
        let persistence = SpyPersistence(log: log)
        let destination = FormDefinition(
            id: "destination",
            title: "Destination",
            rows: [AnyFormRow(TextInputRow(id: "name", title: "Name"))],
            persistence: persistence
        )
        let parent = FormDefinition(
            id: "parent",
            title: "Parent",
            rows: [AnyFormRow(NavigationRow(id: "nav", title: "Nav", destination: destination))],
            persistence: persistence
        )
        let vm = FormViewModel(formDefinition: parent)
        await vm.awaitReady()

        #expect(vm.childViewModel(for: "nav") == nil)

        let result = await vm.save()

        #expect(result == true)
        let stored = await persistence.stored
        #expect(stored["destination"] == nil)
        #expect(stored["parent"] != nil)
    }

    @Test("A hidden nav row's invalid child doesn't block save, and its values still persist")
    func hiddenInvalidChildDoesNotBlockSave() async {
        let log = OrderLog()
        let persistence = SpyPersistence(log: log)
        let child = FormDefinition(
            id: "child",
            title: "Child",
            rows: [AnyFormRow(TextInputRow(id: "name", title: "Name", validators: [.required()]))],
            persistence: persistence,
            saveBehaviour: .withParent
        )
        let parent = FormDefinition(
            id: "parent",
            title: "Parent",
            rows: [
                AnyFormRow(BooleanSwitchRow(
                    id: "toggle",
                    title: "Toggle",
                    onChange: [.hideRow(id: "nav", when: [.equals(rowId: "toggle", bool: true)])]
                )),
                AnyFormRow(NavigationRow(id: "nav", title: "Nav", destination: child))
            ],
            persistence: persistence
        )
        let vm = FormViewModel(formDefinition: parent)
        await vm.awaitReady()

        vm.setBool(true, for: "toggle")
        #expect(vm.visibleRows.contains { $0.id == "nav" } == false)

        let result = await vm.save()

        #expect(result == true)
        let stored = await persistence.stored
        #expect(stored["child"] != nil)
    }

    @Test("A child stuck in .loadFailed makes the parent's save() return false")
    func childLoadFailedBlocksSave() async {
        let child = FormDefinition(
            id: "child",
            title: "Child",
            rows: [AnyFormRow(TextInputRow(id: "name", title: "Name"))],
            persistence: LoadFailingPersistence(),
            saveBehaviour: .withParent
        )
        let parent = FormDefinition(
            id: "parent",
            title: "Parent",
            rows: [AnyFormRow(NavigationRow(id: "nav", title: "Nav", destination: child))]
        )
        let vm = FormViewModel(formDefinition: parent)
        await vm.awaitReady()

        let childVM = vm.childViewModel(for: "nav")!
        #expect(childVM.status.isLoadFailed == true)

        let result = await vm.save()
        #expect(result == false)
    }
}
