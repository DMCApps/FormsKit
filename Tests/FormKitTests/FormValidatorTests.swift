@testable import FormKit
import Foundation
import Testing

@Suite("FormValidator")
struct FormValidatorTests {
    // MARK: - Required

    @Test("required — nil fails")
    func requiredNilFails() {
        let v = FormValidator.required()
        #expect(v.validate(nil, FormValueStore()) != nil)
    }

    @Test("required — .null fails")
    func requiredNullFails() {
        let v = FormValidator.required()
        #expect(v.validate(.null, FormValueStore()) != nil)
    }

    @Test("required — empty string fails")
    func requiredEmptyStringFails() {
        let v = FormValidator.required()
        #expect(v.validate(.string(""), FormValueStore()) != nil)
        #expect(v.validate(.string("   "), FormValueStore()) != nil)
    }

    @Test("required — empty array fails")
    func requiredEmptyArrayFails() {
        let v = FormValidator.required()
        #expect(v.validate(.array([]), FormValueStore()) != nil)
    }

    @Test("required — valid values pass")
    func requiredValidPass() {
        let v = FormValidator.required()
        #expect(v.validate(.string("hello"), FormValueStore()) == nil)
        #expect(v.validate(.int(0), FormValueStore()) == nil)
        #expect(v.validate(.bool(false), FormValueStore()) == nil)
        #expect(v.validate(.array([.string("one")]), FormValueStore()) == nil)
    }

    // MARK: - Email

    @Test("email — valid addresses pass")
    func emailValid() {
        let v = FormValidator.email()
        #expect(v.validate(.string("user@example.com"), FormValueStore()) == nil)
        #expect(v.validate(.string("user+tag@sub.domain.org"), FormValueStore()) == nil)
    }

    @Test("email — invalid addresses fail")
    func emailInvalid() {
        let v = FormValidator.email()
        #expect(v.validate(.string("notanemail"), FormValueStore()) != nil)
        #expect(v.validate(.string("missing@tld"), FormValueStore()) != nil)
        #expect(v.validate(.string("@nodomain.com"), FormValueStore()) != nil)
    }

    @Test("email — empty string passes (not responsible for required)")
    func emailEmptyPasses() {
        let v = FormValidator.email()
        #expect(v.validate(.string(""), FormValueStore()) == nil)
        #expect(v.validate(nil, FormValueStore()) == nil)
    }

    // MARK: - minLength

    @Test("minLength")
    func minLength() {
        let v = FormValidator.minLength(5)
        #expect(v.validate(.string("hi"), FormValueStore()) != nil)
        #expect(v.validate(.string("hello"), FormValueStore()) == nil)
        #expect(v.validate(.string("longer"), FormValueStore()) == nil)
        #expect(v.validate(nil, FormValueStore()) == nil) // nil is not a string — not our responsibility
    }

    // MARK: - maxLength

    @Test("maxLength")
    func maxLength() {
        let v = FormValidator.maxLength(5)
        #expect(v.validate(.string("toolong"), FormValueStore()) != nil)
        #expect(v.validate(.string("hi"), FormValueStore()) == nil)
        #expect(v.validate(.string("hello"), FormValueStore()) == nil)
    }

    // MARK: - range (Double)

    @Test("range Double")
    func rangeDouble() {
        let v = FormValidator.range(1.0 ... 10.0)
        #expect(v.validate(.double(5.0), FormValueStore()) == nil)
        #expect(v.validate(.double(1.0), FormValueStore()) == nil)
        #expect(v.validate(.double(10.0), FormValueStore()) == nil)
        #expect(v.validate(.double(0.9), FormValueStore()) != nil)
        #expect(v.validate(.double(10.1), FormValueStore()) != nil)
        #expect(v.validate(.int(5), FormValueStore()) == nil) // Int coerced to Double
    }

    // MARK: - range (Int)

    @Test("range Int")
    func rangeInt() {
        let v = FormValidator.range(1 ... 10)
        #expect(v.validate(.int(5), FormValueStore()) == nil)
        #expect(v.validate(.int(1), FormValueStore()) == nil)
        #expect(v.validate(.int(11), FormValueStore()) != nil)
        #expect(v.validate(.string("5"), FormValueStore()) == nil) // non-int passes (not validated)
    }

