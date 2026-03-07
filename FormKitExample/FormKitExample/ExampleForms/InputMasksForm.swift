import FormKit

// MARK: - InputMasksForm

/// Demonstrates FormInputMask — phone, date, and custom pattern masks.
enum InputMasksForm {
    static let definition = FormDefinition(
        id: "inputMasks",
        title: "Input Masks",
        saveBehaviour: .buttonNavigationBar()
    ) {
        // MARK: Built-in presets

        FormSection(id: "presetsSection", title: "Built-in Presets") {
            TextInputRow(
                id: "usPhone",
                title: "US Phone — .usPhone",
                subtitle: "Pattern: (###) ###-####",
                placeholder: "(415) 555-1234",
                mask: .usPhone
            )

            TextInputRow(
                id: "dateField",
                title: "Date — .date",
                subtitle: "Pattern: ##/##/#### (MM/DD/YYYY)",
                mask: .date
            )
        }

        // MARK: Custom patterns

        FormSection(id: "customSection", title: "Custom Patterns") {
            TextInputRow(
                id: "postalCode",
                title: "Postal code",
                subtitle: "Pattern: \"A#A #A#\" (Canadian format)",
                mask: FormInputMask("A#A #A#")
            )

            TextInputRow(
                id: "creditCard",
                title: "Credit card number",
                subtitle: "Pattern: \"#### #### #### ####\"",
                mask: FormInputMask("#### #### #### ####")
            )

            TextInputRow(
                id: "referenceCode",
                title: "Reference code",
                subtitle: "Pattern: \"##-##-####\" (stored uppercased)",
                mask: FormInputMask(
                    "##-##-####",
                    toStorable: { rawChars in .string(rawChars) },
                    fromStorable: { stored in
                        if case let .string(s) = stored { return s }
                        return nil
                    }
                )
            )

            TextInputRow(
                id: "alphaNumeric",
                title: "Alphanumeric code",
                subtitle: "Pattern: \"AAA-###\" — 3 letters, dash, 3 digits",
                mask: FormInputMask("AAA-###")
            )
        }

        // MARK: Mask pattern reference

        FormSection(id: "referenceSection", title: "Pattern Character Reference") {
            InfoRow(id: "hashRef", title: "#") { "Any digit (0–9)" }
            InfoRow(id: "letterRef", title: "A") { "Any letter (a–z, A–Z)" }
            InfoRow(id: "wildcardRef", title: "*") { "Any character" }
            InfoRow(id: "literalRef", title: "other") { "Literal character — auto-inserted" }
        }

        // MARK: With validation

        FormSection(id: "validationSection", title: "Masks + Validation") {
            TextInputRow(
                id: "requiredPhone",
                title: "Required phone number",
                subtitle: "Must be fully entered",
                mask: .usPhone,
                validators: [.required(message: "Phone number is required")]
            )
        }
    }
}
