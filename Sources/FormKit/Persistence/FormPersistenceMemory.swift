import Foundation

// MARK: - FormPersistenceMemory

/// In-memory persistence backed by a dictionary.
/// Data is retained as long as this instance is alive.
/// Suitable for use during testing or when you want transient save/load within a session.
public final class FormPersistenceMemory: FormPersistence, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: FormValueStore] = [:]

    /// Optional prefix added to all form IDs to namespace this instance.
    public let keyPrefix: String

    /// - Parameter keyPrefix: Prepended to all form IDs. Use to isolate between features.
    public init(keyPrefix: String = "") {
        self.keyPrefix = keyPrefix
    }

    // MARK: FormPersistence

    public func save(_ values: FormValueStore, formId: String) async throws {
        lock.withLock {
            storage[prefixedKey(formId)] = values
        }
    }

    public func load(formId: String) async throws -> FormValueStore {
        lock.withLock {
            storage[prefixedKey(formId)] ?? FormValueStore()
        }
    }

    public func clear(formId: String) async throws {
        let key = prefixedKey(formId)
        lock.withLock {
            _ = storage.removeValue(forKey: key)
        }
    }

    // MARK: Helpers

    private func prefixedKey(_ formId: String) -> String {
        keyPrefix.isEmpty ? formId : "\(keyPrefix).\(formId)"
    }
}