    // MARK: - regex

    @Test("regex matching")
    func regexMatch() {
        let v = FormValidator.regex("^[0-9]{4}$", message: "Must be 4 digits")
        #expect(v.validate(.string("1234"), FormValueStore()) == nil)
        #expect(v.validate(.string("12345"), FormValueStore()) != nil)
        #expect(v.validate(.string("abcd"), FormValueStore()) != nil)
        #expect(v.validate(nil, FormValueStore()) == nil) // not a string — pass
    }

    // MARK: - custom

    @Test("custom validator")
    func customValidator() {
        let v = FormValidator.custom(message: "Must be positive") { value in
            guard let value, case let .int(i) = value else { return true }
            return i > 0
        }
        #expect(v.validate(.int(5), FormValueStore()) == nil)
        #expect(v.validate(.int(-1), FormValueStore()) != nil)
        #expect(v.validate(nil, FormValueStore()) == nil)
    }

    // MARK: - Trigger

    @Test("trigger type is preserved")
    func triggerPreserved() {
        let v1 = FormValidator.required(trigger: .onSave)
        let v2 = FormValidator.required(trigger: .onChange)
        let v3 = FormValidator.required(trigger: .onChangeDebounced(seconds: 0.5))

        #expect(v1.trigger == .onSave)
        #expect(v2.trigger == .onChange)
        #expect(v3.trigger == .onChangeDebounced(seconds: 0.5))
    }

    @Test("ValidationTrigger isChangeDebounced")
    func isChangeDebounced() {
        #expect(ValidationTrigger.onChangeDebounced(seconds: 0.3).isChangeDebounced == true)
        #expect(ValidationTrigger.onSave.isChangeDebounced == false)
        #expect(ValidationTrigger.onChange.isChangeDebounced == false)
        #expect(ValidationTrigger.onBlur.isChangeDebounced == false)
    }

    @Test("ValidationTrigger onBlur equality")
    func onBlurEquality() {
        #expect(ValidationTrigger.onBlur == .onBlur)
        #expect(ValidationTrigger.onBlur != .onSave)
        #expect(ValidationTrigger.onBlur != .onChange)
    }

    @Test("onBlur trigger is preserved on a created validator")
    func onBlurTriggerPreserved() {
        let v = FormValidator.required(trigger: .onBlur)
        #expect(v.trigger == .onBlur)
    }

    @Test("ValidationTrigger debounceDuration")
    func debounceDuration() {
        #expect(ValidationTrigger.onChangeDebounced(seconds: 1.5).debounceDuration == 1.5)
        #expect(ValidationTrigger.onSave.debounceDuration == nil)
    }

    @Test("Multi-trigger validator fires on any listed trigger")
    func multiTriggerValidator() {
        let v = FormValidator(triggers: [.onBlur, .onSave]) { _ in "error" }
        #expect(v.triggers.contains(.onBlur))
        #expect(v.triggers.contains(.onSave))
        #expect(!v.triggers.contains(.onChange))
        // Convenience accessor returns first trigger.
        #expect(v.trigger == .onBlur)
    }

    @Test("Single-trigger init wraps trigger in array")
    func singleTriggerWrapsInArray() {
        let v = FormValidator.required(trigger: .onChange)
        #expect(v.triggers == [.onChange])
        #expect(v.trigger == .onChange)
    }

    @Test("triggers: factory overloads store the full trigger array")
    func triggersFactoryStoresTriggerArray() {
        let triggers: [ValidationTrigger] = [.onBlur, .onSave]
        let validators: [FormValidator] = [
            .required(triggers: triggers),
            .email(triggers: triggers),
            .minLength(3, triggers: triggers),
            .maxLength(10, triggers: triggers),
            .regex(".*", triggers: triggers),
            .double(triggers: triggers),
            .ipv4(triggers: triggers),
            .date(triggers: triggers),
            .custom(message: "e", triggers: triggers) { _ in true },
            .url(triggers: triggers),
            .integer(triggers: triggers),
            .matches(rowId: "other", triggers: triggers)
        ]
        for v in validators {
            #expect(v.triggers.contains(.onBlur))
            #expect(v.triggers.contains(.onSave))
            #expect(v.triggers.count == 2)
        }
    }

