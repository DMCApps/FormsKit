import FormKit

// MARK: - ValidationForm

/// Demonstrates built-in validators and validation triggers.
enum ValidationForm {
    static let definition = FormDefinition(
        id: "validation",
        title: "Validation",
        saveBehaviour: .buttonNavigationBar()
    ) {
        // MARK: Triggers

        FormSection(id: "triggersSection", title: "Triggers") {
            TextInputRow(
                id: "onSaveTrigger",
                title: "onSave (default)",
                subtitle: "Error appears only when Save is tapped",
                placeholder: "Required",
                validators: [.required()]
            )

            TextInputRow(
                id: "onChangeTrigger",
                title: "onChange",
                subtitle: "Error appears on every keystroke",
                placeholder: "Required",
                validators: [.required(trigger: .onChange)]
            )

            TextInputRow(
                id: "onDebouncedTrigger",
                title: "onChangeDebounced",
                subtitle: "Error appears 0.5 s after you stop typing",
                placeholder: "Required",
                validators: [.required(trigger: .onChangeDebounced(seconds: 0.5))]
            )

            TextInputRow(
                id: "onBlurTrigger",
                title: "onBlur",
                subtitle: "Error appears when the field loses focus",
                placeholder: "Required",
                validators: [.required(trigger: .onBlur)]
            )
        }

        // MARK: Text Validators

        FormSection(id: "textValidatorsSection", title: "Text Validators") {
            TextInputRow(
                id: "requiredText",
                title: "required()",
                subtitle: "Field must not be empty",
                placeholder: "Cannot be blank",
                validators: [.required()]
            )

            TextInputRow(
                id: "emailText",
                title: "email()",
                subtitle: "Must be a valid email address",
                keyboardType: .emailAddress,
                placeholder: "you@example.com",
                validators: [.email()]
            )

            TextInputRow(
                id: "minLengthText",
                title: "minLength(5)",
                subtitle: "Must be at least 5 characters",
                placeholder: "At least 5 chars",
                validators: [.minLength(5)]
            )

            TextInputRow(
                id: "maxLengthText",
                title: "maxLength(10)",
                subtitle: "Must be 10 characters or fewer",
                placeholder: "Up to 10 chars",
                validators: [.maxLength(10)]
            )

            TextInputRow(
                id: "regexText",
                title: "regex()",
                subtitle: #"Pattern: ^\d{4}$ (4 digits)"#,
                placeholder: "e.g. 1234",
                validators: [.regex(#"^\d{4}$"#, message: "Must be exactly 4 digits")]
            )

            TextInputRow(
                id: "urlText",
                title: "url()",
                subtitle: "Must be a valid URL",
                keyboardType: .url,
                placeholder: "https://example.com",
                validators: [.url()]
            )

            TextInputRow(
                id: "ipv4Text",
                title: "ipv4()",
                subtitle: "Must be a valid IPv4 address",
                placeholder: "192.168.1.1",
                validators: [.ipv4()]
            )

            TextInputRow(
                id: "dateText",
                title: "date(format:)",
                subtitle: #"Format: "MM/dd/yyyy""#,
                placeholder: "01/31/2025",
                validators: [.date(format: "MM/dd/yyyy")]
            )
        }

        // MARK: Number Validators

        FormSection(id: "numberValidatorsSection", title: "Number Validators") {
            NumberInputRow(
                id: "rangeInt",
                title: "range(1...100)",
                subtitle: "Must be between 1 and 100",
                placeholder: "1–100",
                kind: .int(defaultValue: nil),
                validators: [.range(1 ... 100)]
            )

            NumberInputRow(
                id: "rangeDecimal",
                title: "range(0.0...9.99)",
                subtitle: "Must be between 0 and 9.99",
                placeholder: "0.00–9.99",
                kind: .decimal(defaultValue: nil),
                validators: [.range(0.0 ... 9.99)]
            )

            TextInputRow(
                id: "integerText",
                title: "integer()",
                subtitle: "Must be a whole number",
                placeholder: "e.g. 42",
                validators: [.integer()]
            )

            TextInputRow(
                id: "doubleText",
                title: "double()",
                subtitle: "Must be a valid decimal number",
                placeholder: "e.g. 3.14",
                validators: [.double()]
            )
        }

        // MARK: Cross-field Validators

        FormSection(id: "crossFieldSection", title: "Cross-field Validators") {
            TextInputRow(
                id: "password",
                title: "Password",
                subtitle: "Enter a password",
                isSecure: true,
                placeholder: "••••••••"
            )

            TextInputRow(
                id: "confirmPassword",
                title: "matches(rowId:)",
                subtitle: "Must match the Password field above",
                isSecure: true,
                placeholder: "Repeat password",
                validators: [.matches(rowId: "password", message: "Passwords do not match")]
            )
        }

        // MARK: Custom Validator

        FormSection(id: "customSection", title: "Custom Validator") {
            TextInputRow(
                id: "customText",
                title: "custom()",
                subtitle: "Must start with the letter 'A'",
                placeholder: "e.g. Apple",
                validators: [
                    .custom(message: "Must start with 'A'") { value in
                        guard case let .string(str) = value else { return false }
                        return str.hasPrefix("A") || str.hasPrefix("a")
                    }
                ]
            )
        }

        // MARK: Error Positions

        FormSection(id: "errorPositionSection", title: "Error Positions (preview)") {
            TextInputRow(
                id: "belowRowError",
                title: "belowRow (default)",
                placeholder: "Leave empty to see error",
                validators: [.required(errorPosition: .belowRow)]
            )

            TextInputRow(
                id: "formTopError",
                title: "formTop",
                placeholder: "Leave empty to see error",
                validators: [.required(errorPosition: .formTop)]
            )

            TextInputRow(
                id: "formBottomError",
                title: "formBottom",
                placeholder: "Leave empty to see error",
                validators: [.required(errorPosition: .formBottom)]
            )
        }
    }
}
