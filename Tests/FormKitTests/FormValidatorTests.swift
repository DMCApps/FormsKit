@testable import FormKit
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

    // MARK: - Custom error messages

    @Test("custom error messages are returned")
    func customErrorMessages() {
        let v = FormValidator.required(message: "Please fill this in")
        #expect(v.validate(nil) == "Please fill this in")
    }
}