    @Test("Single-trigger factory forwards same logic as multi-trigger factory")
    func singleTriggerForwardsToMultiTrigger() {
        let single = FormValidator.required(trigger: .onSave)
        let multi = FormValidator.required(triggers: [.onSave])
        let store = FormValueStore()
        #expect(single.validate(nil, store) != nil)
        #expect(multi.validate(nil, store) != nil)
        #expect(single.validate(.string("hello"), store) == nil)
        #expect(multi.validate(.string("hello"), store) == nil)
    }

    @Test("Array<ValidationTrigger>.isChangeDebounced")
    func arrayIsChangeDebounced() {
        #expect([ValidationTrigger.onSave, .onBlur].isChangeDebounced == false)
        #expect([ValidationTrigger.onChange].isChangeDebounced == false)
        #expect([ValidationTrigger.onChangeDebounced(seconds: 0.5)].isChangeDebounced == true)
        #expect([ValidationTrigger.onSave, .onChangeDebounced(seconds: 1.0)].isChangeDebounced == true)
        #expect([ValidationTrigger]().isChangeDebounced == false)
    }

    @Test("Array<ValidationTrigger>.debounceDuration returns longest duration")
    func arrayDebounceDuration() {
        #expect([ValidationTrigger.onSave].debounceDuration == nil)
        #expect([ValidationTrigger.onChangeDebounced(seconds: 0.5)].debounceDuration == 0.5)
        let mixed: [ValidationTrigger] = [.onChangeDebounced(seconds: 0.3), .onChangeDebounced(seconds: 1.5)]
        #expect(mixed.debounceDuration == 1.5)
    }

    // MARK: - double

    @Test("double — valid decimal strings pass")
    func doubleValidStringsPass() {
        let v = FormValidator.double()
        #expect(v.validate(.string("37.7833"), FormValueStore()) == nil)
        #expect(v.validate(.string("-122.4167"), FormValueStore()) == nil)
        #expect(v.validate(.string("0"), FormValueStore()) == nil)
        #expect(v.validate(.string("1e5"), FormValueStore()) == nil)
    }

    @Test("double — invalid strings fail")
    func doubleInvalidStringsFail() {
        let v = FormValidator.double()
        #expect(v.validate(.string("abc"), FormValueStore()) != nil)
        #expect(v.validate(.string("12.34.56"), FormValueStore()) != nil)
        #expect(v.validate(.string("--1"), FormValueStore()) != nil)
    }

    @Test("double — empty string passes (not responsible for required)")
    func doubleEmptyStringPasses() {
        let v = FormValidator.double()
        #expect(v.validate(.string(""), FormValueStore()) == nil)
        #expect(v.validate(nil, FormValueStore()) == nil)
    }

    @Test("double — non-string values pass through")
    func doubleNonStringPasses() {
        let v = FormValidator.double()
        #expect(v.validate(.int(5), FormValueStore()) == nil)
        #expect(v.validate(.bool(true), FormValueStore()) == nil)
    }

    @Test("double — custom message returned on failure")
    func doubleCustomMessage() {
        let v = FormValidator.double(message: "Bad number")
        #expect(v.validate(.string("nope"), FormValueStore()) == "Bad number")
    }

    // MARK: - ipv4

    @Test("ipv4 — valid addresses pass")
    func ipv4ValidAddressesPass() {
        let v = FormValidator.ipv4()
        #expect(v.validate(.string("192.168.1.1"), FormValueStore()) == nil)
        #expect(v.validate(.string("0.0.0.0"), FormValueStore()) == nil)
        #expect(v.validate(.string("255.255.255.255"), FormValueStore()) == nil)
        #expect(v.validate(.string("128.218.229.26"), FormValueStore()) == nil)
    }

