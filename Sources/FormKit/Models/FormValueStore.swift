import Foundation

// MARK: - AnyCodableValue

/// A type-erased Codable value that can hold any primitive or array of primitives.
/// This enum is the currency type used throughout FormKit to store row values
/// in a fully Codable, Sendable, Equatable, and Hashable way.
public enum AnyCodableValue: Sendable, Equatable, Hashable {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([AnyCodableValue])
    case null
}

// MARK: - AnyCodableValue + Codable

extension AnyCodableValue: Codable {
    public init(from decoder: Decoder) throws {
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
        var container = encoder.singleValueContainer()
        switch self {
        case let .bool(value): try container.encode(value)
        case let .int(value): try container.encode(value)
        case let .double(value): try container.encode(value)
        case let .string(value): try container.encode(value)
        case let .array(value): try container.encode(value)
        case .null: try container.encodeNil()
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
        default: return false
        }
    }
}

// MARK: - AnyCodableValue + Typed Access

public extension AnyCodableValue {
    /// Create an AnyCodableValue from any supported Swift type.
    /// Falls back to a string description for types that don't map directly.
    static func from(_ value: some Codable & Sendable) -> AnyCodableValue {
        if let v = value as? Bool { return .bool(v) }
        if let v = value as? Int { return .int(v) }
        if let v = value as? Double { return .double(v) }
        if let v = value as? Float { return .double(Double(v)) }
        if let v = value as? String { return .string(v) }
        // For CaseIterable / CustomStringConvertible enums, use their description.
        return .string(String(describing: value))
    }

    /// Attempt to extract a typed value from this AnyCodableValue.
    func typed<T>(_ type: T.Type) -> T? {
        switch self {
        case let .bool(v): return v as? T
        case let .int(v): return (v as? T) ?? (Double(v) as? T)
        case let .double(v): return (v as? T) ?? (Int(v) as? T)
        case let .string(v): return v as? T
        case let .array(v): return v as? T
        case .null: return nil
        }
    }

    /// Returns the string representation for display purposes.
    var displayString: String {
        switch self {
        case let .bool(v): return v ? "true" : "false"
        case let .int(v): return "\(v)"
        case let .double(v): return "\(v)"
        case let .string(v): return v
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
    public func value<T>(for key: String) -> T? {
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
