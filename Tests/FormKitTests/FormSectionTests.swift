@testable import FormKit
import Testing

// MARK: - FormSection Construction Tests

@Suite("FormSection Construction")
struct FormSectionConstructionTests {
    @Test("FormSection stores id and title")
    func formSectionStoresIdAndTitle() {
        let section = FormSection(id: "my-section", title: "My Section", rows: [])
        #expect(section.id == "my-section")
        #expect(section.title == "My Section")
    }

    @Test("FormSection stores child rows")
    func formSectionStoresChildRows() {
        let rows: [AnyFormRow] = [
            AnyFormRow(BooleanSwitchRow(id: "toggle", title: "Toggle")),
            AnyFormRow(TextInputRow(id: "name", title: "Name"))
        ]
        let section = FormSection(id: "s", title: "S", rows: rows)
        #expect(section.rows.count == 2)
        #expect(section.rows[0].id == "toggle")
        #expect(section.rows[1].id == "name")
    }

    @Test("FormSection builder DSL collects child rows")
    func formSectionBuilderDSL() {
        let section = FormSection(id: "account", title: "Account") {
            TextInputRow(id: "name", title: "Name")
            EmailInputRow(id: "email", title: "Email")
        }
        #expect(section.rows.count == 2)
        #expect(section.rows[0].id == "name")
        #expect(section.rows[1].id == "email")
    }

    @Test("FormSection stores onChange actions")
    func formSectionStoresOnChangeActions() {
        let section = FormSection(
            id: "advanced",
            title: "Advanced",
            rows: [],
            onChange: [.showRow(id: "advanced", when: [.isTrue(rowId: "enabled")])]
        )
        #expect(section.onChange.count == 1)
    }

    @Test("FormSection RawRepresentable id overload with array rows")
    func formSectionRawRepresentableIdArrayRows() {
        enum SectionID: String { case details = "user_details" }
        let section = FormSection(id: SectionID.details, title: "Details", rows: [])
        #expect(section.id == "user_details")
    }

    @Test("FormSection RawRepresentable id overload with builder DSL")
    func formSectionRawRepresentableIdBuilder() {
        enum SectionID: String { case advanced = "advanced_settings" }
        let section = FormSection(id: SectionID.advanced, title: "Advanced") {
            BooleanSwitchRow(id: "flag", title: "Flag")
        }
        #expect(section.id == "advanced_settings")
        #expect(section.rows.count == 1)
    }
}

// MARK: - FormSection Protocol Defaults Tests

@Suite("FormSection Protocol Defaults")
struct FormSectionProtocolDefaultsTests {
    @Test("FormSection has nil subtitle")
    func formSectionHasNilSubtitle() {
        let section = FormSection(id: "s", title: "S", rows: [])
        #expect(section.subtitle == nil)
    }

    @Test("FormSection has no validators")
    func formSectionHasNoValidators() {
        let section = FormSection(id: "s", title: "S", rows: [])
        #expect(section.validators.isEmpty)
    }

    @Test("FormSection has nil defaultValue")
    func formSectionHasNilDefaultValue() {
        let section = FormSection(id: "s", title: "S", rows: [])
        #expect(section.defaultValue == nil)
    }

    @Test("FormSection has empty onChange by default")
    func formSectionHasEmptyOnChangeByDefault() {
        let section = FormSection(id: "s", title: "S", rows: [])
        #expect(section.onChange.isEmpty)
    }
}

// MARK: - AnyFormRow Wrapping Tests

@Suite("FormSection AnyFormRow Wrapping")
struct FormSectionAnyFormRowWrappingTests {
    @Test("AnyFormRow wraps FormSection and casts back correctly")
    func anyFormRowWrapsFormSection() {
        let section = FormSection(id: "sect", title: "Section") {
            TextInputRow(id: "name", title: "Name")
        }
        let anyRow = AnyFormRow(section)
        let cast = anyRow.asType(FormSection.self)
        #expect(cast != nil)
        #expect(cast?.id == "sect")
        #expect(cast?.title == "Section")
        #expect(cast?.rows.count == 1)
    }

    @Test("AnyFormRow wrapping FormSection carries id and title")
    func anyFormRowSectionCarriesMetadata() {
        let section = FormSection(id: "meta", title: "Meta", rows: [])
        let anyRow = AnyFormRow(section)
        #expect(anyRow.id == "meta")
        #expect(anyRow.title == "Meta")
    }
}

// MARK: - FormSection in FormDefinition DSL Tests

@Suite("FormSection in FormDefinition DSL")
struct FormSectionInFormDefinitionTests {
    @Test("FormSection used in FormDefinition builder DSL")
    func formSectionInFormDefinitionDSL() {
        let form = FormDefinition(id: "test", title: "Test", saveBehaviour: .none) {
            BooleanSwitchRow(id: "top", title: "Top Level")
            FormSection(id: "details", title: "Details") {
                TextInputRow(id: "name", title: "Name")
                EmailInputRow(id: "email", title: "Email")
            }
        }
        #expect(form.rows.count == 2)
        #expect(form.rows[0].id == "top")
        #expect(form.rows[1].id == "details")
        let section = form.rows[1].asType(FormSection.self)
        #expect(section?.rows.count == 2)
    }

