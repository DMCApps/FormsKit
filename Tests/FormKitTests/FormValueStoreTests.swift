@testable import FormKit
import Foundation
import Testing

private let referenceDate = Date(timeIntervalSinceReferenceDate: 800_000_000)

// MARK: - AnyCodableValue Tests

@Suite("AnyCodableValue")
struct AnyCodableValueTests {
    @Test("Codable round-trip for all value types")
    func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let values: [AnyCodableValue] = [
            .bool(true),
            .bool(false),
            .int(42),
            .double(3.14),
            .string("hello"),
            .date(referenceDate),
            .array([.int(1), .string("two"), .bool(false)]),
            .null
        ]

        for original in values {
            let data = try encoder.encode(original)
            let decoded = try decoder.decode(AnyCodableValue.self, from: data)
            #expect(decoded == original)
        }
    }

    @Test("date is encoded as tagged object, not a plain double")
    func dateEncodedAsTaggedObject() throws {
        let encoded = try JSONEncoder().encode(AnyCodableValue.date(referenceDate))
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Double]
        #expect(json?["__date"] == referenceDate.timeIntervalSinceReferenceDate)
    }

    @Test("date round-trip preserves TimeInterval exactly")
    func dateRoundTrip() throws {
        let original = AnyCodableValue.date(referenceDate)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AnyCodableValue.self, from: data)
        if case let .date(d) = decoded {
            #expect(d.timeIntervalSinceReferenceDate == referenceDate.timeIntervalSinceReferenceDate)
        } else {
            Issue.record("Expected .date, got \(decoded)")
        }
    }

    @Test("Comparable ordering")
    func comparable() {
        #expect(AnyCodableValue.int(1) < .int(2))
        #expect(AnyCodableValue.double(1.5) < .double(2.5))
        #expect(AnyCodableValue.int(1) < .double(1.5))
        #expect(AnyCodableValue.double(0.9) < .int(1))
        #expect(AnyCodableValue.string("apple") < .string("banana"))
        let earlier = Date(timeIntervalSinceReferenceDate: 0)
        let later = Date(timeIntervalSinceReferenceDate: 1000)
        #expect(AnyCodableValue.date(earlier) < .date(later))
        // Incompatible types return false for <
        #expect((AnyCodableValue.bool(true) < .int(1)) == false)
        #expect((AnyCodableValue.date(earlier) < .int(1)) == false)
    }

    @Test("Typed extraction")
    func typedExtraction() {
        #expect(AnyCodableValue.bool(true).typed(Bool.self) == true)
        #expect(AnyCodableValue.int(7).typed(Int.self) == 7)
        #expect(AnyCodableValue.double(2.5).typed(Double.self) == 2.5)
        #expect(AnyCodableValue.string("hi").typed(String.self) == "hi")
        #expect(AnyCodableValue.date(referenceDate).typed(Date.self) == referenceDate)
        // Int can also be extracted as Double
        #expect(AnyCodableValue.int(3).typed(Double.self) == 3.0)
    }

    @Test("typed() and from(_:) round-trip String-backed enums")
    func roundTripStringBackedEnum() {
        enum Fruit: String, Codable, Sendable { case apple, banana, cherry }

        // Storage side: from(_:) encodes via JSONEncoder, producing .string("banana")
        #expect(AnyCodableValue.from(Fruit.banana) == .string("banana"))

        // Retrieval side: typed<T> decodes via JSONDecoder from the stored .string
        let result = AnyCodableValue.string("banana").typed(Fruit.self)
        #expect(result == .banana)
    }

    @Test("typed() and from(_:) round-trip Int-backed enums")
    func roundTripIntBackedEnum() {
        enum Priority: Int, Codable, Sendable { case low = 1, medium = 2, high = 3 }

        // Storage side: from(_:) encodes via JSONEncoder, producing .int(2)
        #expect(AnyCodableValue.from(Priority.medium) == .int(2))

        // Retrieval side: typed<T> decodes via JSONDecoder from the stored .int
        let result = AnyCodableValue.int(2).typed(Priority.self)
        #expect(result == .medium)
    }

    @Test("typed() and from(_:) round-trip Double-backed enums")
    func roundTripDoubleBackedEnum() {
        enum Scale: Double, Codable, Sendable { case half = 0.5, full = 1.0, double = 2.0 }

        // JSONDecoder decodes whole-number doubles as .int when there is no fractional
        // part (AnyCodableValue tries Int before Double in its Decodable init).
        // The important contract is the round-trip: from → typed recovers the original value.
        let stored = AnyCodableValue.from(Scale.full)
        let result = stored.typed(Scale.self)
        #expect(result == .full)

        // A value with a fractional part cannot be decoded as Int, so it is stored as .double.
        let storedHalf = AnyCodableValue.from(Scale.half)
        #expect(storedHalf == .double(0.5))
        #expect(storedHalf.typed(Scale.self) == .half)
    }

    @Test("from(_:) factory method")
    func fromFactory() {
        #expect(AnyCodableValue.from(true) == .bool(true))
        #expect(AnyCodableValue.from(42) == .int(42))
        #expect(AnyCodableValue.from(3.14) == .double(3.14))
        #expect(AnyCodableValue.from("hello") == .string("hello"))
        #expect(AnyCodableValue.from(referenceDate) == .date(referenceDate))
    }

    @Test("from(_:) converts Float to .double")
    func fromFloat() {
        // Float has a dedicated branch: Float → Double to avoid the JSON slow path.
        let value = AnyCodableValue.from(Float(1.5))
        #expect(value == .double(Double(Float(1.5))))
        #expect(value.typed(Double.self) == Double(Float(1.5)))
    }

    @Test("from(_:) calls failure handler and returns .null for unencodable types")
    func fromUnencodableType() {
        // A Codable type whose encode(to:) always throws — exercises the catch branch
        // and verifies the injected failure handler fires instead of assertionFailure.
        struct AlwaysFails: Codable, Sendable {
            func encode(to encoder: Encoder) throws {
                struct Boom: Error { }
                throw Boom()
            }

            init(from decoder: Decoder) throws { }
            init() { }
        }

        var capturedMessage: String?
        let previous = anyCodableValueEncodingFailure
        anyCodableValueEncodingFailure = { capturedMessage = $0 }
        defer { anyCodableValueEncodingFailure = previous }

        let result = AnyCodableValue.from(AlwaysFails())

        #expect(result == .null)
        #expect(capturedMessage?.contains("AlwaysFails") == true)
    }

    @Test("displayString output")
    func displayString() {
        #expect(AnyCodableValue.bool(true).displayString == "true")
        #expect(AnyCodableValue.int(5).displayString == "5")
        #expect(AnyCodableValue.string("abc").displayString == "abc")
        #expect(AnyCodableValue.null.displayString == "")
        // .date displayString is a non-empty ISO 8601 string
        let s = AnyCodableValue.date(referenceDate).displayString
        #expect(!s.isEmpty)
        #expect(s.contains("-")) // ISO 8601 contains hyphens
    }
}

