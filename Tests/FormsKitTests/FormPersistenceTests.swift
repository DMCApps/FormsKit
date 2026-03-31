@testable import FormsKit
import Foundation
import Testing

// MARK: - Helpers

private func makeStore(_ values: [String: AnyCodableValue]) -> FormValueStore {
    FormValueStore(values)
}

// Shared enum types used across persistence round-trip tests.
private enum Status: String, Codable, Sendable { case active, inactive, pending }
private enum Priority: Int, Codable, Sendable { case low = 1, medium = 2, high = 3 }
// Scale exercises the Double-backed enum edge case where raw value 1.0 is stored as
// .int(1) by AnyCodableValue's decoder (Int is tried before Double). The round-trip
// must still recover the correct enum case via the JSON slow path in typed<T>.
private enum Scale: Double, Codable, Sendable { case off = 0.0, normal = 1.0, high = 2.5 }

// MARK: - FormPersistenceMemory Tests

@Suite("FormPersistenceMemory")
struct FormPersistenceMemoryTests {
    @Test("Save and load returns same values")
    func saveAndLoad() async throws {
        let persistence = FormPersistenceMemory()
        let store = makeStore(["name": .string("Alice"), "age": .int(30)])
        try await persistence.save(store, formId: "form1")
        let loaded = try await persistence.load(formId: "form1")
        #expect(loaded["name"] == .string("Alice"))
        #expect(loaded["age"] == .int(30))
    }

    @Test("Load returns empty store when nothing saved")
    func loadEmptyWhenNotSaved() async throws {
        let persistence = FormPersistenceMemory()
        let store = try await persistence.load(formId: "nonexistent")
        #expect(store.isEmpty == true)
    }

    @Test("Clear removes saved data")
    func clearRemovesData() async throws {
        let persistence = FormPersistenceMemory()
        let store = makeStore(["key": .string("value")])
        try await persistence.save(store, formId: "form1")
        try await persistence.clear(formId: "form1")
        let loaded = try await persistence.load(formId: "form1")
        #expect(loaded.isEmpty == true)
    }

    @Test("Key prefix namespacing isolates forms")
    func keyPrefixNamespacing() async throws {
        let p1 = FormPersistenceMemory(keyPrefix: "app1")
        let p2 = FormPersistenceMemory(keyPrefix: "app2")

        try await p1.save(makeStore(["x": .int(1)]), formId: "form")
        try await p2.save(makeStore(["x": .int(2)]), formId: "form")

        let loaded1 = try await p1.load(formId: "form")
        let loaded2 = try await p2.load(formId: "form")

        #expect(loaded1["x"] == .int(1))
        #expect(loaded2["x"] == .int(2))
    }

    @Test("Multiple forms don't interfere")
    func multipleForms() async throws {
        let persistence = FormPersistenceMemory()
        try await persistence.save(makeStore(["a": .string("form1")]), formId: "form1")
        try await persistence.save(makeStore(["a": .string("form2")]), formId: "form2")

        let loaded1 = try await persistence.load(formId: "form1")
        let loaded2 = try await persistence.load(formId: "form2")

        #expect(loaded1["a"] == .string("form1"))
        #expect(loaded2["a"] == .string("form2"))
    }

    @Test("String- and Int-backed enum values survive memory round-trip")
    func enumRoundTrip() async throws {
        let persistence = FormPersistenceMemory()
        var store = FormValueStore()
        store.setValue(Status.active, for: "status")
        store.setValue(Priority.high, for: "priority")

        try await persistence.save(store, formId: "enums")
        let loaded = try await persistence.load(formId: "enums")

        let status: Status? = loaded.value(for: "status")
        let priority: Priority? = loaded.value(for: "priority")
        #expect(status == .active)
        #expect(priority == .high)
    }

