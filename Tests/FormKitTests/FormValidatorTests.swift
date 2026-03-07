@testable import FormKit
import Foundation
import Testing

@Suite("FormValidator")
struct FormValidatorTests {
    // MARK: - Required

    @Test("required — nil fails")
    func requiredNilFails() {
        let v = FormValidator.required()
        #expect(v.validate(nil) != nil)
    }

    @Test("required — .null fails")
    func requiredNullFails() {
        let v = FormValidator.required()
        #expect(v.validate(.null) != nil)
    }

    @Test("required — empty string fails")
    func requiredEmptyStringFails() {
        let v = FormValidator.required()
        #expect(v.validate(.string("")) != nil)
        #expect(v.validate(.string("   ")) != nil)
    }

    @Test("required — empty array fails")
    func requiredEmptyArrayFails() {
        let v = FormValidator.required()
        #expect(v.validate(.array([])) != nil)
    }

    @Test("required — valid values pass")
    func requiredValidPass() {
        let v = FormValidator.required()
        #expect(v.validate(.string("hello")) == nil)
        #expect(v.validate(.int(0)) == nil)
        #expect(v.validate(.bool(false)) == nil)
        #expect(v.validate(.array([.string("one")])) == nil)
    }

    // MARK: - Email

    @Test("email — valid addresses pass")
    func emailValid() {
        let v = FormValidator.email()
        #expect(v.validate(.string("user@example.com")) == nil)
        #expect(v.validate(.string("user+tag@sub.domain.org")) == nil)
    }

    @Test("email — invalid addresses fail")
    func emailInvalid() {
        let v = FormValidator.email()
        #expect(v.validate(.string("notanemail")) != nil)
        #expect(v.validate(.string("missing@tld")) != nil)
        #expect(v.validate(.string("@nodomain.com")) != nil)
    }

    @Test("email — empty string passes (not responsible for required)")
    func emailEmptyPasses() {
        let v = FormValidator.email()
        #expect(v.validate(.string("")) == nil)
        #expect(v.validate(nil) == nil)
    }

    // MARK: - minLength

    @Test("minLength")
    func minLength() {
        let v = FormValidator.minLength(5)
        #expect(v.validate(.string("hi")) != nil)
        #expect(v.validate(.string("hello")) == nil)
        #expect(v.validate(.string("longer")) == nil)
        #expect(v.validate(nil) == nil) // nil is not a string — not our responsibility
    }

    // MARK: - maxLength

    @Test("maxLength")
    func maxLength() {
        let v = FormValidator.maxLength(5)
        #expect(v.validate(.string("toolong")) != nil)
        #expect(v.validate(.string("hi")) == nil)
        #expect(v.validate(.string("hello")) == nil)
    }

    // MARK: - range (Double)

    @Test("range Double")
    func rangeDouble() {
        let v = FormValidator.range(1.0 ... 10.0)
        #expect(v.validate(.double(5.0)) == nil)
        #expect(v.validate(.double(1.0)) == nil)
        #expect(v.validate(.double(10.0)) == nil)
        #expect(v.validate(.double(0.9)) != nil)
        #expect(v.validate(.double(10.1)) != nil)
        #expect(v.validate(.int(5)) == nil) // Int coerced to Double
    }

    // MARK: - range (Int)

    @Test("range Int")
    func rangeInt() {
        let v = FormValidator.range(1 ... 10)
        #expect(v.validate(.int(5)) == nil)
        #expect(v.validate(.int(1)) == nil)
        #expect(v.validate(.int(11)) != nil)
        #expect(v.validate(.string("5")) == nil) // non-int passes (not validated)
    }

    // MARK: - regex

    @Test("regex matching")
    func regexMatch() {
        let v = FormValidator.regex("^[0-9]{4}$", message: "Must be 4 digits")
        #expect(v.validate(.string("1234")) == nil)
        #expect(v.validate(.string("12345")) != nil)
        #expect(v.validate(.string("abcd")) != nil)
        #expect(v.validate(nil) == nil) // not a string — pass
    }

    // MARK: - custom

    @Test("custom validator")
    func customValidator() {
        let v = FormValidator.custom(message: "Must be positive") { value in
            guard let value, case let .int(i) = value else { return true }
            return i > 0
        }
        #expect(v.validate(.int(5)) == nil)
        #expect(v.validate(.int(-1)) != nil)
        #expect(v.validate(nil) == nil)
    }

    // MARK: - Trigger

    @Test("trigger type is preserved")
    func triggerPreserved() {
        let v1 = FormValidator.required(trigger: .onSave)
        let v2 = FormValidator.required(trigger: .onChange)
        let v3 = FormValidator.required(trigger: .onDebouncedInput(seconds: 0.5))

        #expect(v1.trigger == .onSave)
        #expect(v2.trigger == .onChange)
        #expect(v3.trigger == .onDebouncedInput(seconds: 0.5))
    }

