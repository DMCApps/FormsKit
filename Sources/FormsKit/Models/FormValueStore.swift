import Foundation

// MARK: - AnyCodableValue Failure Handler

/// Called when `AnyCodableValue.from(_:)` cannot encode a value.
/// Defaults to `assertionFailure` so bugs surface immediately in debug builds.
/// Tests can replace this with a closure that records the failure without crashing.
///
/// `nonisolated(unsafe)` is safe here because:
/// - In production this var is never written — only the default closure is read.
/// - In tests it is written once during single-threaded setup, before any concurrent
///   test execution begins. No two tests write to it concurrently.
nonisolated(unsafe) var anyCodableValueEncodingFailure: (_ message: String) -> Void = { message in
    assertionFailure(message)
}

// MARK: - AnyCodableValue

/// A type-erased Codable value that can hold any primitive or array of primitives.
/// This enum is the currency type used throughout FormKit to store row values
/// in a fully Codable, Sendable, Equatable, and Hashable way.
public enum AnyCodableValue: Sendable, Equatable, Hashable {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    /// A calendar-independent point in time, stored as a `TimeInterval`
    /// (seconds since 1 Jan 2001 00:00:00 UTC — i.e. `Date.timeIntervalSinceReferenceDate`).
    case date(Date)
    case array([AnyCodableValue])
    case null
}

// MARK: - AnyCodableValue + Codable

extension AnyCodableValue: Codable {
    /// The JSON key used to tag date values, distinguishing them from plain doubles.
    private enum DateCodingKeys: String, CodingKey { case __date }

