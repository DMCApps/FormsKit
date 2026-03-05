@testable import FormKit
import Testing

@Suite("FormCondition")
struct FormConditionTests {
    // Helper to build a store quickly.
    private func store(_ dict: [String: AnyCodableValue]) -> FormValueStore {
        FormValueStore(dict)
    }

    @Test("equals")
    func testEquals() {
        let condition = FormCondition.equals(rowId: "env", value: .string("staging"))
        #expect(condition.evaluate(with: store(["env": .string("staging")])) == true)
        #expect(condition.evaluate(with: store(["env": .string("prod")])) == false)
        #expect(condition.evaluate(with: store([:])) == false)
    }

    @Test("notEquals")
    func testNotEquals() {
        let condition = FormCondition.notEquals(rowId: "env", value: .string("prod"))
        #expect(condition.evaluate(with: store(["env": .string("staging")])) == true)
        #expect(condition.evaluate(with: store(["env": .string("prod")])) == false)
    }

    @Test("contains")
    func testContains() {
        let condition = FormCondition.contains(rowId: "tags", value: .string("ios"))
        #expect(condition.evaluate(with: store(["tags": .array([.string("ios"), .string("swift")])])) == true)
        #expect(condition.evaluate(with: store(["tags": .array([.string("android")])])) == false)
        #expect(condition.evaluate(with: store([:])) == false)
    }

    @Test("notContains")
    func testNotContains() {
        let condition = FormCondition.notContains(rowId: "tags", value: .string("android"))
        #expect(condition.evaluate(with: store(["tags": .array([.string("ios")])])) == true)
        #expect(condition.evaluate(with: store(["tags": .array([.string("android")])])) == false)
    }

    @Test("greaterThan")
    func testGreaterThan() {
        let condition = FormCondition.greaterThan(rowId: "age", value: .int(18))
        #expect(condition.evaluate(with: store(["age": .int(21)])) == true)
        #expect(condition.evaluate(with: store(["age": .int(18)])) == false)
        #expect(condition.evaluate(with: store(["age": .int(10)])) == false)
    }

    @Test("greaterThanOrEqual")
    func testGreaterThanOrEqual() {
        let condition = FormCondition.greaterThanOrEqual(rowId: "score", value: .int(100))
        #expect(condition.evaluate(with: store(["score": .int(100)])) == true)
        #expect(condition.evaluate(with: store(["score": .int(101)])) == true)
        #expect(condition.evaluate(with: store(["score": .int(99)])) == false)
    }

    @Test("lessThan")
    func testLessThan() {
        let condition = FormCondition.lessThan(rowId: "temp", value: .double(37.5))
        #expect(condition.evaluate(with: store(["temp": .double(36.0)])) == true)
        #expect(condition.evaluate(with: store(["temp": .double(37.5)])) == false)
        #expect(condition.evaluate(with: store(["temp": .double(38.0)])) == false)
    }

    @Test("lessThanOrEqual")
    func testLessThanOrEqual() {
        let condition = FormCondition.lessThanOrEqual(rowId: "level", value: .int(5))
        #expect(condition.evaluate(with: store(["level": .int(5)])) == true)
        #expect(condition.evaluate(with: store(["level": .int(4)])) == true)
        #expect(condition.evaluate(with: store(["level": .int(6)])) == false)
    }

    @Test("isEmpty — null, empty string, empty array, missing")
    func testIsEmpty() {
        let condition = FormCondition.isEmpty(rowId: "field")
        #expect(condition.evaluate(with: store(["field": .null])) == true)
        #expect(condition.evaluate(with: store(["field": .string("")])) == true)
        #expect(condition.evaluate(with: store(["field": .array([])])) == true)
        #expect(condition.evaluate(with: store([:])) == true)
        #expect(condition.evaluate(with: store(["field": .string("value")])) == false)
        #expect(condition.evaluate(with: store(["field": .int(0)])) == false)
    }