    @Test("Double-backed enum with raw value 1.0 survives memory round-trip")
    func doubleBackedEnumRoundTrip() async throws {
        let persistence = FormPersistenceMemory()
        var store = FormValueStore()
        store.setValue(Scale.normal, for: "scale") // raw value 1.0

        // AnyCodableValue.from(Scale.normal) stores .int(1) because the decoder
        // tries Int before Double for whole-number JSON numbers. Verify this
        // intermediate representation explicitly so a future decoder-order change
        // is caught early.
        #expect(store["scale"] == .int(1))

        try await persistence.save(store, formId: "scaleEnums")
        let loaded = try await persistence.load(formId: "scaleEnums")

        // The round-trip must still recover the correct case via the JSON slow path.
        let scale: Scale? = loaded.value(for: "scale")
        #expect(scale == .normal)
    }
}

// MARK: - FormPersistenceFile Tests

@Suite("FormPersistenceFile")
struct FormPersistenceFileTests {
    private func makeTemporaryDirectory() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test("Save creates a JSON file and load returns correct values")
    func saveAndLoad() async throws {
        let dir = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let persistence = FormPersistenceFile(directory: dir)
        let store = makeStore(["name": .string("Bob"), "score": .double(9.5)])
        try await persistence.save(store, formId: "test")

        let jsonFile = dir.appendingPathComponent("test.json")
        #expect(FileManager.default.fileExists(atPath: jsonFile.path) == true)

        let loaded = try await persistence.load(formId: "test")
        #expect(loaded["name"] == .string("Bob"))
        #expect(loaded["score"] == .double(9.5))
    }

    @Test("Load returns empty store when file does not exist")
    func loadWhenNoFile() async throws {
        let dir = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let persistence = FormPersistenceFile(directory: dir)
        let loaded = try await persistence.load(formId: "nonexistent")
        #expect(loaded.isEmpty == true)
    }

    @Test("Clear deletes the file")
    func clearDeletesFile() async throws {
        let dir = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let persistence = FormPersistenceFile(directory: dir)
        try await persistence.save(makeStore(["k": .string("v")]), formId: "form")
        try await persistence.clear(formId: "form")

        let jsonFile = dir.appendingPathComponent("form.json")
        #expect(FileManager.default.fileExists(atPath: jsonFile.path) == false)

        let loaded = try await persistence.load(formId: "form")
        #expect(loaded.isEmpty == true)
    }

    @Test("Key prefix is prepended to file name")
    func keyPrefixInFileName() async throws {
        let dir = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let persistence = FormPersistenceFile(directory: dir, keyPrefix: "myApp")
        try await persistence.save(makeStore(["x": .int(1)]), formId: "settings")

        let expectedFile = dir.appendingPathComponent("myApp.settings.json")
        #expect(FileManager.default.fileExists(atPath: expectedFile.path) == true)
    }

    @Test("All value types survive file round-trip")
    func allValueTypes() async throws {
        let dir = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let persistence = FormPersistenceFile(directory: dir)
        var store = FormValueStore()
        store["bool"] = .bool(true)
        store["int"] = .int(42)
        store["double"] = .double(3.14)
        store["string"] = .string("hello")
        store["array"] = .array([.string("a"), .int(1)])
        store["null"] = .null

        try await persistence.save(store, formId: "allTypes")
        let loaded = try await persistence.load(formId: "allTypes")

        #expect(loaded["bool"] == .bool(true))
        #expect(loaded["int"] == .int(42))
        #expect(loaded["double"] == .double(3.14))
        #expect(loaded["string"] == .string("hello"))
        #expect(loaded["array"] == .array([.string("a"), .int(1)]))
        #expect(loaded["null"] == .null)
    }

    @Test("String- and Int-backed enum values survive file round-trip")
    func enumRoundTrip() async throws {
        let dir = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let persistence = FormPersistenceFile(directory: dir)
        var store = FormValueStore()
        store.setValue(Status.pending, for: "status")
        store.setValue(Priority.medium, for: "priority")

        try await persistence.save(store, formId: "enums")
        let loaded = try await persistence.load(formId: "enums")

        let status: Status? = loaded.value(for: "status")
        let priority: Priority? = loaded.value(for: "priority")
        #expect(status == .pending)
        #expect(priority == .medium)
    }