    public init(from decoder: Decoder) throws {
        // Check for the tagged date object first: {"__date": <TimeInterval>}
        if let keyed = try? decoder.container(keyedBy: DateCodingKeys.self),
           let interval = try? keyed.decode(Double.self, forKey: .__date) {
            self = .date(Date(timeIntervalSinceReferenceDate: interval))
            return
        }
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([AnyCodableValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.typeMismatch(
                AnyCodableValue.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unsupported AnyCodableValue type"
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case let .date(value):
            // Encode as {"__date": <TimeInterval>} so it round-trips unambiguously.
            var keyed = encoder.container(keyedBy: DateCodingKeys.self)
            try keyed.encode(value.timeIntervalSinceReferenceDate, forKey: .__date)
        default:
            var container = encoder.singleValueContainer()
            switch self {
            case let .bool(value): try container.encode(value)
            case let .int(value): try container.encode(value)
            case let .double(value): try container.encode(value)
            case let .string(value): try container.encode(value)
            case let .array(value): try container.encode(value)
            case .null: try container.encodeNil()
            case .date: break // handled above
            }
        }
    }
}

// MARK: - AnyCodableValue + Comparable

extension AnyCodableValue: Comparable {
    public static func < (lhs: AnyCodableValue, rhs: AnyCodableValue) -> Bool {
        switch (lhs, rhs) {
        case let (.int(a), .int(b)): return a < b
        case let (.double(a), .double(b)): return a < b
        case let (.int(a), .double(b)): return Double(a) < b
        case let (.double(a), .int(b)): return a < Double(b)
        case let (.string(a), .string(b)): return a < b
        case let (.date(a), .date(b)): return a < b
        default: return false
        }
    }
}

// MARK: - AnyCodableValue + Typed Access

public extension AnyCodableValue {
    /// Create an AnyCodableValue from any supported Swift type.
    ///
    /// Primitives are mapped directly to their corresponding cases. Any other
    /// `Codable` type (e.g. `String`- or `Int`-backed enums) is encoded via
    /// `JSONEncoder` and decoded back into an `AnyCodableValue`, ensuring
    /// full round-trip symmetry with `typed<T>(_:)`.
    static func from(_ value: some Codable & Sendable) -> AnyCodableValue {
        if let v = value as? Bool { return .bool(v) }
        if let v = value as? Int { return .int(v) }
        if let v = value as? Double { return .double(v) }
        if let v = value as? Float { return .double(Double(v)) }
        if let v = value as? String { return .string(v) }
        if let v = value as? Date { return .date(v) }
        // For any other Codable type (enums backed by String, Int, Double, etc.)
        // encode through JSON so that typed<T>(_:) can recover the value via
        // the same Decodable path — guaranteeing a symmetric round-trip.
        do {
            let data = try JSONEncoder().encode(value)
            return try JSONDecoder().decode(AnyCodableValue.self, from: data)
        } catch {
            anyCodableValueEncodingFailure("AnyCodableValue.from(_:) failed to encode \(type(of: value)): \(error)")
            return .null
        }
    }

    /// Attempt to extract a typed value from this `AnyCodableValue`.
    ///
    /// Primitives are returned via direct cast. For any other `Decodable` type
    /// (e.g. enums backed by `String`, `Int`, `Double`, etc.) the stored value
    /// is encoded back to JSON and decoded as `T`, providing full symmetry with
    /// `from(_:)` without requiring callers to adopt additional protocols.
    func typed<T: Decodable>(_ type: T.Type) -> T? {
        // Fast path: direct primitive casts.
        switch self {
        case let .bool(v): return v as? T
        case let .int(v):
            if let direct = v as? T { return direct }
            // Widen Int → Double so callers requesting Double from an int-stored value
            // (e.g. `.int(3).typed(Double.self) == 3.0`) get a result without hitting
            // the JSON slow path.
            if let coerced = Double(v) as? T { return coerced }
        case let .double(v):
            if let direct = v as? T { return direct }
            // Narrow Double → Int for whole-number values. This handles the case where
            // a Double-backed enum with a whole-number raw value (e.g. `1.0`) gets stored
            // as `.int(1)` by AnyCodableValue's own Decodable init (which tries Int before
            // Double for whole-number JSON numbers). The coercion recovers those values on
            // the fast path before falling through to the JSON slow path.
            if let coerced = Int(v) as? T { return coerced }
        case let .string(v):
            if let direct = v as? T { return direct }
        case let .date(v):
            if let direct = v as? T { return direct }
        case let .array(v):
            if let direct = v as? T { return direct }
        case .null:
            return nil
        }
        // Slow path: Decodable type (enum, struct, etc.) that didn't match a primitive
        // cast. Re-encode self to JSON and decode as T — T is statically Decodable.
        guard let data = try? JSONEncoder().encode(self),
              let value = try? JSONDecoder().decode(T.self, from: data)
        else { return nil }
        return value
    }

    /// Returns the string representation for display purposes.
    var displayString: String {
        switch self {
        case let .bool(v): return v ? "true" : "false"
        case let .int(v): return "\(v)"
        case let .double(v): return "\(v)"
        case let .string(v): return v
        case let .date(v): return ISO8601DateFormatter().string(from: v)
        case let .array(v): return v.map(\.displayString).joined(separator: ", ")
        case .null: return ""
        }
    }
}

// MARK: - FormValueStore

/// A type-erased, Codable dictionary that stores form row values keyed by row ID.
/// This is the central data structure passed between FormViewModel, persistence layers,
/// and condition/validation evaluators.
public struct FormValueStore: Codable, Sendable, Equatable {
    private var storage: [String: AnyCodableValue]

    public init(_ initial: [String: AnyCodableValue] = [:]) {
        storage = initial
    }

    // MARK: Subscript

    public subscript(key: String) -> AnyCodableValue? {
        get { storage[key] }
        set { storage[key] = newValue }
    }

    // MARK: Typed Access

    /// Get a typed value for a key, attempting a type-cast from AnyCodableValue.
    public func value<T: Decodable>(for key: String) -> T? {
        storage[key]?.typed(T.self)
    }

    /// Set a typed Codable value for a key, wrapping it in AnyCodableValue.
    public mutating func setValue(_ value: (some Codable & Sendable)?, for key: String) {
        if let value {
            storage[key] = AnyCodableValue.from(value)
        } else {
            storage[key] = .null
        }
    }

    // MARK: Existence

    /// Returns true if a value exists for the key and it is not `.null`.
    public func hasValue(for key: String) -> Bool {
        guard let val = storage[key] else { return false }
        return val != .null
    }

    // MARK: Array Support (for MultiValueRow)

    /// Returns true if the value for the key is an array that contains the given element.
    public func arrayContains(key: String, value: AnyCodableValue) -> Bool {
        guard case let .array(arr) = storage[key] else { return false }
        return arr.contains(value)
    }

    // MARK: Merge

    /// Merge another store into this one. Values from `other` win on conflict.
    public mutating func merge(_ other: FormValueStore) {
        for (key, value) in other.storage {
            storage[key] = value
        }
    }

    /// Remove the value for a key.
    public mutating func removeValue(for key: String) {
        storage.removeValue(forKey: key)
    }

    // MARK: Keys

    /// All keys currently in the store.
    public var keys: [String] { Array(storage.keys) }

    /// Whether the store is empty.
    public var isEmpty: Bool { storage.isEmpty }
}
