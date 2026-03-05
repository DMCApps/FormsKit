@testable import FormKit
import Foundation
import Testing

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
            .array([.int(1), .string("two"), .bool(false)]),
            .null
        ]

        for original in values {
            let data = try encoder.encode(original)
            let decoded = try decoder.decode(AnyCodableValue.self, from: data)
            #expect(decoded == original)
        }
    }

    @Test("Comparable ordering")
    func comparable() {
        #expect(AnyCodableValue.int(1) < .int(2))
        #expect(AnyCodableValue.double(1.5) < .double(2.5))
        #expect(AnyCodableValue.int(1) < .double(1.5))
        #expect(AnyCodableValue.double(0.9) < .int(1))
        #expect(AnyCodableValue.string("apple") < .string("banana"))
        // Incompatible types return false for <
        #expect((AnyCodableValue.bool(true) < .int(1)) == false)
    }

    @Test("Typed extraction")
    func typedExtraction() {
        #expect(AnyCodableValue.bool(true).typed(Bool.self) == true)
        #expect(AnyCodableValue.int(7).typed(Int.self) == 7)
        #expect(AnyCodableValue.double(2.5).typed(Double.self) == 2.5)
        #expect(AnyCodableValue.string("hi").typed(String.self) == "hi")
        // Int can also be extracted as Double
        #expect(AnyCodableValue.int(3).typed(Double.self) == 3.0)
    }

    @Test("from(_:) factory method")
    func fromFactory() {
        #expect(AnyCodableValue.from(true) == .bool(true))
        #expect(AnyCodableValue.from(42) == .int(42))
        #expect(AnyCodableValue.from(3.14) == .double(3.14))
        #expect(AnyCodableValue.from("hello") == .string("hello"))
    }

    @Test("displayString output")
    func displayString() {
        #expect(AnyCodableValue.bool(true).displayString == "true")
        #expect(AnyCodableValue.int(5).displayString == "5")
        #expect(AnyCodableValue.string("abc").displayString == "abc")
        #expect(AnyCodableValue.null.displayString == "")
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