// MARK: - FormValueStore Tests

@Suite("FormValueStore")
struct FormValueStoreTests {
    @Test("Set and get typed values")
    func setAndGetTypedValues() {
        var store = FormValueStore()
        store["name"] = .string("Alice")
        store["age"] = .int(30)
        store["active"] = .bool(true)

        let name: String? = store.value(for: "name")
        let age: Int? = store.value(for: "age")
        let active: Bool? = store.value(for: "active")

        #expect(name == "Alice")
        #expect(age == 30)
        #expect(active == true)
    }

    @Test("hasValue returns false for null and missing keys")
    func hasValue() {
        var store = FormValueStore()
        store["key1"] = .string("value")
        store["key2"] = .null

        #expect(store.hasValue(for: "key1") == true)
        #expect(store.hasValue(for: "key2") == false)
        #expect(store.hasValue(for: "missing") == false)
    }

    @Test("arrayContains works for multi-value rows")
    func arrayContains() {
        var store = FormValueStore()
        store["tags"] = .array([.string("swift"), .string("ios")])

        #expect(store.arrayContains(key: "tags", value: .string("swift")) == true)
        #expect(store.arrayContains(key: "tags", value: .string("android")) == false)
        #expect(store.arrayContains(key: "missing", value: .string("swift")) == false)
    }

    @Test("merge — other wins on conflict")
    func merge() {
        var store1 = FormValueStore(["a": .int(1), "b": .int(2)])
        let store2 = FormValueStore(["b": .int(99), "c": .int(3)])
        store1.merge(store2)

        #expect(store1["a"] == .int(1))
        #expect(store1["b"] == .int(99)) // store2 wins
        #expect(store1["c"] == .int(3))
    }

    @Test("removeValue removes the key")
    func removeValue() {
        var store = FormValueStore(["key": .string("value")])
        store.removeValue(for: "key")
        #expect(store["key"] == nil)
    }

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        var store = FormValueStore()
        store["name"] = .string("Bob")
        store["count"] = .int(5)
        store["flags"] = .array([.bool(true), .bool(false)])

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(store)
        let decoded = try decoder.decode(FormValueStore.self, from: data)

        #expect(decoded["name"] == AnyCodableValue.string("Bob"))
        #expect(decoded["count"] == AnyCodableValue.int(5))
        #expect(decoded["flags"] == AnyCodableValue.array([.bool(true), .bool(false)]))
    }

    @Test("setValue typed convenience")
    func setValueTyped() {
        var store = FormValueStore()
        store.setValue("hello", for: "text")
        store.setValue(42, for: "num")
        store.setValue(true, for: "flag")

        #expect(store["text"] == .string("hello"))
        #expect(store["num"] == .int(42))
        #expect(store["flag"] == .bool(true))
    }

    @Test("setValue nil sets .null")
    func setValueNil() {
        var store = FormValueStore()
        store.setValue(nil as String?, for: "key")
        #expect(store["key"] == .null)
        #expect(store.hasValue(for: "key") == false)
    }
}
