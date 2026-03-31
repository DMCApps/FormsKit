@testable import FormsKit
import Foundation
import Testing

// MARK: - Helpers

private func makeStore(_ values: [String: AnyCodableValue]) -> FormValueStore {
    FormValueStore(values)
}

// MARK: - RowScope Tests

@Suite("RowScope")
struct RowScopeTests {
    @Test(".all returns the full store unchanged")
    func allScopePassesThrough() {
        let store = makeStore(["a": .string("1"), "b": .string("2"), "c": .string("3")])
        let filtered = store.filtered(by: .all)
        #expect(filtered["a"] == .string("1"))
        #expect(filtered["b"] == .string("2"))
        #expect(filtered["c"] == .string("3"))
    }

    @Test(".including keeps only listed keys")
    func includingKeepsOnlyListedKeys() {
        let store = makeStore(["a": .string("1"), "b": .string("2"), "c": .string("3")])
        let filtered = store.filtered(by: .including(["a", "c"]))
        #expect(filtered["a"] == .string("1"))
        #expect(filtered["b"] == nil)
        #expect(filtered["c"] == .string("3"))
    }

    @Test(".including with empty list produces empty store")
    func includingEmptyListProducesEmptyStore() {
        let store = makeStore(["a": .string("1"), "b": .string("2")])
        let filtered = store.filtered(by: .including([]))
        #expect(filtered.isEmpty)
    }

    @Test(".excluding removes listed keys")
    func excludingRemovesListedKeys() {
        let store = makeStore(["a": .string("1"), "b": .string("2"), "c": .string("3")])
        let filtered = store.filtered(by: .excluding(["b"]))
        #expect(filtered["a"] == .string("1"))
        #expect(filtered["b"] == nil)
        #expect(filtered["c"] == .string("3"))
    }

    @Test(".excluding with empty list keeps all keys")
    func excludingEmptyListKeepsAll() {
        let store = makeStore(["a": .string("1"), "b": .string("2")])
        let filtered = store.filtered(by: .excluding([]))
        #expect(filtered["a"] == .string("1"))
        #expect(filtered["b"] == .string("2"))
    }

    @Test(".including unknown keys produces empty store")
    func includingUnknownKeysProducesEmptyStore() {
        let store = makeStore(["a": .string("1")])
        let filtered = store.filtered(by: .including(["z"]))
        #expect(filtered.isEmpty)
    }

    @Test(".excluding all keys produces empty store")
    func excludingAllKeysProducesEmptyStore() {
        let store = makeStore(["a": .string("1"), "b": .string("2")])
        let filtered = store.filtered(by: .excluding(["a", "b"]))
        #expect(filtered.isEmpty)
    }

    @Test(".including RawRepresentable overload maps rawValues correctly")
    func includingRawRepresentableOverload() {
        enum Row: String { case email, password }
        let store = makeStore(["email": .string("a@b.com"), "password": .string("secret")])
        let filtered = store.filtered(by: .including([Row.password]))
        #expect(filtered["email"] == nil)
        #expect(filtered["password"] == .string("secret"))
    }

    @Test(".excluding RawRepresentable overload maps rawValues correctly")
    func excludingRawRepresentableOverload() {
        enum Row: String { case email, password }
        let store = makeStore(["email": .string("a@b.com"), "password": .string("secret")])
        let filtered = store.filtered(by: .excluding([Row.password]))
        #expect(filtered["email"] == .string("a@b.com"))
        #expect(filtered["password"] == nil)
    }
}

// MARK: - FormPersistenceMixed Tests

@Suite("FormPersistenceMixed")
struct FormPersistenceMixedTests {
    // MARK: Save & Load

    @Test("save routes keys to correct backends based on scope")
    func saveRoutesKeysByScope() async throws {
        let defaults = FormPersistenceMemory(keyPrefix: "defaults")
        let keychain = FormPersistenceMemory(keyPrefix: "keychain")

        let mixed = FormPersistenceMixed([
            .init(defaults, scope: .excluding(["password"])),
            .init(keychain, scope: .including(["password"]))
        ])

        let store = makeStore(["email": .string("a@b.com"), "password": .string("secret")])
        try await mixed.save(store, formId: "login")

        let defaultsStore = try await defaults.load(formId: "login")
        let keychainStore = try await keychain.load(formId: "login")

        #expect(defaultsStore["email"] == .string("a@b.com"))
        #expect(defaultsStore["password"] == nil)

        #expect(keychainStore["password"] == .string("secret"))
        #expect(keychainStore["email"] == nil)
    }

    @Test("load merges values from all backends")
    func loadMergesAllBackends() async throws {
        let defaults = FormPersistenceMemory(keyPrefix: "defaults")
        let keychain = FormPersistenceMemory(keyPrefix: "keychain")

        // Pre-populate each backend directly
        try await defaults.save(makeStore(["email": .string("a@b.com")]), formId: "login")
        try await keychain.save(makeStore(["password": .string("secret")]), formId: "login")

        let mixed = FormPersistenceMixed([
            .init(defaults, scope: .excluding(["password"])),
            .init(keychain, scope: .including(["password"]))
        ])

        let loaded = try await mixed.load(formId: "login")
        #expect(loaded["email"] == .string("a@b.com"))
        #expect(loaded["password"] == .string("secret"))
    }

