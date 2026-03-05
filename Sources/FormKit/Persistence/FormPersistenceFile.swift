import Foundation

// MARK: - FormPersistenceFile

/// File-based JSON persistence. Each form's data is saved as a separate `.json` file
/// in the specified directory.
public final class FormPersistenceFile: FormPersistence, @unchecked Sendable {
    /// The directory where form JSON files are written.
    public let directory: URL

    /// Optional prefix added to all form file names to namespace this instance.
    public let keyPrefix: String

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// - Parameters:
    ///   - directory: Directory to write files to.
    ///     Defaults to `<Application Support>/FormKit/`.
    ///   - keyPrefix: Prepended to all form file names. Use to isolate between features.
    public init(directory: URL? = nil, keyPrefix: String = "") {
        if let directory {
            self.directory = directory
        } else {
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!
            self.directory = appSupport.appendingPathComponent("FormKit", isDirectory: true)
        }
        self.keyPrefix = keyPrefix

        // Ensure the directory exists. Ignore errors (e.g. already exists).
        try? FileManager.default.createDirectory(
            at: self.directory,
            withIntermediateDirectories: true
        )
    }

    // MARK: FormPersistence

    public func save(_ values: FormValueStore, formId: String) async throws {
        do {
            let data = try encoder.encode(values)
            try data.write(to: fileURL(for: formId), options: .atomic)
        } catch let error as EncodingError {
            throw FormPersistenceError.encodingFailed(underlying: error)
        } catch {
            throw FormPersistenceError.fileWriteFailed(underlying: error)
        }
    }

    public func load(formId: String) async throws -> FormValueStore {
        let url = fileURL(for: formId)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return FormValueStore()
        }
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(FormValueStore.self, from: data)
        } catch let error as DecodingError {
            throw FormPersistenceError.decodingFailed(underlying: error)
        } catch {
            throw FormPersistenceError.fileReadFailed(underlying: error)
        }
    }

    public func clear(formId: String) async throws {
        let url = fileURL(for: formId)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            throw FormPersistenceError.fileDeleteFailed(underlying: error)
        }
    }

    // MARK: Helpers

    private func fileURL(for formId: String) -> URL {
        let name = keyPrefix.isEmpty ? formId : "\(keyPrefix).\(formId)"
        return directory.appendingPathComponent("\(name).json")
    }
}