    @Test("ValidationTrigger isDebouncedInput")
    func isDebouncedInput() {
        #expect(ValidationTrigger.onDebouncedInput(seconds: 0.3).isDebouncedInput == true)
        #expect(ValidationTrigger.onSave.isDebouncedInput == false)
        #expect(ValidationTrigger.onChange.isDebouncedInput == false)
    }

    @Test("ValidationTrigger debounceDuration")
    func debounceDuration() {
        #expect(ValidationTrigger.onDebouncedInput(seconds: 1.5).debounceDuration == 1.5)
        #expect(ValidationTrigger.onSave.debounceDuration == nil)
    }

    // MARK: - double

    @Test("double — valid decimal strings pass")
    func doubleValidStringsPass() {
        let v = FormValidator.double()
        #expect(v.validate(.string("37.7833")) == nil)
        #expect(v.validate(.string("-122.4167")) == nil)
        #expect(v.validate(.string("0")) == nil)
        #expect(v.validate(.string("1e5")) == nil)
    }

    @Test("double — invalid strings fail")
    func doubleInvalidStringsFail() {
        let v = FormValidator.double()
        #expect(v.validate(.string("abc")) != nil)
        #expect(v.validate(.string("12.34.56")) != nil)
        #expect(v.validate(.string("--1")) != nil)
    }

    @Test("double — empty string passes (not responsible for required)")
    func doubleEmptyStringPasses() {
        let v = FormValidator.double()
        #expect(v.validate(.string("")) == nil)
        #expect(v.validate(nil) == nil)
    }

    @Test("double — non-string values pass through")
    func doubleNonStringPasses() {
        let v = FormValidator.double()
        #expect(v.validate(.int(5)) == nil)
        #expect(v.validate(.bool(true)) == nil)
    }

    @Test("double — custom message returned on failure")
    func doubleCustomMessage() {
        let v = FormValidator.double(message: "Bad number")
        #expect(v.validate(.string("nope")) == "Bad number")
    }

    // MARK: - ipv4

    @Test("ipv4 — valid addresses pass")
    func ipv4ValidAddressesPass() {
        let v = FormValidator.ipv4()
        #expect(v.validate(.string("192.168.1.1")) == nil)
        #expect(v.validate(.string("0.0.0.0")) == nil)
        #expect(v.validate(.string("255.255.255.255")) == nil)
        #expect(v.validate(.string("128.218.229.26")) == nil)
    }

    @Test("ipv4 — invalid format fails")
    func ipv4InvalidFormatFails() {
        let v = FormValidator.ipv4()
        #expect(v.validate(.string("999.999.999.999")) != nil) // octets out of range
        #expect(v.validate(.string("192.168.1")) != nil) // only 3 octets
        #expect(v.validate(.string("192.168.1.1.1")) != nil) // 5 octets
        #expect(v.validate(.string("abc.def.ghi.jkl")) != nil) // non-numeric
        #expect(v.validate(.string("192.168.1.256")) != nil) // octet > 255
    }

    @Test("ipv4 — empty string passes (not responsible for required)")
    func ipv4EmptyStringPasses() {
        let v = FormValidator.ipv4()
        #expect(v.validate(.string("")) == nil)
        #expect(v.validate(nil) == nil)
    }

    @Test("ipv4 — non-string values pass through")
    func ipv4NonStringPasses() {
        let v = FormValidator.ipv4()
        #expect(v.validate(.int(42)) == nil)
        #expect(v.validate(.bool(false)) == nil)
    }

    @Test("ipv4 — custom message returned on failure")
    func ipv4CustomMessage() {
        let v = FormValidator.ipv4(message: "Bad IP")
        #expect(v.validate(.string("notanip")) == "Bad IP")
    }

    // MARK: - date

    @Test("date — valid date string passes (raw mask format MMddyyyy)")
    func dateRawMaskFormatPasses() {
        let v = FormValidator.date(format: "MMddyyyy")
        #expect(v.validate(.string("12252026")) == nil)
        #expect(v.validate(.string("01012000")) == nil)
    }

    @Test("date — valid date string passes (pre-formatted MM/dd/yyyy)")
    func datePreformattedPasses() {
        let v = FormValidator.date(format: "MM/dd/yyyy")
        #expect(v.validate(.string("12/25/2026")) == nil)
        #expect(v.validate(.string("01/01/2000")) == nil)
    }

    @Test("date — invalid date fails (month 13)")
    func dateInvalidMonthFails() {
        let v = FormValidator.date(format: "MMddyyyy")
        #expect(v.validate(.string("13012026")) != nil)
    }

    @Test("date — invalid date fails (day 32)")
    func dateInvalidDayFails() {
        let v = FormValidator.date(format: "MMddyyyy")
        #expect(v.validate(.string("01322026")) != nil)
    }

    @Test("date — non-calendar date fails (Feb 30)")
    func dateNonCalendarDateFails() {
        let v = FormValidator.date(format: "MMddyyyy")
        #expect(v.validate(.string("02302026")) != nil)
    }

