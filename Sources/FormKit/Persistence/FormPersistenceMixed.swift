import Foundation

// MARK: - RowScope

/// Defines which row IDs a persistence backend is responsible for.
///
/// Use `RowScope` when constructing a `MixedPersistenceEntry` to restrict a
/// backend to a specific subset of rows. This lets you route sensitive fields
/// (e.g. passwords) to a secure store while persisting everything else with a
/// standard backend.
///
/// - `.all`: The backend receives every key in the store. Default.
/// - `.including`: The backend receives **only** the listed row IDs.
/// - `.excluding`: The backend receives every row ID **except** the listed ones.
///
/// ## Choosing between `.including` and `.excluding`
///
/// Use `.including` when you know exactly which rows need special handling
/// (e.g. a keychain backend that owns `["password", "pin"]`). Use `.excluding`
/// when it's easier to describe the complement — the rows a general-purpose
/// backend should skip.
///
/// Together they cover the common pattern cleanly:
/// ```swift
/// FormPersistenceMixed([
///     .init(FormPersistenceUserDefaults(), scope: .excluding(["password"])),
///     .init(MyKeychainPersistence(),       scope: .including(["password"]))
/// ])
/// ```
public enum RowScope: Sendable {
    /// No filtering — the backend sees every key in the store.
    case all

    /// The backend only receives values whose row ID appears in this list.
    /// Keys absent from the list are silently dropped before the store is
    /// handed to the backend.
    case including([String])

    /// The backend receives all values **except** those whose row ID appears
    /// in this list. Listed keys are silently dropped before the store is
    /// handed to the backend.
    case excluding([String])
}

// MARK: - MixedPersistenceEntry

/// A pairing of a persistence backend and the row IDs it is responsible for.
///
/// Pass an array of `MixedPersistenceEntry` values to `FormPersistenceMixed`.
/// The `scope` defaults to `.all`, so existing backends drop in unchanged:
///
/// ```swift
/// // Full store — equivalent to using the backend directly
/// MixedPersistenceEntry(FormPersistenceUserDefaults())
///
/// // Only rows "password" and "pin" go to keychain
/// MixedPersistenceEntry(MyKeychainPersistence(), scope: .including(["password", "pin"]))
///
/// // Everything except "password" and "pin" goes to UserDefaults
/// MixedPersistenceEntry(FormPersistenceUserDefaults(), scope: .excluding(["password", "pin"]))
/// ```
public struct MixedPersistenceEntry: Sendable {
    /// The backend that will receive the filtered store.
    public let backend: any FormPersistence

    /// Which row IDs this backend is responsible for.
    public let scope: RowScope

    /// - Parameters:
    ///   - backend: The persistence backend to use.
    ///   - scope: Which row IDs the backend receives. Defaults to `.all`.
    public init(_ backend: any FormPersistence, scope: RowScope = .all) {
        self.backend = backend
        self.scope = scope
    }
}

// MARK: - FormPersistenceMixed