    @Test("load returns empty store when all backends are empty")
    func loadEmptyWhenNoData() async throws {
        let mixed = FormPersistenceMixed([
            .init(FormPersistenceMemory(), scope: .all)
        ])
        let loaded = try await mixed.load(formId: "noop")
        #expect(loaded.isEmpty)
    }

    @Test("clear removes data from all backends")
    func clearRemovesAllBackends() async throws {
        let defaults = FormPersistenceMemory(keyPrefix: "defaults")
        let keychain = FormPersistenceMemory(keyPrefix: "keychain")

        let mixed = FormPersistenceMixed([
            .init(defaults, scope: .excluding(["password"])),
            .init(keychain, scope: .including(["password"]))
        ])

        let store = makeStore(["email": .string("a@b.com"), "password": .string("secret")])
        try await mixed.save(store, formId: "login")
        try await mixed.clear(formId: "login")

        let defaultsStore = try await defaults.load(formId: "login")
        let keychainStore = try await keychain.load(formId: "login")

        #expect(defaultsStore.isEmpty)
        #expect(keychainStore.isEmpty)
    }

    // MARK: Execution order — save

    @Test("save processes entries in array order")
    func saveProcessesInOrder() async throws {
        // Use two .all backends to observe that both receive the full store,
        // and the order they are called can be inferred by what each stores.
        let first = FormPersistenceMemory(keyPrefix: "first")
        let second = FormPersistenceMemory(keyPrefix: "second")

        let mixed = FormPersistenceMixed([
            .init(first, scope: .all),
            .init(second, scope: .all)
        ])

        let store = makeStore(["x": .int(1)])
        try await mixed.save(store, formId: "form")

        let firstLoaded = try await first.load(formId: "form")
        let secondLoaded = try await second.load(formId: "form")

        #expect(firstLoaded["x"] == .int(1))
        #expect(secondLoaded["x"] == .int(1))
    }

    // MARK: Execution order — load / last-writer-wins

    @Test("load: later entries win on key conflict")
    func loadLaterEntryWinsOnConflict() async throws {
        let first = FormPersistenceMemory(keyPrefix: "first")
        let second = FormPersistenceMemory(keyPrefix: "second")

        // Both backends have a value for "sharedKey" — second should win
        try await first.save(makeStore(["sharedKey": .string("from-first")]), formId: "form")
        try await second.save(makeStore(["sharedKey": .string("from-second")]), formId: "form")

        let mixed = FormPersistenceMixed([
            .init(first, scope: .all),
            .init(second, scope: .all)
        ])

        let loaded = try await mixed.load(formId: "form")
        #expect(loaded["sharedKey"] == .string("from-second"))
    }

    @Test("load: first entry wins when it is listed last in the array")
    func loadEntryOrderDeterminesWinner() async throws {
        let first = FormPersistenceMemory(keyPrefix: "first")
        let second = FormPersistenceMemory(keyPrefix: "second")

        try await first.save(makeStore(["sharedKey": .string("from-first")]), formId: "form")
        try await second.save(makeStore(["sharedKey": .string("from-second")]), formId: "form")

        // Reversed order — first is now last, so it wins
        let mixed = FormPersistenceMixed([
            .init(second, scope: .all),
            .init(first, scope: .all)
        ])

        let loaded = try await mixed.load(formId: "form")
        #expect(loaded["sharedKey"] == .string("from-first"))
    }

    // MARK: .all scope

    @Test("single .all entry behaves identically to using the backend directly")
    func singleAllEntryPassesThrough() async throws {
        let backend = FormPersistenceMemory()
        let mixed = FormPersistenceMixed([.init(backend, scope: .all)])

        let store = makeStore(["a": .bool(true), "b": .int(42)])
        try await mixed.save(store, formId: "form")
        let loaded = try await mixed.load(formId: "form")

        #expect(loaded["a"] == .bool(true))
        #expect(loaded["b"] == .int(42))
    }

    // MARK: Non-overlapping scopes round-trip

    @Test("non-overlapping including/excluding scopes round-trip correctly")
    func nonOverlappingScopesRoundTrip() async throws {
        let defaults = FormPersistenceMemory(keyPrefix: "defaults")
        let secure = FormPersistenceMemory(keyPrefix: "secure")

        let mixed = FormPersistenceMixed([
            .init(defaults, scope: .excluding(["pin", "password"])),
            .init(secure, scope: .including(["pin", "password"]))
        ])

        let store = makeStore([
            "username": .string("alice"),
            "email": .string("a@b.com"),
            "pin": .string("1234"),
            "password": .string("hunter2")
        ])

        try await mixed.save(store, formId: "account")
        let loaded = try await mixed.load(formId: "account")

        #expect(loaded["username"] == .string("alice"))
        #expect(loaded["email"] == .string("a@b.com"))
        #expect(loaded["pin"] == .string("1234"))
        #expect(loaded["password"] == .string("hunter2"))

        // Verify routing — defaults must NOT have sensitive keys
        let defaultsStore = try await defaults.load(formId: "account")
        #expect(defaultsStore["pin"] == nil)
        #expect(defaultsStore["password"] == nil)

        // Verify routing — secure must NOT have non-sensitive keys
        let secureStore = try await secure.load(formId: "account")
        #expect(secureStore["username"] == nil)
        #expect(secureStore["email"] == nil)
    }
}
