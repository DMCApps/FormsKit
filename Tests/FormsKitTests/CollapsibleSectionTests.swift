@testable import FormsKit
import Testing

// MARK: - CollapsibleSection Construction Tests

@Suite("CollapsibleSection Construction")
struct CollapsibleSectionConstructionTests {
    @Test("CollapsibleSection stores id and title")
    func collapsibleSectionStoresIdAndTitle() {
        let section = CollapsibleSection(id: "my-section", title: "My Section", rows: [])
        #expect(section.id == "my-section")
        #expect(section.title == "My Section")
    }

    @Test("CollapsibleSection stores child rows via array initialiser")
    func collapsibleSectionStoresChildRows() {
        let rows: [AnyFormRow] = [
            AnyFormRow(BooleanSwitchRow(id: "toggle", title: "Toggle")),
            AnyFormRow(TextInputRow(id: "name", title: "Name"))
        ]
        let section = CollapsibleSection(id: "s", title: "S", rows: rows)
        #expect(section.rows.count == 2)
        #expect(section.rows[0].id == "toggle")
        #expect(section.rows[1].id == "name")
    }

    @Test("CollapsibleSection builder DSL collects child rows")
    func collapsibleSectionBuilderDSL() {
        let section = CollapsibleSection(id: "account", title: "Account") {
            TextInputRow(id: "name", title: "Name")
            TextInputRow(id: "email", title: "Email")
        }
        #expect(section.rows.count == 2)
        #expect(section.rows[0].id == "name")
        #expect(section.rows[1].id == "email")
    }

    @Test("CollapsibleSection stores onChange actions")
    func collapsibleSectionStoresOnChangeActions() {
        let section = CollapsibleSection(
            id: "advanced",
            title: "Advanced",
            rows: [],
            onChange: [.showRow(id: "advanced", when: [.isTrue(rowId: "enabled")])]
        )
        #expect(section.onChange.count == 1)
    }

    @Test("CollapsibleSection isExpandedByDefault defaults to true")
    func collapsibleSectionExpandedByDefaultIsTrue() {
        let section = CollapsibleSection(id: "s", title: "S", rows: [])
        #expect(section.isExpandedByDefault == true)
    }

    @Test("CollapsibleSection isExpandedByDefault can be set to false")
    func collapsibleSectionExpandedByDefaultCanBeFalse() {
        let section = CollapsibleSection(id: "s", title: "S", isExpandedByDefault: false, rows: [])
        #expect(section.isExpandedByDefault == false)
    }

    @Test("CollapsibleSection RawRepresentable id overload with array rows")
    func collapsibleSectionRawRepresentableIdArrayRows() {
        enum SectionID: String { case details = "user_details" }
        let section = CollapsibleSection(id: SectionID.details, title: "Details", rows: [])
        #expect(section.id == "user_details")
    }

    @Test("CollapsibleSection RawRepresentable id overload with builder DSL")
    func collapsibleSectionRawRepresentableIdBuilderDSL() {
        enum SectionID: String { case advanced = "advanced_settings" }
        let section = CollapsibleSection(id: SectionID.advanced, title: "Advanced") {
            BooleanSwitchRow(id: "flag", title: "Flag")
        }
        #expect(section.id == "advanced_settings")
        #expect(section.rows.count == 1)
    }
}

// MARK: - CollapsibleSection Protocol Defaults Tests

@Suite("CollapsibleSection Protocol Defaults")
struct CollapsibleSectionProtocolDefaultsTests {
    @Test("CollapsibleSection has nil subtitle")
    func collapsibleSectionHasNilSubtitle() {
        let section = CollapsibleSection(id: "s", title: "S", rows: [])
        #expect(section.subtitle == nil)
    }

    @Test("CollapsibleSection has no validators")
    func collapsibleSectionHasNoValidators() {
        let section = CollapsibleSection(id: "s", title: "S", rows: [])
        #expect(section.validators.isEmpty)
    }

    @Test("CollapsibleSection has nil defaultValue")
    func collapsibleSectionHasNilDefaultValue() {
        let section = CollapsibleSection(id: "s", title: "S", rows: [])
        #expect(section.defaultValue == nil)
    }

    @Test("CollapsibleSection has empty onChange by default")
    func collapsibleSectionHasEmptyOnChangeByDefault() {
        let section = CollapsibleSection(id: "s", title: "S", rows: [])
        #expect(section.onChange.isEmpty)
    }
}