    @Test("ipv4 — invalid format fails")
    func ipv4InvalidFormatFails() {
        let v = FormValidator.ipv4()
        #expect(v.validate(.string("999.999.999.999"), FormValueStore()) != nil) // octets out of range
        #expect(v.validate(.string("192.168.1"), FormValueStore()) != nil) // only 3 octets
        #expect(v.validate(.string("192.168.1.1.1"), FormValueStore()) != nil) // 5 octets
        #expect(v.validate(.string("abc.def.ghi.jkl"), FormValueStore()) != nil) // non-numeric
        #expect(v.validate(.string("192.168.1.256"), FormValueStore()) != nil) // octet > 255
    }

    @Test("ipv4 — empty string passes (not responsible for required)")
    func ipv4EmptyStringPasses() {
        let v = FormValidator.ipv4()
        #expect(v.validate(.string(""), FormValueStore()) == nil)
        #expect(v.validate(nil, FormValueStore()) == nil)
    }

    @Test("ipv4 — non-string values pass through")
    func ipv4NonStringPasses() {
        let v = FormValidator.ipv4()
        #expect(v.validate(.int(42), FormValueStore()) == nil)
        #expect(v.validate(.bool(false), FormValueStore()) == nil)
    }

    @Test("ipv4 — custom message returned on failure")
    func ipv4CustomMessage() {
        let v = FormValidator.ipv4(message: "Bad IP")
        #expect(v.validate(.string("notanip"), FormValueStore()) == "Bad IP")
    }

    // MARK: - date

    @Test("date — valid date string passes (raw mask format MMddyyyy)")
    func dateRawMaskFormatPasses() {
        let v = FormValidator.date(format: "MMddyyyy")
        #expect(v.validate(.string("12252026"), FormValueStore()) == nil)
        #expect(v.validate(.string("01012000"), FormValueStore()) == nil)
    }

    @Test("date — valid date string passes (pre-formatted MM/dd/yyyy)")
    func datePreformattedPasses() {
        let v = FormValidator.date(format: "MM/dd/yyyy")
        #expect(v.validate(.string("12/25/2026"), FormValueStore()) == nil)
        #expect(v.validate(.string("01/01/2000"), FormValueStore()) == nil)
    }

    @Test("date — invalid date fails (month 13)")
    func dateInvalidMonthFails() {
        let v = FormValidator.date(format: "MMddyyyy")
        #expect(v.validate(.string("13012026"), FormValueStore()) != nil)
    }

    @Test("date — invalid date fails (day 32)")
    func dateInvalidDayFails() {
        let v = FormValidator.date(format: "MMddyyyy")
        #expect(v.validate(.string("01322026"), FormValueStore()) != nil)
    }

    @Test("date — non-calendar date fails (Feb 30)")
    func dateNonCalendarDateFails() {
        let v = FormValidator.date(format: "MMddyyyy")
        #expect(v.validate(.string("02302026"), FormValueStore()) != nil)
    }

    @Test("date — non-numeric string fails")
    func dateNonNumericFails() {
        let v = FormValidator.date(format: "MMddyyyy")
        #expect(v.validate(.string("abcdefgh"), FormValueStore()) != nil)
    }

    @Test("date — empty string passes (not responsible for required)")
    func dateEmptyStringPasses() {
        let v = FormValidator.date(format: "MMddyyyy")
        #expect(v.validate(.string(""), FormValueStore()) == nil)
        #expect(v.validate(nil, FormValueStore()) == nil)
    }

    @Test("date — non-string values pass through")
    func dateNonStringPasses() {
        let v = FormValidator.date(format: "MMddyyyy")
        #expect(v.validate(.int(12252026), FormValueStore()) == nil)
        #expect(v.validate(.bool(true), FormValueStore()) == nil)
    }

    @Test("date — .date(Date) is always valid (typed date needs no parsing)")
    func dateCaseAlwaysPasses() {
        let v = FormValidator.date()
        #expect(v.validate(.date(Date()), FormValueStore()) == nil)
    }

