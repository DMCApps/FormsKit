import Foundation

// MARK: - FormPersistenceUserDefaults

/// UserDefaults-backed persistence. Form values are encoded as JSON and stored
/// under a namespaced key in the given `UserDefaults` suite.
public final class FormPersistenceUserDefaults: FormPersistence, @unchecked Sendable {
    private let defaults: UserDefaults

    /// Prefix prepended to all storage keys. Defaults to "FormKit".
    public let keyPrefix: String

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// - Parameters:
    ///   - defaults: The `UserDefaults` suite to use. Defaults to `.standard`.
    ///   - keyPrefix: Prepended to all storage keys.
    ///     Use an app-specific prefix to avoid collisions. Defaults to "FormKit".
    public init(defaults: UserDefaults = .standard,
                keyPrefix: String = "FormKit") {
        self.defaults = defaults
        self.keyPrefix = keyPrefix
    }

    // MARK: FormPersistence

    public func save(_ values: FormValueStore, formId: String) async throws {
        do {
            let data = try encoder.encode(values)
            defaults.set(data, forKey: storageKey(for: formId))
        } catch {
            throw FormPersistenceError.encodingFailed(underlying: error)
        }
    }

    public func load(formId: String) async throws -> FormValueStore {
        guard let data = defaults.data(forKey: storageKey(for: formId)) else {
            return FormValueStore()
        }
        do {
            return try decoder.decode(FormValueStore.self, from: data)
        } catch {
            throw FormPersistenceError.decodingFailed(underlying: error)
        }
    }

    public func clear(formId: String) async throws {
        defaults.removeObject(forKey: storageKey(for: formId))
    }

    // MARK: Helpers

    private func storageKey(for formId: String) -> String {
        "\(keyPrefix).\(formId)"
    }
}