// MARK: - CollapsibleSection AnyFormRow Wrapping Tests

@Suite("CollapsibleSection AnyFormRow Wrapping")
struct CollapsibleSectionAnyFormRowWrappingTests {
    @Test("AnyFormRow wraps CollapsibleSection and casts back correctly")
    func anyFormRowWrapsCollapsibleSection() {
        let section = CollapsibleSection(id: "sect", title: "Section") {
            TextInputRow(id: "name", title: "Name")
        }
        let anyRow = AnyFormRow(section)
        let cast = anyRow.asType(CollapsibleSection.self)
        #expect(cast != nil)
        #expect(cast?.id == "sect")
        #expect(cast?.title == "Section")
        #expect(cast?.rows.count == 1)
    }

    @Test("AnyFormRow wrapping CollapsibleSection carries id and title")
    func anyFormRowCollapsibleSectionCarriesMetadata() {
        let section = CollapsibleSection(id: "meta", title: "Meta", rows: [])
        let anyRow = AnyFormRow(section)
        #expect(anyRow.id == "meta")
        #expect(anyRow.title == "Meta")
    }
}

// MARK: - CollapsibleSection in FormDefinition DSL Tests

@Suite("CollapsibleSection in FormDefinition DSL")
struct CollapsibleSectionInFormDefinitionTests {
    @Test("CollapsibleSection used in FormDefinition builder DSL")
    func collapsibleSectionInFormDefinitionDSL() {
        let form = FormDefinition(id: "test", title: "Test", saveBehaviour: .none) {
            BooleanSwitchRow(id: "top", title: "Top Level")
            CollapsibleSection(id: "details", title: "Details") {
                TextInputRow(id: "name", title: "Name")
                TextInputRow(id: "email", title: "Email")
            }
        }
        #expect(form.rows.count == 2)
        #expect(form.rows[0].id == "top")
        #expect(form.rows[1].id == "details")
        let section = form.rows[1].asType(CollapsibleSection.self)
        #expect(section?.rows.count == 2)
    }

    @Test("CollapsibleSection id is not seeded into FormViewModel value store")
    func collapsibleSectionIdNotInValueStore() {
        let form = FormDefinition(id: "test", title: "Test", saveBehaviour: .none) {
            CollapsibleSection(id: "sect", title: "Section") {
                BooleanSwitchRow(id: "flag", title: "Flag", defaultValue: true)
            }
        }
        let vm = FormViewModel(formDefinition: form)
        let sectionValue: Bool? = vm.value(for: "sect")
        #expect(sectionValue == nil)
    }