    @Test("FormSection does not contribute its own id to FormViewModel value store")
    func formSectionIdNotInValueStore() {
        let form = FormDefinition(id: "test", title: "Test", saveBehaviour: .none) {
            FormSection(id: "sect", title: "Section") {
                BooleanSwitchRow(id: "flag", title: "Flag", defaultValue: true)
            }
        }
        let vm = FormViewModel(formDefinition: form)
        // Section id should NOT be in the store
        let sectionValue: Bool? = vm.value(for: "sect")
        #expect(sectionValue == nil)
        // Child row default should be in the store
        let flagValue: Bool? = vm.value(for: "flag")
        #expect(flagValue == true)
    }

    @Test("Child row default values inside section are seeded into FormViewModel")
    func childRowDefaultsSeededIntoViewModel() {
        let form = FormDefinition(id: "test", title: "Test", saveBehaviour: .none) {
            FormSection(id: "info", title: "Info") {
                BooleanSwitchRow(id: "toggle", title: "Toggle", defaultValue: true)
                TextInputRow(id: "name", title: "Name", defaultValue: "Alice")
            }
        }
        let vm = FormViewModel(formDefinition: form)
        let toggle: Bool? = vm.value(for: "toggle")
        let name: String? = vm.value(for: "name")
        #expect(toggle == true)
        #expect(name == "Alice")
    }
}

// MARK: - FormSection Visibility Tests

@Suite("FormSection Visibility")
struct FormSectionVisibilityTests {
    @Test("FormSection with no showRow actions is always visible")
    func formSectionAlwaysVisible() {
        let form = FormDefinition(id: "test", title: "Test", saveBehaviour: .none) {
            FormSection(id: "sect", title: "Section") {
                BooleanSwitchRow(id: "flag", title: "Flag")
            }
        }
        let vm = FormViewModel(formDefinition: form)
        let sectionRow = form.rows[0]
        #expect(vm.isRowVisible(sectionRow))
    }

    @Test("Hidden section hides all its child rows")
    func hiddenSectionHidesChildren() {
        let form = FormDefinition(id: "test", title: "Test", saveBehaviour: .none) {
            BooleanSwitchRow(
                id: "showAdvanced",
                title: "Show Advanced",
                defaultValue: false,
                onChange: [.showRow(id: "advanced", when: [.isTrue(rowId: "showAdvanced")])]
            )
            FormSection(id: "advanced", title: "Advanced") {
                TextInputRow(id: "timeout", title: "Timeout")
            }
        }
        let vm = FormViewModel(formDefinition: form)
        let sectionRow = form.rows[1]
        let childRow = form.rows[1].asType(FormSection.self)!.rows[0]
        // Section is hidden because showAdvanced is false.
        #expect(!vm.isRowVisible(sectionRow))
        // Child is also hidden because its parent section is hidden.
        #expect(!vm.isRowVisible(childRow))
    }

    @Test("Visible section shows all its child rows")
    func visibleSectionShowsChildren() {
        let form = FormDefinition(id: "test", title: "Test", saveBehaviour: .none) {
            BooleanSwitchRow(
                id: "showAdvanced",
                title: "Show Advanced",
                defaultValue: true,
                onChange: [.showRow(id: "advanced", when: [.isTrue(rowId: "showAdvanced")])]
            )
            FormSection(id: "advanced", title: "Advanced") {
                TextInputRow(id: "timeout", title: "Timeout")
            }
        }
        let vm = FormViewModel(formDefinition: form)
        let sectionRow = form.rows[1]
        let childRow = form.rows[1].asType(FormSection.self)!.rows[0]
        #expect(vm.isRowVisible(sectionRow))
        #expect(vm.isRowVisible(childRow))
    }

    @Test("Section visibility toggles when controlling row value changes")
    func sectionVisibilityTogglesOnValueChange() {
        let form = FormDefinition(id: "test", title: "Test", saveBehaviour: .none) {
            BooleanSwitchRow(
                id: "enabled",
                title: "Enabled",
                defaultValue: false,
                onChange: [.showRow(id: "details", when: [.isTrue(rowId: "enabled")])]
            )
            FormSection(id: "details", title: "Details") {
                TextInputRow(id: "name", title: "Name")
            }
        }
        let vm = FormViewModel(formDefinition: form)
        let sectionRow = form.rows[1]
        let childRow = form.rows[1].asType(FormSection.self)!.rows[0]

        // Initially hidden (enabled = false).
        #expect(!vm.isRowVisible(sectionRow))
        #expect(!vm.isRowVisible(childRow))

        // Enable the controlling toggle.
        vm.setBool(true, for: "enabled")

        // Now section and child should be visible.
        #expect(vm.isRowVisible(sectionRow))
        #expect(vm.isRowVisible(childRow))
    }

    @Test("allRows flattens sections recursively")
    func allRowsFlattensRecursively() {
        let rows: [AnyFormRow] = [
            AnyFormRow(BooleanSwitchRow(id: "top", title: "Top")),
            AnyFormRow(FormSection(id: "sect", title: "Section") {
                TextInputRow(id: "inner", title: "Inner")
                FormSection(id: "nested", title: "Nested") {
                    BooleanSwitchRow(id: "deep", title: "Deep")
                }
            })
        ]
        let flattened = FormViewModel.allRows(in: rows)
        let ids = flattened.map(\.id)
        // Expected: top, sect, inner, nested, deep
        #expect(ids.contains("top"))
        #expect(ids.contains("sect"))
        #expect(ids.contains("inner"))
        #expect(ids.contains("nested"))
        #expect(ids.contains("deep"))
        #expect(ids.count == 5)
    }
}