    @Test("date — no format and string value passes through (not responsible for parsing)")
    func dateNoFormatStringPassesThrough() {
        let v = FormValidator.date()
        #expect(v.validate(.string("anything"), FormValueStore()) == nil)
    }

    @Test("date — custom message returned on failure")
    func dateCustomMessage() {
        let v = FormValidator.date(format: "MMddyyyy", message: "Enter a real date")
        #expect(v.validate(.string("99999999"), FormValueStore()) == "Enter a real date")
    }

    @Test("date — trigger is preserved")
    func dateTriggerPreserved() {
        let v = FormValidator.date(format: "MMddyyyy", trigger: .onChange)
        #expect(v.trigger == .onChange)
    }

    // MARK: - Custom error messages

    @Test("custom error messages are returned")
    func customErrorMessages() {
        let v = FormValidator.required(message: "Please fill this in")
        #expect(v.validate(nil, FormValueStore()) == "Please fill this in")
    }

    // MARK: - url

    @Test(".url passes for empty value")
    func urlPassesForEmpty() {
        let v = FormValidator.url()
        #expect(v.validate(nil, FormValueStore()) == nil)
        #expect(v.validate(.string(""), FormValueStore()) == nil)
    }

    @Test(".url passes for valid https URL")
    func urlPassesForValidURL() {
        let v = FormValidator.url()
        #expect(v.validate(.string("https://example.com"), FormValueStore()) == nil)
    }

    @Test(".url passes for valid http URL")
    func urlPassesForHTTP() {
        let v = FormValidator.url()
        #expect(v.validate(.string("http://192.168.1.1:8080/api"), FormValueStore()) == nil)
    }

    @Test(".url fails for bare string with no scheme")
    func urlFailsForNoScheme() {
        let v = FormValidator.url()
        #expect(v.validate(.string("not a url"), FormValueStore()) != nil)
    }

    @Test(".url fails for non-string value")
    func urlPassesForNonString() {
        let v = FormValidator.url()
        // non-string values are not URLs but the validator only checks strings
        #expect(v.validate(.int(42), FormValueStore()) == nil)
    }

    // MARK: - integer

    @Test(".integer passes for empty value")
    func integerPassesForEmpty() {
        let v = FormValidator.integer()
        #expect(v.validate(nil, FormValueStore()) == nil)
        #expect(v.validate(.string(""), FormValueStore()) == nil)
    }

    @Test(".integer passes for valid integer string")
    func integerPassesForValidInt() {
        let v = FormValidator.integer()
        #expect(v.validate(.string("42"), FormValueStore()) == nil)
        #expect(v.validate(.string("-7"), FormValueStore()) == nil)
        #expect(v.validate(.string("0"), FormValueStore()) == nil)
    }

    @Test(".integer fails for decimal string")
    func integerFailsForDecimal() {
        let v = FormValidator.integer()
        #expect(v.validate(.string("3.14"), FormValueStore()) != nil)
    }

    @Test(".integer fails for non-numeric string")
    func integerFailsForNonNumeric() {
        let v = FormValidator.integer()
        #expect(v.validate(.string("abc"), FormValueStore()) != nil)
    }

    // MARK: - matches

    @Test(".matches passes when values are equal")
    func matchesPassesWhenEqual() {
        let v = FormValidator.matches(rowId: "password")
        var store = FormValueStore()
        store["password"] = .string("secret")
        #expect(v.validate(.string("secret"), store) == nil)
    }

    @Test(".matches fails when values differ")
    func matchesFailsWhenDifferent() {
        let v = FormValidator.matches(rowId: "password")
        var store = FormValueStore()
        store["password"] = .string("secret")
        #expect(v.validate(.string("wrong"), store) != nil)
    }

    @Test(".matches passes when both values are nil")
    func matchesPassesWhenBothNil() {
        let v = FormValidator.matches(rowId: "password")
        let store = FormValueStore()
        #expect(v.validate(nil, store) == nil)
    }

    @Test(".matches RawRepresentable overload resolves rowId correctly")
    func matchesRawRepresentableRowId() {
        enum RowID: String { case password }
        let v = FormValidator.matches(rowId: RowID.password)
        var store = FormValueStore()
        store["password"] = .string("abc")
        #expect(v.validate(.string("abc"), store) == nil)
        #expect(v.validate(.string("xyz"), store) != nil)
    }