    @Test("Child row default values inside CollapsibleSection are seeded into FormViewModel")
    func childRowDefaultsSeededIntoViewModel() {
        let form = FormDefinition(id: "test", title: "Test", saveBehaviour: .none) {
            CollapsibleSection(id: "info", title: "Info") {
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

// MARK: - CollapsibleSection Expand/Collapse Tests

@Suite("CollapsibleSection Expand/Collapse")
struct CollapsibleSectionExpandCollapseTests {
    @Test("Expanded section shows child rows")
    func expandedSectionShowsChildren() {
        let form = FormDefinition(id: "test", title: "Test", saveBehaviour: .none) {
            CollapsibleSection(id: "sect", title: "Section", isExpandedByDefault: true) {
                BooleanSwitchRow(id: "child", title: "Child")
            }
        }
        let vm = FormViewModel(formDefinition: form)
        let childRow = form.rows[0].asType(CollapsibleSection.self)!.rows[0]
        #expect(vm.isSectionExpanded("sect"))
        #expect(vm.isRowVisible(childRow))
    }

    @Test("Collapsed section hides child rows")
    func collapsedSectionHidesChildren() {
        let form = FormDefinition(id: "test", title: "Test", saveBehaviour: .none) {
            CollapsibleSection(id: "sect", title: "Section", isExpandedByDefault: false) {
                BooleanSwitchRow(id: "child", title: "Child")
            }
        }
        let vm = FormViewModel(formDefinition: form)
        let childRow = form.rows[0].asType(CollapsibleSection.self)!.rows[0]
        #expect(!vm.isSectionExpanded("sect"))
        #expect(!vm.isRowVisible(childRow))
    }

    @Test("CollapsibleSection header row itself is always visible when no showRow targets it")
    func collapsibleSectionHeaderAlwaysVisible() {
        let form = FormDefinition(id: "test", title: "Test", saveBehaviour: .none) {
            CollapsibleSection(id: "sect", title: "Section", isExpandedByDefault: false) {
                BooleanSwitchRow(id: "child", title: "Child")
            }
        }
        let vm = FormViewModel(formDefinition: form)
        let sectionRow = form.rows[0]
        #expect(vm.isRowVisible(sectionRow))
    }

    @Test("toggleSection expands a collapsed section")
    func toggleExpandsCollapsedSection() {
        let form = FormDefinition(id: "test", title: "Test", saveBehaviour: .none) {
            CollapsibleSection(id: "sect", title: "Section", isExpandedByDefault: false) {
                BooleanSwitchRow(id: "child", title: "Child")
            }
        }
        let vm = FormViewModel(formDefinition: form)
        let childRow = form.rows[0].asType(CollapsibleSection.self)!.rows[0]

        #expect(!vm.isSectionExpanded("sect"))
        #expect(!vm.isRowVisible(childRow))

        vm.toggleSection("sect")

        #expect(vm.isSectionExpanded("sect"))
        #expect(vm.isRowVisible(childRow))
    }

    @Test("toggleSection collapses an expanded section")
    func toggleCollapsesExpandedSection() {
        let form = FormDefinition(id: "test", title: "Test", saveBehaviour: .none) {
            CollapsibleSection(id: "sect", title: "Section", isExpandedByDefault: true) {
                BooleanSwitchRow(id: "child", title: "Child")
            }
        }
        let vm = FormViewModel(formDefinition: form)
        let childRow = form.rows[0].asType(CollapsibleSection.self)!.rows[0]

        #expect(vm.isSectionExpanded("sect"))
        #expect(vm.isRowVisible(childRow))

        vm.toggleSection("sect")

        #expect(!vm.isSectionExpanded("sect"))
        #expect(!vm.isRowVisible(childRow))
    }

    @Test("allRows flattens CollapsibleSection children recursively")
    func allRowsFlattensCollapsibleSectionChildren() {
        let rows: [AnyFormRow] = [
            AnyFormRow(BooleanSwitchRow(id: "top", title: "Top")),
            AnyFormRow(CollapsibleSection(id: "collapsible", title: "Collapsible") {
                TextInputRow(id: "inner", title: "Inner")
            })
        ]
        let flattened = FormViewModel.allRows(in: rows)
        let ids = flattened.map(\.id)
        #expect(ids.contains("top"))
        #expect(ids.contains("collapsible"))
        #expect(ids.contains("inner"))
        #expect(ids.count == 3)
    }

    @Test("Hidden CollapsibleSection hides children regardless of expand state")
    func hiddenCollapsibleSectionHidesChildren() {
        let form = FormDefinition(id: "test", title: "Test", saveBehaviour: .none) {
            BooleanSwitchRow(
                id: "showAdvanced",
                title: "Show Advanced",
                defaultValue: false,
                onChange: [.showRow(id: "advanced", when: [.isTrue(rowId: "showAdvanced")])]
            )
            CollapsibleSection(id: "advanced", title: "Advanced", isExpandedByDefault: true) {
                TextInputRow(id: "timeout", title: "Timeout")
            }
        }
        let vm = FormViewModel(formDefinition: form)
        let sectionRow = form.rows[1]
        let childRow = form.rows[1].asType(CollapsibleSection.self)!.rows[0]

        // Section is hidden by showRow action (toggle is off).
        #expect(!vm.isRowVisible(sectionRow))
        #expect(!vm.isRowVisible(childRow))

        // Turn the toggle on — section and child should now be visible.
        vm.setBool(true, for: "showAdvanced")
        #expect(vm.isRowVisible(sectionRow))
        #expect(vm.isRowVisible(childRow))
    }

    @Test("reset re-seeds expandedSections to initial defaults")
    func resetResedsExpandedSections() {
        let form = FormDefinition(id: "test", title: "Test", saveBehaviour: .none) {
            CollapsibleSection(id: "sect", title: "Section", isExpandedByDefault: true) {
                BooleanSwitchRow(id: "child", title: "Child")
            }
        }
        let vm = FormViewModel(formDefinition: form)

        // Collapse it manually.
        vm.toggleSection("sect")
        #expect(!vm.isSectionExpanded("sect"))

        // Reset should restore the section to its default expanded state.
        vm.reset()
        #expect(vm.isSectionExpanded("sect"))
    }
}