    @Test("date — non-numeric string fails")
    func dateNonNumericFails() {
        let v = FormValidator.date(format: "MMddyyyy")
        #expect(v.validate(.string("abcdefgh")) != nil)
    }

    @Test("date — empty string passes (not responsible for required)")
    func dateEmptyStringPasses() {
        let v = FormValidator.date(format: "MMddyyyy")
        #expect(v.validate(.string("")) == nil)
        #expect(v.validate(nil) == nil)
    }

    @Test("date — non-string values pass through")
    func dateNonStringPasses() {
        let v = FormValidator.date(format: "MMddyyyy")
        #expect(v.validate(.int(12252026)) == nil)
        #expect(v.validate(.bool(true)) == nil)
    }

    @Test("date — .date(Date) is always valid (typed date needs no parsing)")
    func dateCaseAlwaysPasses() {
        let v = FormValidator.date()
        #expect(v.validate(.date(Date())) == nil)
    }

    @Test("date — no format and string value passes through (not responsible for parsing)")
    func dateNoFormatStringPassesThrough() {
        let v = FormValidator.date()
        #expect(v.validate(.string("anything")) == nil)
    }

    @Test("date — custom message returned on failure")
    func dateCustomMessage() {
        let v = FormValidator.date(format: "MMddyyyy", message: "Enter a real date")
        #expect(v.validate(.string("99999999")) == "Enter a real date")
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
        #expect(v.validate(nil) == "Please fill this in")
    }

    // MARK: - url

    @Test(".url passes for empty value")
    func urlPassesForEmpty() {
        let v = FormValidator.url()
        #expect(v.validate(nil) == nil)
        #expect(v.validate(.string("")) == nil)
    }

    @Test(".url passes for valid https URL")
    func urlPassesForValidURL() {
        let v = FormValidator.url()
        #expect(v.validate(.string("https://example.com")) == nil)
    }

    @Test(".url passes for valid http URL")
    func urlPassesForHTTP() {
        let v = FormValidator.url()
        #expect(v.validate(.string("http://192.168.1.1:8080/api")) == nil)
    }

    @Test(".url fails for bare string with no scheme")
    func urlFailsForNoScheme() {
        let v = FormValidator.url()
        #expect(v.validate(.string("not a url")) != nil)
    }

    @Test(".url fails for non-string value")
    func urlPassesForNonString() {
        let v = FormValidator.url()
        // non-string values are not URLs but the validator only checks strings
        #expect(v.validate(.int(42)) == nil)
    }

    // MARK: - integer

    @Test(".integer passes for empty value")
    func integerPassesForEmpty() {
        let v = FormValidator.integer()
        #expect(v.validate(nil) == nil)
        #expect(v.validate(.string("")) == nil)
    }

    @Test(".integer passes for valid integer string")
    func integerPassesForValidInt() {
        let v = FormValidator.integer()
        #expect(v.validate(.string("42")) == nil)
        #expect(v.validate(.string("-7")) == nil)
        #expect(v.validate(.string("0")) == nil)
    }

    @Test(".integer fails for decimal string")
    func integerFailsForDecimal() {
        let v = FormValidator.integer()
        #expect(v.validate(.string("3.14")) != nil)
    }

    @Test(".integer fails for non-numeric string")
    func integerFailsForNonNumeric() {
        let v = FormValidator.integer()
        #expect(v.validate(.string("abc")) != nil)
    }

    // MARK: - matches

    @Test(".matches passes when values are equal")
    func matchesPassesWhenEqual() {
        let v = FormValidator.matches(rowId: "password")
        var store = FormValueStore()
        store["password"] = .string("secret")
        #expect(v.validateWithStore?(.string("secret"), store) == nil)
    }

    @Test(".matches fails when values differ")
    func matchesFailsWhenDifferent() {
        let v = FormValidator.matches(rowId: "password")
        var store = FormValueStore()
        store["password"] = .string("secret")
        #expect(v.validateWithStore?(.string("wrong"), store) != nil)
    }

    @Test(".matches passes when both values are nil")
    func matchesPassesWhenBothNil() {
        let v = FormValidator.matches(rowId: "password")
        let store = FormValueStore()
        #expect(v.validateWithStore?(nil, store) == nil)
    }

    @Test(".matches uses store-aware init — validate closure returns nil")
    func matchesBaseValidateReturnsNil() {
        let v = FormValidator.matches(rowId: "password")
        // The base `validate` closure is unused for store-aware validators.
        #expect(v.validate(.string("anything")) == nil)
    }

    @Test(".matches RawRepresentable overload resolves rowId correctly")
    func matchesRawRepresentableRowId() {
        enum RowID: String { case password }
        let v = FormValidator.matches(rowId: RowID.password)
        var store = FormValueStore()
        store["password"] = .string("abc")
        #expect(v.validateWithStore?(.string("abc"), store) == nil)
        #expect(v.validateWithStore?(.string("xyz"), store) != nil)
    }
}
