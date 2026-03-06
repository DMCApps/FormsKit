import Foundation

// MARK: - FormPersistence

/// Protocol for saving and loading form data.
/// All operations are async to support file I/O, network, and other async-capable backends.
/// Conform to this protocol to integrate custom persistence (e.g., Keychain, CoreData, network).
public protocol FormPersistence: Sendable {
    /// Persist the given value store for a form.
    func save(_ values: FormValueStore, formId: String) async throws

    /// Load previously persisted values for a form.
    /// Returns an empty store if nothing has been saved yet.
    func load(formId: String) async throws -> FormValueStore

    /// Delete all persisted data for a form.
    func clear(formId: String) async throws
}

// MARK: - FormPersistenceError

/// Errors thrown by FormPersistence implementations.
public enum FormPersistenceError: Error, Sendable, LocalizedError {
    case encodingFailed(underlying: Error)
    case decodingFailed(underlying: Error)
    case fileWriteFailed(underlying: Error)
    case fileReadFailed(underlying: Error)
    case fileDeleteFailed(underlying: Error)
    case unknown(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case let .encodingFailed(e): return "Encoding failed: \(e.localizedDescription)"
        case let .decodingFailed(e): return "Decoding failed: \(e.localizedDescription)"
        case let .fileWriteFailed(e): return "File write failed: \(e.localizedDescription)"
        case let .fileReadFailed(e): return "File read failed: \(e.localizedDescription)"
        case let .fileDeleteFailed(e): return "File delete failed: \(e.localizedDescription)"
        case let .unknown(e): return "Unknown persistence error: \(e.localizedDescription)"
        }
    }
}
