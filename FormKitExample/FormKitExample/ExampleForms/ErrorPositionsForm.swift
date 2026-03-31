import FormsKit

// MARK: - ErrorPositionsForm

/// Demonstrates all ErrorPosition cases: belowRow, formTop, formBottom, and alert.
enum ErrorPositionsForm {
    static let definition = FormDefinition(
        id: "errorPositions",
        title: "Error Positions",
        saveBehaviour: .none
    ) {
        InfoRow(id: "intro", title: "How to use") {
            "Tap a row to open a sub-form. Leave fields empty and tap Save to see where errors appear."
        }

        FormSection(id: "positionsSection", title: "Tap a row to see each error position") {
            // MARK: belowRow

            NavigationRow(
                id: "belowRowExample",
                title: ".belowRow (default)",
                subtitle: "Errors appear directly below the invalid field",
                destination: FormDefinition(
                    id: "errorPositions.belowRow",
                    title: "Below Row",
                    saveBehaviour: .buttonNavigationBar()
                ) {
                    InfoRow(id: "hint", title: "Error position") { "ErrorPosition.belowRow" }

                    TextInputRow(
                        id: "field1",
                        title: "Required field",
                        subtitle: "Leave empty and tap Save",
                        placeholder: "Cannot be blank",
                        validators: [.required(errorPosition: .belowRow)]
                    )

                    TextInputRow(
                        id: "field2",
                        title: "Email field",
                        subtitle: "Enter an invalid email and tap Save",
                        keyboardType: .emailAddress,
                        placeholder: "you@example.com",
                        validators: [.email(errorPosition: .belowRow)]
                    )
                }
            )

            // MARK: formTop

            NavigationRow(
                id: "formTopExample",
                title: ".formTop",
                subtitle: "Errors appear in a banner at the top of the form",
                destination: FormDefinition(
                    id: "errorPositions.formTop",
                    title: "Form Top",
                    saveBehaviour: .buttonNavigationBar()
                ) {
                    InfoRow(id: "hint", title: "Error position") { "ErrorPosition.formTop" }

                    TextInputRow(
                        id: "field1",
                        title: "Required field",
                        subtitle: "Leave empty and tap Save",
                        placeholder: "Cannot be blank",
                        validators: [.required(errorPosition: .formTop)]
                    )

                    TextInputRow(
                        id: "field2",
                        title: "Email field",
                        subtitle: "Enter an invalid email and tap Save",
                        keyboardType: .emailAddress,
                        placeholder: "you@example.com",
                        validators: [.email(errorPosition: .formTop)]
                    )
                }
            )

            // MARK: formBottom

            NavigationRow(
                id: "formBottomExample",
                title: ".formBottom",
                subtitle: "Errors appear in a banner at the bottom of the form",
                destination: FormDefinition(
                    id: "errorPositions.formBottom",
                    title: "Form Bottom",
                    saveBehaviour: .buttonNavigationBar()
                ) {
                    InfoRow(id: "hint", title: "Error position") { "ErrorPosition.formBottom" }

                    TextInputRow(
                        id: "field1",
                        title: "Required field",
                        subtitle: "Leave empty and tap Save",
                        placeholder: "Cannot be blank",
                        validators: [.required(errorPosition: .formBottom)]
                    )

                    TextInputRow(
                        id: "field2",
                        title: "Email field",
                        subtitle: "Enter an invalid email and tap Save",
                        keyboardType: .emailAddress,
                        placeholder: "you@example.com",
                        validators: [.email(errorPosition: .formBottom)]
                    )
                }
            )

            // MARK: alert

            NavigationRow(
                id: "alertExample",
                title: ".alert",
                subtitle: "Errors appear in a dismissible alert dialog",
                destination: FormDefinition(
                    id: "errorPositions.alert",
                    title: "Alert",
                    saveBehaviour: .buttonNavigationBar()
                ) {
                    InfoRow(id: "hint", title: "Error position") { "ErrorPosition.alert" }

                    TextInputRow(
                        id: "field1",
                        title: "Required field",
                        subtitle: "Leave empty and tap Save",
                        placeholder: "Cannot be blank",
                        validators: [.required(errorPosition: .alert)]
                    )

                    TextInputRow(
                        id: "field2",
                        title: "Email field",
                        subtitle: "Enter an invalid email and tap Save",
                        keyboardType: .emailAddress,
                        placeholder: "you@example.com",
                        validators: [.email(errorPosition: .alert)]
                    )
                }
            )

            // MARK: Mixed positions

            NavigationRow(
                id: "mixedExample",
                title: "Mixed positions",
                subtitle: "Different error positions on different fields",
                destination: FormDefinition(
                    id: "errorPositions.mixed",
                    title: "Mixed",
                    saveBehaviour: .buttonNavigationBar()
                ) {
                    InfoRow(id: "hint", title: "Error positions") { "belowRow + formTop + alert" }

                    TextInputRow(
                        id: "below",
                        title: "Below row error",
                        placeholder: "Required",
                        validators: [.required(errorPosition: .belowRow)]
                    )

                    TextInputRow(
                        id: "top",
                        title: "Form top error",
                        placeholder: "Required",
                        validators: [.required(errorPosition: .formTop)]
                    )

                    TextInputRow(
                        id: "alerted",
                        title: "Alert error",
                        placeholder: "Required",
                        validators: [.required(errorPosition: .alert)]
                    )
                }
            )
        }
    }
}