    @Test("isNotEmpty")
    func testIsNotEmpty() {
        let condition = FormCondition.isNotEmpty(rowId: "field")
        #expect(condition.evaluate(with: store(["field": .string("hello")])) == true)
        #expect(condition.evaluate(with: store(["field": .null])) == false)
        #expect(condition.evaluate(with: store([:])) == false)
    }

    @Test("isTrue / isFalse")
    func testBoolShorthand() {
        #expect(FormCondition.isTrue(rowId: "toggle").evaluate(with: store(["toggle": .bool(true)])) == true)
        #expect(FormCondition.isTrue(rowId: "toggle").evaluate(with: store(["toggle": .bool(false)])) == false)
        #expect(FormCondition.isFalse(rowId: "toggle").evaluate(with: store(["toggle": .bool(false)])) == true)
        #expect(FormCondition.isFalse(rowId: "toggle").evaluate(with: store([:])) == true)
    }

    @Test("custom predicate")
    func testCustom() {
        let condition = FormCondition.custom { store in
            store.hasValue(for: "a") && store.hasValue(for: "b")
        }
        #expect(condition.evaluate(with: store(["a": .int(1), "b": .int(2)])) == true)
        #expect(condition.evaluate(with: store(["a": .int(1)])) == false)
    }

    @Test(".and — all conditions must pass")
    func testAnd() {
        let condition = FormCondition.and([
            .equals(rowId: "env", value: .string("dev")),
            .isTrue(rowId: "debug")
        ])
        let matching = store(["env": .string("dev"), "debug": .bool(true)])
        let partial = store(["env": .string("dev"), "debug": .bool(false)])
        let empty = store([:])

        #expect(condition.evaluate(with: matching) == true)
        #expect(condition.evaluate(with: partial) == false)
        #expect(condition.evaluate(with: empty) == false)
    }

    @Test(".or — at least one condition must pass")
    func testOr() {
        let condition = FormCondition.or([
            .equals(rowId: "env", value: .string("dev")),
            .equals(rowId: "env", value: .string("staging"))
        ])
        #expect(condition.evaluate(with: store(["env": .string("dev")])) == true)
        #expect(condition.evaluate(with: store(["env": .string("staging")])) == true)
        #expect(condition.evaluate(with: store(["env": .string("prod")])) == false)
    }

    @Test(".not — inverts the condition")
    func testNot() {
        let condition = FormCondition.not(.isTrue(rowId: "enabled"))
        #expect(condition.evaluate(with: store(["enabled": .bool(false)])) == true)
        #expect(condition.evaluate(with: store(["enabled": .bool(true)])) == false)
    }

    @Test("Nested and/or composition")
    func testNestedComposition() {
        // (env == "dev" OR env == "staging") AND debug == true
        let condition = FormCondition.and([
            .or([
                .equals(rowId: "env", value: .string("dev")),
                .equals(rowId: "env", value: .string("staging"))
            ]),
            .isTrue(rowId: "debug")
        ])

        #expect(condition.evaluate(with: store(["env": .string("dev"), "debug": .bool(true)])) == true)
        #expect(condition.evaluate(with: store(["env": .string("staging"), "debug": .bool(true)])) == true)
        #expect(condition.evaluate(with: store(["env": .string("prod"), "debug": .bool(true)])) == false)
        #expect(condition.evaluate(with: store(["env": .string("dev"), "debug": .bool(false)])) == false)
    }

    @Test("Convenience string/int/bool factory methods")
    func testConvenienceFactories() {
        let s = FormCondition.equals(rowId: "x", string: "hello")
        let i = FormCondition.equals(rowId: "x", int: 5)
        let b = FormCondition.equals(rowId: "x", bool: true)

        #expect(s.evaluate(with: store(["x": .string("hello")])) == true)
        #expect(i.evaluate(with: store(["x": .int(5)])) == true)
        #expect(b.evaluate(with: store(["x": .bool(true)])) == true)
    }
}