    // MARK: - SelectionValidator

    @Test("SelectionValidator.required always uses .onSave trigger")
    func selectionValidatorRequiredTriggerIsOnSave() {
        let v = SelectionValidator.required()
        #expect(v.asFormValidator.trigger == .onSave)
    }

    @Test("SelectionValidator.notEmpty always uses .onSave trigger")
    func selectionValidatorNotEmptyTriggerIsOnSave() {
        let v = SelectionValidator.notEmpty()
        #expect(v.asFormValidator.trigger == .onSave)
    }

    @Test("SelectionValidator.custom always uses .onSave trigger")
    func selectionValidatorCustomTriggerIsOnSave() {
        let v = SelectionValidator.custom(message: "Nope") { _ in false }
        #expect(v.asFormValidator.trigger == .onSave)
    }

    @Test("SelectionValidator.required fires on nil value")
    func selectionValidatorRequiredFailsOnNil() {
        let v = SelectionValidator.required()
        #expect(v.asFormValidator.validate(nil, FormValueStore()) != nil)
    }

    @Test("SelectionValidator.required passes on non-empty value")
    func selectionValidatorRequiredPassesOnValue() {
        let v = SelectionValidator.required()
        #expect(v.asFormValidator.validate(.string("dev"), FormValueStore()) == nil)
    }

    @Test("SelectionValidator.notEmpty uses custom message")
    func selectionValidatorNotEmptyCustomMessage() {
        let v = SelectionValidator.notEmpty(message: "Pick one")
        #expect(v.asFormValidator.validate(nil, FormValueStore()) == "Pick one")
    }

    @Test("SelectionValidator.custom uses provided predicate")
    func selectionValidatorCustomPredicate() {
        let v = SelectionValidator.custom(message: "Must be prod") { value in
            guard case let .string(s) = value else { return false }
            return s == "prod"
        }
        #expect(v.asFormValidator.validate(.string("prod"), FormValueStore()) == nil)
        #expect(v.asFormValidator.validate(.string("dev"), FormValueStore()) != nil)
    }

    @Test("BooleanSwitchRow accepts [SelectionValidator] and converts to [FormValidator]")
    func booleanSwitchRowAcceptsSelectionValidators() {
        let row = BooleanSwitchRow(
            id: "agree",
            title: "I Agree",
            validators: [.required(message: "You must agree")]
        )
        // The stored validators array should contain one FormValidator with .onSave trigger.
        #expect(row.validators.count == 1)
        #expect(row.validators[0].trigger == .onSave)
        #expect(row.validators[0].validate(nil, FormValueStore()) == "You must agree")
    }

    @Test("SingleValueRow accepts [SelectionValidator] and converts to [FormValidator]")
    func singleValueRowAcceptsSelectionValidators() {
        enum Env: String, CaseIterable, CustomStringConvertible, Hashable, Sendable, Codable {
            case dev, prod
            var description: String { rawValue }
        }
        let row = SingleValueRow<Env>(
            id: "env",
            title: "Environment",
            validators: [.notEmpty(message: "Select an environment")]
        )
        #expect(row.validators.count == 1)
        #expect(row.validators[0].trigger == .onSave)
        #expect(row.validators[0].validate(nil, FormValueStore()) == "Select an environment")
    }

    @Test("MultiValueRow accepts [SelectionValidator] and converts to [FormValidator]")
    func multiValueRowAcceptsSelectionValidators() {
        enum Tag: String, CaseIterable, CustomStringConvertible, Hashable, Sendable, Codable {
            case swift, ui
            var description: String { rawValue }
        }
        let row = MultiValueRow<Tag>(
            id: "tags",
            title: "Tags",
            validators: [.required(message: "Pick at least one")]
        )
        #expect(row.validators.count == 1)
        #expect(row.validators[0].trigger == .onSave)
        #expect(row.validators[0].validate(.array([]), FormValueStore()) == "Pick at least one")
    }
}