    @Test("Double-backed enum with raw value 1.0 survives file round-trip")
    func doubleBackedEnumRoundTrip() async throws {
        let dir = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let persistence = FormPersistenceFile(directory: dir)
        var store = FormValueStore()
        store.setValue(Scale.normal, for: "scale") // raw value 1.0

        // AnyCodableValue.from(Scale.normal) stores .int(1) — whole-number doubles
        // are decoded as Int first. Pin this to catch any future decoder-order change.
        #expect(store["scale"] == .int(1))

        try await persistence.save(store, formId: "scaleEnums")
        let loaded = try await persistence.load(formId: "scaleEnums")

        let scale: Scale? = loaded.value(for: "scale")
        #expect(scale == .normal)
    }
}

// MARK: - FormPersistenceUserDefaults Tests

@Suite("FormPersistenceUserDefaults")
struct FormPersistenceUserDefaultsTests {
    private func makeSuiteName() -> String {
        "FormKitTests.\(UUID().uuidString)"
    }

    @Test("Save and load returns same values")
    func saveAndLoad() async throws {
        let suiteName = makeSuiteName()
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let persistence = FormPersistenceUserDefaults(defaults: defaults)
        let store = makeStore(["city": .string("NYC"), "count": .int(5)])
        try await persistence.save(store, formId: "prefs")

        let loaded = try await persistence.load(formId: "prefs")
        #expect(loaded["city"] == .string("NYC"))
        #expect(loaded["count"] == .int(5))
    }

    @Test("Load returns empty store when key not present")
    func loadWhenNoData() async throws {
        let suiteName = makeSuiteName()
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let persistence = FormPersistenceUserDefaults(defaults: defaults)
        let loaded = try await persistence.load(formId: "nonexistent")
        #expect(loaded.isEmpty == true)
    }

    @Test("Clear removes the UserDefaults key")
    func clearRemovesKey() async throws {
        let suiteName = makeSuiteName()
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let persistence = FormPersistenceUserDefaults(defaults: defaults, keyPrefix: "Test")
        try await persistence.save(makeStore(["k": .string("v")]), formId: "form")
        try await persistence.clear(formId: "form")

        #expect(defaults.data(forKey: "Test.form") == nil)
        let loaded = try await persistence.load(formId: "form")
        #expect(loaded.isEmpty == true)
    }

    @Test("Key prefix namespacing prevents collision")
    func keyPrefixNamespacing() async throws {
        let suiteName = makeSuiteName()
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let p1 = FormPersistenceUserDefaults(defaults: defaults, keyPrefix: "feature1")
        let p2 = FormPersistenceUserDefaults(defaults: defaults, keyPrefix: "feature2")

        try await p1.save(makeStore(["val": .int(1)]), formId: "settings")
        try await p2.save(makeStore(["val": .int(2)]), formId: "settings")

        let loaded1 = try await p1.load(formId: "settings")
        let loaded2 = try await p2.load(formId: "settings")

        #expect(loaded1["val"] == .int(1))
        #expect(loaded2["val"] == .int(2))
    }

    @Test("String- and Int-backed enum values survive UserDefaults round-trip")
    func enumRoundTrip() async throws {
        let suiteName = makeSuiteName()
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let persistence = FormPersistenceUserDefaults(defaults: defaults)
        var store = FormValueStore()
        store.setValue(Status.inactive, for: "status")
        store.setValue(Priority.low, for: "priority")

        try await persistence.save(store, formId: "enums")
        let loaded = try await persistence.load(formId: "enums")

        let status: Status? = loaded.value(for: "status")
        let priority: Priority? = loaded.value(for: "priority")
        #expect(status == .inactive)
        #expect(priority == .low)
    }

    @Test("Double-backed enum with raw value 1.0 survives UserDefaults round-trip")
    func doubleBackedEnumRoundTrip() async throws {
        let suiteName = makeSuiteName()
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let persistence = FormPersistenceUserDefaults(defaults: defaults)
        var store = FormValueStore()
        store.setValue(Scale.normal, for: "scale") // raw value 1.0

        // AnyCodableValue.from(Scale.normal) stores .int(1) — whole-number doubles
        // are decoded as Int first. Pin this to catch any future decoder-order change.
        #expect(store["scale"] == .int(1))

        try await persistence.save(store, formId: "scaleEnums")
        let loaded = try await persistence.load(formId: "scaleEnums")

        let scale: Scale? = loaded.value(for: "scale")
        #expect(scale == .normal)
    }
}
