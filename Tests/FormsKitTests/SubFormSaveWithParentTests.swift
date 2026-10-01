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
}