/// A fan-out persistence backend that routes row values to multiple backends
/// based on each backend's declared `RowScope`.
///
/// ## Execution order
///
/// **Save** — entries are processed **in array order**, sequentially. Each
/// backend receives only the keys permitted by its `RowScope`. If a backend
/// throws, execution stops immediately and the error propagates; subsequent
/// backends in the array are **not** called. Design your entry order with this
/// in mind: place the most critical backend first if partial failure is a
/// concern.
///
/// **Load** — entries are loaded **in array order**, sequentially. Results are
/// merged into a single store using a last-writer-wins strategy: if two
/// backends both return a value for the same key, the value from the
/// **later entry** in the array wins. In practice this should never happen if
/// scopes are non-overlapping, but the behaviour is deterministic when they do
/// overlap.
///
/// **Clear** — entries are cleared **in array order**, sequentially. The same
/// early-exit-on-throw behaviour applies as with save.
///
/// ## Usage
///
/// ```swift
/// let persistence = FormPersistenceMixed([
///     .init(FormPersistenceUserDefaults(), scope: .excluding(["password"])),
///     .init(MyKeychainPersistence(),       scope: .including(["password"]))
/// ])
///
/// let form = FormDefinition(
///     id: "login",
///     title: "Sign In",
///     persistence: persistence,
///     saveBehaviour: .buttonNavigationBar()
/// ) {
///     TextInputRow(id: "email",    title: "Email",    keyboardType: .emailAddress)
///     TextInputRow(id: "password", title: "Password", isSecure: true)
/// }
/// ```
///
/// ## Scopes with a typed RowID enum
///
/// If you use `TypedFormDefinition`, pass your enum values directly using the
/// `RawRepresentable` convenience initializers on `RowScope`:
///
/// ```swift
/// FormPersistenceMixed([
///     .init(FormPersistenceUserDefaults(), scope: .excluding([LoginRow.password])),
///     .init(MyKeychainPersistence(),       scope: .including([LoginRow.password]))
/// ])
/// ```
public actor FormPersistenceMixed: FormPersistence {
    private let entries: [MixedPersistenceEntry]

    /// - Parameter entries: Ordered list of backend/scope pairs.
    ///   See the class-level documentation for execution order guarantees.
    public init(_ entries: [MixedPersistenceEntry]) {
        self.entries = entries
    }

    // MARK: FormPersistence

    /// Saves the store to each backend in array order.
    ///
    /// Each backend receives only the keys permitted by its `RowScope`. If any
    /// backend throws, the remaining backends are skipped and the error
    /// propagates to the caller.
    public func save(_ values: FormValueStore, formId: String) async throws {
        for entry in entries {
            try await entry.backend.save(values.filtered(by: entry.scope), formId: formId)
        }
    }

    /// Loads values from each backend in array order and merges them.
    ///
    /// Later entries win on key conflicts. This is deterministic when scopes
    /// are non-overlapping (the expected case), and predictable when they
    /// accidentally overlap.
    public func load(formId: String) async throws -> FormValueStore {
        var merged = FormValueStore()
        for entry in entries {
            let loaded = try await entry.backend.load(formId: formId)
            merged.merge(loaded)
        }
        return merged
    }

    /// Clears all backends in array order.
    ///
    /// If any backend throws, the remaining backends are skipped and the error
    /// propagates to the caller.
    public func clear(formId: String) async throws {
        for entry in entries {
            try await entry.backend.clear(formId: formId)
        }
    }
}

// MARK: - FormValueStore + RowScope filtering

extension FormValueStore {
    /// Returns a new store containing only the keys permitted by the given `RowScope`.
    func filtered(by scope: RowScope) -> FormValueStore {
        switch scope {
        case .all:
            return self
        case let .including(ids):
            let allowed = Set(ids)
            return FormValueStore(
                Dictionary(uniqueKeysWithValues: keys
                    .filter { allowed.contains($0) }
                    .compactMap { key in self[key].map { (key, $0) } }
                )
            )
        case let .excluding(ids):
            let blocked = Set(ids)
            return FormValueStore(
                Dictionary(uniqueKeysWithValues: keys
                    .filter { !blocked.contains($0) }
                    .compactMap { key in self[key].map { (key, $0) } }
                )
            )
        }
    }
}

// MARK: - RowScope + RawRepresentable convenience

public extension RowScope {
    /// Creates an `.including` scope from a `RawRepresentable` enum array.
    ///
    /// ```swift
    /// .including([LoginRow.password, LoginRow.pin])
    /// ```
    static func including<ID: RawRepresentable>(
        _ ids: [ID]
    ) -> RowScope where ID.RawValue == String {
        .including(ids.map(\.rawValue))
    }

    /// Creates an `.excluding` scope from a `RawRepresentable` enum array.
    ///
    /// ```swift
    /// .excluding([LoginRow.password, LoginRow.pin])
    /// ```
    static func excluding<ID: RawRepresentable>(
        _ ids: [ID]
    ) -> RowScope where ID.RawValue == String {
        .excluding(ids.map(\.rawValue))
    }
}
