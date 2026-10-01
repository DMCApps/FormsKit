@testable import FormsKit
import Testing

// MARK: - Test Row ID Enums

private enum SettingsRowID: String {
    case username
    case email
    case notifications
    case count
    case score
    case tags
    case section
}

private enum TagOption: String, CaseIterable, CustomStringConvertible, Hashable, Sendable, Codable {
    case ios, swift, android
    var description: String { rawValue }
}

/// A String-backed enum used to test storing and retrieving enum *values* (not row IDs).
private enum Theme: String, Codable, Sendable { case light, dark, system }

// MARK: - FormViewModel RawRepresentable Overload Tests

@Suite("FormViewModel RawRepresentable overloads")
@MainActor
struct FormViewModelRawRepresentableTests {
    private func makeViewModel() -> FormViewModel {
        let form = FormDefinition(id: "typed-test", title: "Typed Test") {
            TextInputRow(id: SettingsRowID.username, title: "Username", defaultValue: "alice")
            TextInputRow(id: SettingsRowID.email, title: "Email", validators: [.required()])
            BooleanSwitchRow(id: SettingsRowID.notifications, title: "Notifications", defaultValue: true)
            NumberInputRow(id: SettingsRowID.count, title: "Count", kind: .int(defaultValue: nil))
            NumberInputRow(id: SettingsRowID.score, title: "Score", kind: .decimal(defaultValue: nil))
            MultiValueRow<TagOption>(id: SettingsRowID.tags, title: "Tags")
        }
        return FormViewModel(formDefinition: form)
    }

    @Test("Enum row ID read returns row default")
    func enumReadReturnsDefault() {
        let vm = makeViewModel()

        let username: String? = vm.value(for: SettingsRowID.username)
        let notifications: Bool? = vm.value(for: SettingsRowID.notifications)

        #expect(username == "alice")
        #expect(notifications == true)
    }

    @Test("Enum row ID write and read round-trip")
    func enumWriteReadRoundTrip() {
        let vm = makeViewModel()

        vm.setString("bob", for: SettingsRowID.username)
        vm.setBool(false, for: SettingsRowID.notifications)
        vm.setInt(42, for: SettingsRowID.count)
        vm.setDouble(9.9, for: SettingsRowID.score)

        let username: String? = vm.value(for: SettingsRowID.username)
        let notifications: Bool? = vm.value(for: SettingsRowID.notifications)
        let count: Int? = vm.value(for: SettingsRowID.count)
        let score: Double? = vm.value(for: SettingsRowID.score)

        #expect(username == "bob")
        #expect(notifications == false)
        #expect(count == 42)
        #expect(score == 9.9)
    }

    @Test("Custom enum value round-trips via setValue/value(for:)")
    func enumValueRoundTrip() {
        let vm = makeViewModel()

        vm.setValue(AnyCodableValue.from(Theme.dark), for: SettingsRowID.username)
        let result: Theme? = vm.value(for: SettingsRowID.username)
        #expect(result == .dark)
    }

    @Test("rawValue(for:) returns the AnyCodableValue")
    func rawValueForEnumID() {
        let vm = makeViewModel()

        vm.setString("charlie", for: SettingsRowID.username)
        #expect(vm.rawValue(for: SettingsRowID.username) == .string("charlie"))
    }

    @Test("toggleArrayValue adds and removes elements")
    func toggleArrayValueAddsAndRemoves() {
        let vm = makeViewModel()

        vm.toggleArrayValue(.string("ios"), for: SettingsRowID.tags)
        #expect(vm.rawValue(for: SettingsRowID.tags) == .array([.string("ios")]))

        vm.toggleArrayValue(.string("swift"), for: SettingsRowID.tags)
        #expect(vm.rawValue(for: SettingsRowID.tags) == .array([.string("ios"), .string("swift")]))

        vm.toggleArrayValue(.string("ios"), for: SettingsRowID.tags)
        #expect(vm.rawValue(for: SettingsRowID.tags) == .array([.string("swift")]))
    }

    @Test("errorsForRow and rowHasError accept enum row IDs")
    func errorsForEnumID() {
        let vm = makeViewModel()

        #expect(vm.validateAll() == false)
        #expect(vm.errorsForRow(SettingsRowID.email).isEmpty == false)
        #expect(vm.rowHasError(SettingsRowID.email))
        #expect(vm.rowHasError(SettingsRowID.username) == false)
    }

    @Test("toggleSection and isSectionExpanded accept enum row IDs")
    func sectionToggleEnumID() {
        let form = FormDefinition(id: "s", title: "S") {
            CollapsibleSection(id: SettingsRowID.section, title: "Section") {
                TextInputRow(id: SettingsRowID.username, title: "Username")
            }
        }
        let vm = FormViewModel(formDefinition: form)
        let initial = vm.isSectionExpanded(SettingsRowID.section)

        vm.toggleSection(SettingsRowID.section)
        #expect(vm.isSectionExpanded(SettingsRowID.section) == !initial)
    }
}
