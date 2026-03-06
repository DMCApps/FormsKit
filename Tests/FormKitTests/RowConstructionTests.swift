@testable import FormKit
import Testing

// MARK: - ButtonRow Tests

@Suite("ButtonRow")
struct ButtonRowTests {
    // MARK: Construction

    @Test("ButtonRow stores id and title")
    func buttonRowStoresIdAndTitle() {
        let row = ButtonRow(id: "my-button", title: "Tap Me") { }
        #expect(row.id == "my-button")
        #expect(row.title == "Tap Me")
    }

    @Test("ButtonRow stores subtitle")
    func buttonRowStoresSubtitle() {
        let row = ButtonRow(id: "btn", title: "Button", subtitle: "Help text") { }
        #expect(row.subtitle == "Help text")
    }

    @Test("ButtonRow stores onChange actions")
    func buttonRowStoresOnChangeActions() {
        let row = ButtonRow(
            id: "btn",
            title: "Button",
            onChange: [.showRow(id: "other", when: [])]
        ) { }
        #expect(row.onChange.count == 1)
    }

    @Test("ButtonRow action fires when called")
    func buttonRowActionFiresWhenCalled() {
        nonisolated(unsafe) var fired = false
        let row = ButtonRow(id: "btn", title: "Button") { fired = true }
        row.action()
        #expect(fired)
    }

    @Test("ButtonRow RawRepresentable id overload")
    func buttonRowRawRepresentableId() {
        enum RowID: String { case logout = "user_logout" }
        let row = ButtonRow(id: RowID.logout, title: "Logout") { }
        #expect(row.id == "user_logout")
    }

    // MARK: Protocol Defaults

    @Test("ButtonRow has nil subtitle by default")
    func buttonRowHasNilSubtitle() {
        let row = ButtonRow(id: "btn", title: "Button") { }
        #expect(row.subtitle == nil)
    }

    @Test("ButtonRow has empty validators")
    func buttonRowHasEmptyValidators() {
        let row = ButtonRow(id: "btn", title: "Button") { }
        #expect(row.validators.isEmpty)
    }

    @Test("ButtonRow has nil defaultValue")
    func buttonRowHasNilDefaultValue() {
        let row = ButtonRow(id: "btn", title: "Button") { }
        #expect(row.defaultValue == nil)
    }

    @Test("ButtonRow has empty onChange by default")
    func buttonRowHasEmptyOnChangeByDefault() {
        let row = ButtonRow(id: "btn", title: "Button") { }
        #expect(row.onChange.isEmpty)
    }

    // MARK: AnyFormRow wrapping

    @Test("AnyFormRow wraps ButtonRow and casts back correctly")
    func anyFormRowWrapsButtonRow() {
        let row = ButtonRow(id: "b", title: "B") { }
        let anyRow = AnyFormRow(row)
        let cast = anyRow.asType(ButtonRow.self)
        #expect(cast != nil)
        #expect(cast?.id == "b")
        #expect(cast?.title == "B")
    }

    @Test("AnyFormRow wrapping ButtonRow carries id and title")
    func anyFormRowButtonRowCarriesMetadata() {
        let row = ButtonRow(id: "meta", title: "Meta") { }
        let anyRow = AnyFormRow(row)
        #expect(anyRow.id == "meta")
        #expect(anyRow.title == "Meta")
    }

    @Test("ButtonRow does not appear in FormViewModel value store")
    func buttonRowNotInValueStore() {
        let form = FormDefinition(
            id: "test",
            title: "Test",
            rows: [AnyFormRow(ButtonRow(id: "logout", title: "Logout") { })],
            saveBehaviour: .none
        )
        let vm = FormViewModel(formDefinition: form)
        let value: Bool? = vm.value(for: "logout")
        #expect(value == nil)
    }
}

// MARK: - NavigationRow Tests

@Suite("NavigationRow")
struct NavigationRowTests {
    // MARK: Construction

    @Test("NavigationRow stores id and title")
    func navigationRowStoresIdAndTitle() {
        let dest = FormDefinition(id: "sub", title: "Sub Form", rows: [], saveBehaviour: .none)
        let row = NavigationRow(id: "nav", title: "Go to Sub", destination: dest)
        #expect(row.id == "nav")
        #expect(row.title == "Go to Sub")
    }

    @Test("NavigationRow stores destination")
    func navigationRowStoresDestination() {
        let dest = FormDefinition(id: "sub", title: "Sub Form", rows: [], saveBehaviour: .none)
        let row = NavigationRow(id: "nav", title: "Nav", destination: dest)
        #expect(row.destination.id == "sub")
        #expect(row.destination.title == "Sub Form")
    }

    @Test("NavigationRow stores subtitle")
    func navigationRowStoresSubtitle() {
        let dest = FormDefinition(id: "sub", title: "Sub", rows: [], saveBehaviour: .none)
        let row = NavigationRow(id: "nav", title: "Nav", subtitle: "Tap to go", destination: dest)
        #expect(row.subtitle == "Tap to go")
    }

    @Test("NavigationRow stores onChange actions")
    func navigationRowStoresOnChangeActions() {
        let dest = FormDefinition(id: "sub", title: "Sub", rows: [], saveBehaviour: .none)
        let row = NavigationRow(
            id: "nav",
            title: "Nav",
            destination: dest,
            onChange: [.showRow(id: "nav", when: [.isTrue(rowId: "enabled")])]
        )
        #expect(row.onChange.count == 1)
    }

    @Test("NavigationRow RawRepresentable id overload")
    func navigationRowRawRepresentableId() {
        enum RowID: String { case settings = "app_settings" }
        let dest = FormDefinition(id: "settings", title: "Settings", rows: [], saveBehaviour: .none)
        let row = NavigationRow(id: RowID.settings, title: "Settings", destination: dest)
        #expect(row.id == "app_settings")
    }

    // MARK: Protocol Defaults

    @Test("NavigationRow has nil subtitle by default")
    func navigationRowHasNilSubtitle() {
        let dest = FormDefinition(id: "sub", title: "Sub", rows: [], saveBehaviour: .none)
        let row = NavigationRow(id: "nav", title: "Nav", destination: dest)
        #expect(row.subtitle == nil)
    }

    @Test("NavigationRow has empty validators")
    func navigationRowHasEmptyValidators() {
        let dest = FormDefinition(id: "sub", title: "Sub", rows: [], saveBehaviour: .none)
        let row = NavigationRow(id: "nav", title: "Nav", destination: dest)
        #expect(row.validators.isEmpty)
    }

    @Test("NavigationRow has nil defaultValue")
    func navigationRowHasNilDefaultValue() {
        let dest = FormDefinition(id: "sub", title: "Sub", rows: [], saveBehaviour: .none)
        let row = NavigationRow(id: "nav", title: "Nav", destination: dest)
        #expect(row.defaultValue == nil)
    }

    @Test("NavigationRow has empty onChange by default")
    func navigationRowHasEmptyOnChangeByDefault() {
        let dest = FormDefinition(id: "sub", title: "Sub", rows: [], saveBehaviour: .none)
        let row = NavigationRow(id: "nav", title: "Nav", destination: dest)
        #expect(row.onChange.isEmpty)
    }

    // MARK: AnyFormRow wrapping

    @Test("AnyFormRow wraps NavigationRow and casts back correctly")
    func anyFormRowWrapsNavigationRow() {
        let dest = FormDefinition(id: "sub", title: "Sub", rows: [], saveBehaviour: .none)
        let row = NavigationRow(id: "nav", title: "Nav", destination: dest)
        let anyRow = AnyFormRow(row)
        let cast = anyRow.asType(NavigationRow.self)
        #expect(cast != nil)
        #expect(cast?.id == "nav")
        #expect(cast?.destination.id == "sub")
    }

    @Test("AnyFormRow wrapping NavigationRow carries id and title")
    func anyFormRowNavigationRowCarriesMetadata() {
        let dest = FormDefinition(id: "sub", title: "Sub", rows: [], saveBehaviour: .none)
        let row = NavigationRow(id: "meta", title: "Meta", destination: dest)
        let anyRow = AnyFormRow(row)
        #expect(anyRow.id == "meta")
        #expect(anyRow.title == "Meta")
    }

    @Test("NavigationRow does not appear in FormViewModel value store")
    func navigationRowNotInValueStore() {
        let dest = FormDefinition(id: "sub", title: "Sub", rows: [], saveBehaviour: .none)
        let form = FormDefinition(
            id: "test",
            title: "Test",
            rows: [AnyFormRow(NavigationRow(id: "nav", title: "Nav", destination: dest))],
            saveBehaviour: .none
        )
        let vm = FormViewModel(formDefinition: form)
        let value: String? = vm.value(for: "nav")
        #expect(value == nil)
    }
}

// MARK: - SingleValueRow Tests

@Suite("SingleValueRow")
struct SingleValueRowTests {
    enum Colour: String, CaseIterable, CustomStringConvertible, Hashable, Codable, Sendable {
        case red, green, blue
        var description: String { rawValue }
    }

    // MARK: Construction

    @Test("SingleValueRow stores id and title")
    func singleValueRowStoresIdAndTitle() {
        let row = SingleValueRow<Colour>(id: "colour", title: "Colour")
        #expect(row.id == "colour")
        #expect(row.title == "Colour")
    }

    @Test("SingleValueRow defaults to all cases for options")
    func singleValueRowDefaultsToAllCases() {
        let row = SingleValueRow<Colour>(id: "colour", title: "Colour")
        #expect(row.options.count == 3)
    }

    @Test("SingleValueRow accepts custom options subset")
    func singleValueRowCustomOptions() {
        let row = SingleValueRow<Colour>(id: "colour", title: "Colour", options: [.red, .blue])
        #expect(row.options == [.red, .blue])
    }

    @Test("SingleValueRow stores subtitle")
    func singleValueRowStoresSubtitle() {
        let row = SingleValueRow<Colour>(id: "colour", title: "Colour", subtitle: "Pick a color")
        #expect(row.subtitle == "Pick a color")
    }

    @Test("SingleValueRow stores defaultValue")
    func singleValueRowStoresDefaultValue() {
        let row = SingleValueRow<Colour>(id: "colour", title: "Colour", defaultValue: .green)
        if case let .string(val) = row.defaultValue {
            #expect(val == "green")
        } else {
            Issue.record("Expected .string defaultValue")
        }
    }

    @Test("SingleValueRow nil defaultValue when not provided")
    func singleValueRowNilDefaultValueWhenNotProvided() {
        let row = SingleValueRow<Colour>(id: "colour", title: "Colour")
        #expect(row.defaultValue == nil)
    }

    @Test("SingleValueRow optionDescriptions matches option descriptions")
    func singleValueRowOptionDescriptions() {
        let row = SingleValueRow<Colour>(id: "colour", title: "Colour")
        #expect(row.optionDescriptions == ["red", "green", "blue"])
    }

    @Test("SingleValueRow selectedDescription returns nil when no default")
    func singleValueRowSelectedDescriptionNilWhenNoDefault() {
        let row = SingleValueRow<Colour>(id: "colour", title: "Colour")
        #expect(row.selectedDescription == nil)
    }

    @Test("SingleValueRow selectedDescription returns description of default value")
    func singleValueRowSelectedDescriptionMatchesDefault() {
        let row = SingleValueRow<Colour>(id: "colour", title: "Colour", defaultValue: .blue)
        #expect(row.selectedDescription == "blue")
    }

    @Test("SingleValueRow stores validators")
    func singleValueRowStoresValidators() {
        let v = FormValidator { _ in nil }
        let row = SingleValueRow<Colour>(id: "colour", title: "Colour", validators: [v])
        #expect(row.validators.count == 1)
    }

    @Test("SingleValueRow stores onChange actions")
    func singleValueRowStoresOnChangeActions() {
        let row = SingleValueRow<Colour>(
            id: "colour",
            title: "Colour",
            onChange: [.showRow(id: "other", when: [])]
        )
        #expect(row.onChange.count == 1)
    }

    @Test("SingleValueRow RawRepresentable id overload")
    func singleValueRowRawRepresentableId() {
        enum RowID: String { case theme = "app_theme" }
        let row = SingleValueRow<Colour>(id: RowID.theme, title: "Theme")
        #expect(row.id == "app_theme")
    }

    // MARK: AnyFormRow wrapping

    @Test("AnyFormRow wraps SingleValueRow and casts back correctly")
    func anyFormRowWrapsSingleValueRow() {
        let row = SingleValueRow<Colour>(id: "colour", title: "Colour", defaultValue: .red)
        let anyRow = AnyFormRow(row)
        let cast = anyRow.asType(SingleValueRow<Colour>.self)
        #expect(cast != nil)
        #expect(cast?.id == "colour")
        #expect(cast?.selectedDescription == "red")
    }

    @Test("AnyFormRow asSingleValueRepresentable returns non-nil for SingleValueRow")
    func anyFormRowAsSingleValueRepresentable() {
        let row = SingleValueRow<Colour>(id: "colour", title: "Colour")
        let anyRow = AnyFormRow(row)
        #expect(anyRow.asSingleValueRepresentable != nil)
    }

    @Test("AnyFormRow asSingleValueRepresentable optionDescriptions match")
    func anyFormRowSingleValueRepresentableOptionDescriptions() {
        let row = SingleValueRow<Colour>(id: "colour", title: "Colour")
        let anyRow = AnyFormRow(row)
        #expect(anyRow.asSingleValueRepresentable?.optionDescriptions == ["red", "green", "blue"])
    }

    @Test("AnyFormRow asMultiValueRepresentable returns nil for SingleValueRow")
    func anyFormRowSingleValueNotMultiValue() {
        let row = SingleValueRow<Colour>(id: "colour", title: "Colour")
        let anyRow = AnyFormRow(row)
        #expect(anyRow.asMultiValueRepresentable == nil)
    }

    @Test("SingleValueRow default value is seeded into FormViewModel")
    func singleValueRowDefaultSeededIntoViewModel() {
        let form = FormDefinition(
            id: "test",
            title: "Test",
            rows: [AnyFormRow(SingleValueRow<Colour>(id: "colour", title: "Colour", defaultValue: .green))],
            saveBehaviour: .none
        )
        let vm = FormViewModel(formDefinition: form)
        let value: String? = vm.value(for: "colour")
        #expect(value == "green")
    }
}

// MARK: - MultiValueRow Tests

@Suite("MultiValueRow")
struct MultiValueRowTests {
    enum Tag: String, CaseIterable, CustomStringConvertible, Hashable, Codable, Sendable {
        case swift, ios, macos
        var description: String { rawValue }
    }

    // MARK: Construction

    @Test("MultiValueRow stores id and title")
    func multiValueRowStoresIdAndTitle() {
        let row = MultiValueRow<Tag>(id: "tags", title: "Tags")
        #expect(row.id == "tags")
        #expect(row.title == "Tags")
    }

    @Test("MultiValueRow defaults to all cases for options")
    func multiValueRowDefaultsToAllCases() {
        let row = MultiValueRow<Tag>(id: "tags", title: "Tags")
        #expect(row.options.count == 3)
    }

    @Test("MultiValueRow accepts custom options subset")
    func multiValueRowCustomOptions() {
        let row = MultiValueRow<Tag>(id: "tags", title: "Tags", options: [.swift, .ios])
        #expect(row.options == [.swift, .ios])
    }

    @Test("MultiValueRow stores subtitle")
    func multiValueRowStoresSubtitle() {
        let row = MultiValueRow<Tag>(id: "tags", title: "Tags", subtitle: "Select tags")
        #expect(row.subtitle == "Select tags")
    }

    @Test("MultiValueRow nil defaultValue when default set is empty")
    func multiValueRowNilDefaultValueWhenEmpty() {
        let row = MultiValueRow<Tag>(id: "tags", title: "Tags")
        #expect(row.defaultValue == nil)
    }

    @Test("MultiValueRow defaultValue as array when default set is non-empty")
    func multiValueRowDefaultValueAsArray() {
        let row = MultiValueRow<Tag>(id: "tags", title: "Tags", defaultValue: [.swift, .ios])
        if case let .array(items) = row.defaultValue {
            let strings = items.compactMap { if case let .string(s) = $0 { return s } else { return nil } }
            #expect(strings.sorted() == ["ios", "swift"])
        } else {
            Issue.record("Expected .array defaultValue")
        }
    }

    @Test("MultiValueRow optionDescriptions matches option descriptions")
    func multiValueRowOptionDescriptions() {
        let row = MultiValueRow<Tag>(id: "tags", title: "Tags")
        #expect(row.optionDescriptions == ["swift", "ios", "macos"])
    }

    @Test("MultiValueRow selectedDescriptions empty when no default")
    func multiValueRowSelectedDescriptionsEmptyWhenNoDefault() {
        let row = MultiValueRow<Tag>(id: "tags", title: "Tags")
        #expect(row.selectedDescriptions.isEmpty)
    }

    @Test("MultiValueRow selectedDescriptions reflect default set")
    func multiValueRowSelectedDescriptionsReflectDefault() {
        let row = MultiValueRow<Tag>(id: "tags", title: "Tags", defaultValue: [.macos])
        #expect(row.selectedDescriptions == ["macos"])
    }

    @Test("MultiValueRow stores validators")
    func multiValueRowStoresValidators() {
        let v = FormValidator { _ in nil }
        let row = MultiValueRow<Tag>(id: "tags", title: "Tags", validators: [v])
        #expect(row.validators.count == 1)
    }

    @Test("MultiValueRow stores onChange actions")
    func multiValueRowStoresOnChangeActions() {
        let row = MultiValueRow<Tag>(
            id: "tags",
            title: "Tags",
            onChange: [.showRow(id: "other", when: [])]
        )
        #expect(row.onChange.count == 1)
    }

    @Test("MultiValueRow RawRepresentable id overload")
    func multiValueRowRawRepresentableId() {
        enum RowID: String { case platforms = "target_platforms" }
        let row = MultiValueRow<Tag>(id: RowID.platforms, title: "Platforms")
        #expect(row.id == "target_platforms")
    }

    // MARK: AnyFormRow wrapping

    @Test("AnyFormRow wraps MultiValueRow and casts back correctly")
    func anyFormRowWrapsMultiValueRow() {
        let row = MultiValueRow<Tag>(id: "tags", title: "Tags", defaultValue: [.swift])
        let anyRow = AnyFormRow(row)
        let cast = anyRow.asType(MultiValueRow<Tag>.self)
        #expect(cast != nil)
        #expect(cast?.id == "tags")
        #expect(cast?.selectedDescriptions == ["swift"])
    }

    @Test("AnyFormRow asMultiValueRepresentable returns non-nil for MultiValueRow")
    func anyFormRowAsMultiValueRepresentable() {
        let row = MultiValueRow<Tag>(id: "tags", title: "Tags")
        let anyRow = AnyFormRow(row)
        #expect(anyRow.asMultiValueRepresentable != nil)
    }

    @Test("AnyFormRow asMultiValueRepresentable optionDescriptions match")
    func anyFormRowMultiValueRepresentableOptionDescriptions() {
        let row = MultiValueRow<Tag>(id: "tags", title: "Tags")
        let anyRow = AnyFormRow(row)
        #expect(anyRow.asMultiValueRepresentable?.optionDescriptions == ["swift", "ios", "macos"])
    }

    @Test("AnyFormRow asSingleValueRepresentable returns nil for MultiValueRow")
    func anyFormRowMultiValueNotSingleValue() {
        let row = MultiValueRow<Tag>(id: "tags", title: "Tags")
        let anyRow = AnyFormRow(row)
        #expect(anyRow.asSingleValueRepresentable == nil)
    }
}

// MARK: - BooleanSwitchRow Tests

@Suite("BooleanSwitchRow")
struct BooleanSwitchRowTests {
    // MARK: Construction

    @Test("BooleanSwitchRow stores id and title")
    func booleanSwitchRowStoresIdAndTitle() {
        let row = BooleanSwitchRow(id: "notifications", title: "Enable Notifications")
        #expect(row.id == "notifications")
        #expect(row.title == "Enable Notifications")
    }

    @Test("BooleanSwitchRow stores subtitle")
    func booleanSwitchRowStoresSubtitle() {
        let row = BooleanSwitchRow(id: "toggle", title: "Toggle", subtitle: "Toggles a thing")
        #expect(row.subtitle == "Toggles a thing")
    }

    @Test("BooleanSwitchRow defaults to false")
    func booleanSwitchRowDefaultsFalse() {
        let row = BooleanSwitchRow(id: "toggle", title: "Toggle")
        if case let .bool(val) = row.defaultValue {
            #expect(val == false)
        } else {
            Issue.record("Expected .bool defaultValue")
        }
    }

    @Test("BooleanSwitchRow stores true defaultValue")
    func booleanSwitchRowStoreTrueDefault() {
        let row = BooleanSwitchRow(id: "toggle", title: "Toggle", defaultValue: true)
        if case let .bool(val) = row.defaultValue {
            #expect(val == true)
        } else {
            Issue.record("Expected .bool defaultValue")
        }
    }

    @Test("BooleanSwitchRow defaultValue is .bool AnyCodableValue")
    func booleanSwitchRowDefaultValueIsBool() {
        let row = BooleanSwitchRow(id: "toggle", title: "Toggle", defaultValue: true)
        #expect(row.defaultValue != nil)
        guard case .bool = row.defaultValue else {
            Issue.record("defaultValue should be .bool")
            return
        }
    }

    @Test("BooleanSwitchRow stores validators")
    func booleanSwitchRowStoresValidators() {
        let v = FormValidator { _ in nil }
        let row = BooleanSwitchRow(id: "toggle", title: "Toggle", validators: [v])
        #expect(row.validators.count == 1)
    }

    @Test("BooleanSwitchRow stores onChange actions")
    func booleanSwitchRowStoresOnChangeActions() {
        let row = BooleanSwitchRow(
            id: "toggle",
            title: "Toggle",
            onChange: [.showRow(id: "section", when: [.isTrue(rowId: "toggle")])]
        )
        #expect(row.onChange.count == 1)
    }

    @Test("BooleanSwitchRow RawRepresentable id overload")
    func booleanSwitchRowRawRepresentableId() {
        enum RowID: String { case darkMode = "ui_dark_mode" }
        let row = BooleanSwitchRow(id: RowID.darkMode, title: "Dark Mode")
        #expect(row.id == "ui_dark_mode")
    }

    @Test("BooleanSwitchRow RawRepresentable id with defaultValue")
    func booleanSwitchRowRawRepresentableIdWithDefault() {
        enum RowID: String { case sound = "sound_enabled" }
        let row = BooleanSwitchRow(id: RowID.sound, title: "Sound", defaultValue: true)
        #expect(row.id == "sound_enabled")
        if case let .bool(val) = row.defaultValue {
            #expect(val == true)
        } else {
            Issue.record("Expected .bool defaultValue")
        }
    }

    // MARK: AnyFormRow wrapping

    @Test("AnyFormRow wraps BooleanSwitchRow and casts back correctly")
    func anyFormRowWrapsBooleanSwitchRow() {
        let row = BooleanSwitchRow(id: "toggle", title: "Toggle", defaultValue: true)
        let anyRow = AnyFormRow(row)
        let cast = anyRow.asType(BooleanSwitchRow.self)
        #expect(cast != nil)
        #expect(cast?.id == "toggle")
    }

    @Test("AnyFormRow wrapping BooleanSwitchRow carries id and title")
    func anyFormRowBooleanSwitchRowCarriesMetadata() {
        let row = BooleanSwitchRow(id: "meta", title: "Meta")
        let anyRow = AnyFormRow(row)
        #expect(anyRow.id == "meta")
        #expect(anyRow.title == "Meta")
    }

    @Test("BooleanSwitchRow default value is seeded into FormViewModel")
    func booleanSwitchRowDefaultSeededIntoViewModel() {
        let form = FormDefinition(
            id: "test",
            title: "Test",
            rows: [AnyFormRow(BooleanSwitchRow(id: "flag", title: "Flag", defaultValue: true))],
            saveBehaviour: .none
        )
        let vm = FormViewModel(formDefinition: form)
        let value: Bool? = vm.value(for: "flag")
        #expect(value == true)
    }
}

// MARK: - TextInputRow Tests

@Suite("TextInputRow")
struct TextInputRowTests {
    // MARK: Construction

    @Test("TextInputRow stores id and title")
    func textInputRowStoresIdAndTitle() {
        let row = TextInputRow(id: "name", title: "Name")
        #expect(row.id == "name")
        #expect(row.title == "Name")
    }

    @Test("TextInputRow stores subtitle")
    func textInputRowStoresSubtitle() {
        let row = TextInputRow(id: "name", title: "Name", subtitle: "Your full name")
        #expect(row.subtitle == "Your full name")
    }

    @Test("TextInputRow stores placeholder")
    func textInputRowStoresPlaceholder() {
        let row = TextInputRow(id: "name", title: "Name", placeholder: "Enter name")
        #expect(row.placeholder == "Enter name")
    }

    @Test("TextInputRow nil placeholder by default")
    func textInputRowNilPlaceholderByDefault() {
        let row = TextInputRow(id: "name", title: "Name")
        #expect(row.placeholder == nil)
    }

    @Test("TextInputRow stores defaultValue as string")
    func textInputRowStoresDefaultValue() {
        let row = TextInputRow(id: "name", title: "Name", defaultValue: "Alice")
        if case let .string(val) = row.defaultValue {
            #expect(val == "Alice")
        } else {
            Issue.record("Expected .string defaultValue")
        }
    }

    @Test("TextInputRow nil defaultValue when not provided")
    func textInputRowNilDefaultValue() {
        let row = TextInputRow(id: "name", title: "Name")
        #expect(row.defaultValue == nil)
    }

    @Test("TextInputRow isSecure defaults to false")
    func textInputRowIsSecureFalseByDefault() {
        let row = TextInputRow(id: "text", title: "Text")
        #expect(row.isSecure == false)
    }

    @Test("TextInputRow stores isSecure true")
    func textInputRowStoresIsSecureTrue() {
        let row = TextInputRow(id: "password", title: "Password", isSecure: true)
        #expect(row.isSecure == true)
    }

    @Test("TextInputRow mask is nil by default")
    func textInputRowMaskNilByDefault() {
        let row = TextInputRow(id: "text", title: "Text")
        #expect(row.mask == nil)
    }

    @Test("TextInputRow stores mask when provided")
    func textInputRowStoresMask() {
        let row = TextInputRow(id: "phone", title: "Phone", mask: .usPhone)
        #expect(row.mask == .usPhone)
    }

    @Test("TextInputRow stores custom mask pattern")
    func textInputRowStoresCustomMask() {
        let mask = FormInputMask("##-##-####")
        let row = TextInputRow(id: "ref", title: "Reference", mask: mask)
        #expect(row.mask?.pattern == "##-##-####")
    }

    @Test("TextInputRow stores validators")
    func textInputRowStoresValidators() {
        let v = FormValidator { _ in nil }
        let row = TextInputRow(id: "text", title: "Text", validators: [v])
        #expect(row.validators.count == 1)
    }

    @Test("TextInputRow stores onChange actions")
    func textInputRowStoresOnChangeActions() {
        let row = TextInputRow(
            id: "text",
            title: "Text",
            onChange: [.showRow(id: "other", when: [])]
        )
        #expect(row.onChange.count == 1)
    }

    @Test("TextInputRow RawRepresentable id overload")
    func textInputRowRawRepresentableId() {
        enum RowID: String { case username = "account_username" }
        let row = TextInputRow(id: RowID.username, title: "Username")
        #expect(row.id == "account_username")
    }

    @Test("TextInputRow RawRepresentable id with all params")
    func textInputRowRawRepresentableIdAllParams() {
        enum RowID: String { case password = "auth_password" }
        let row = TextInputRow(
            id: RowID.password,
            title: "Password",
            isSecure: true,
            placeholder: "••••••••"
        )
        #expect(row.id == "auth_password")
        #expect(row.isSecure == true)
        #expect(row.placeholder == "••••••••")
    }

    // MARK: AnyFormRow wrapping

    @Test("AnyFormRow wraps TextInputRow and casts back correctly")
    func anyFormRowWrapsTextInputRow() {
        let row = TextInputRow(id: "name", title: "Name", defaultValue: "Bob")
        let anyRow = AnyFormRow(row)
        let cast = anyRow.asType(TextInputRow.self)
        #expect(cast != nil)
        #expect(cast?.id == "name")
        if case let .string(val) = cast?.defaultValue {
            #expect(val == "Bob")
        } else {
            Issue.record("Expected .string defaultValue")
        }
    }

    @Test("AnyFormRow wrapping TextInputRow carries id and title")
    func anyFormRowTextInputRowCarriesMetadata() {
        let row = TextInputRow(id: "meta", title: "Meta")
        let anyRow = AnyFormRow(row)
        #expect(anyRow.id == "meta")
        #expect(anyRow.title == "Meta")
    }

    @Test("TextInputRow default value is seeded into FormViewModel")
    func textInputRowDefaultSeededIntoViewModel() {
        let form = FormDefinition(
            id: "test",
            title: "Test",
            rows: [AnyFormRow(TextInputRow(id: "name", title: "Name", defaultValue: "Alice"))],
            saveBehaviour: .none
        )
        let vm = FormViewModel(formDefinition: form)
        let value: String? = vm.value(for: "name")
        #expect(value == "Alice")
    }
}

// MARK: - FormInputMask Tests

@Suite("FormInputMask")
struct FormInputMaskTests {
    // MARK: - Presets

    @Test("usPhone preset has correct pattern")
    func usPhonePresetPattern() {
        #expect(FormInputMask.usPhone.pattern == "(###) ###-####")
    }

    @Test("date preset has correct pattern")
    func datePresetPattern() {
        #expect(FormInputMask.date.pattern == "##/##/####")
    }

    @Test("usPhone maxInputLength is 10")
    func usPhoneMaxInputLength() {
        #expect(FormInputMask.usPhone.maxInputLength == 10)
    }

    @Test("date maxInputLength is 8")
    func dateMaxInputLength() {
        #expect(FormInputMask.date.maxInputLength == 8)
    }

    // MARK: - apply(to:) — usPhone

    @Test("apply usPhone with full 10-digit input formats correctly")
    func applyUsPhoneFullInput() {
        #expect(FormInputMask.usPhone.apply(to: "4155551234") == "(415) 555-1234")
    }

    @Test("apply usPhone with partial 3-digit input shows digits inside open paren only")
    func applyUsPhonePartialAreaCode() {
        // Literals are only inserted when there is remaining input to consume.
        // After "415" fills the 3 # slots, the trailing ")" literal has no more input
        // following it, so the loop breaks before appending it.
        #expect(FormInputMask.usPhone.apply(to: "415") == "(415")
    }

    @Test("apply usPhone with partial 6-digit input")
    func applyUsPhonePartialSixDigits() {
        #expect(FormInputMask.usPhone.apply(to: "415555") == "(415) 555")
    }

    @Test("apply usPhone with empty input returns empty string")
    func applyUsPhoneEmptyInput() {
        #expect(FormInputMask.usPhone.apply(to: "") == "")
    }

    @Test("apply usPhone stops at first non-digit character")
    func applyUsPhoneStopsAtNonDigit() {
        // Letters are not valid for # slots. After filling "(415", the ")" and " "
        // literals are appended as the loop continues, then "X" fails the next # slot.
        #expect(FormInputMask.usPhone.apply(to: "415X551234") == "(415) ")
    }

    // MARK: - apply(to:) — date

    @Test("apply date with full 8-digit input formats correctly")
    func applyDateFullInput() {
        #expect(FormInputMask.date.apply(to: "12252026") == "12/25/2026")
    }

    @Test("apply date with partial 2-digit input")
    func applyDatePartialMonth() {
        #expect(FormInputMask.date.apply(to: "12") == "12")
    }

    @Test("apply date with partial 4-digit input")
    func applyDatePartialMonthDay() {
        #expect(FormInputMask.date.apply(to: "1225") == "12/25")
    }

    @Test("apply date with empty input returns empty string")
    func applyDateEmptyInput() {
        #expect(FormInputMask.date.apply(to: "") == "")
    }

    // MARK: - apply(to:) — slot characters

    @Test("# slot accepts only digits")
    func hashSlotAcceptsOnlyDigits() {
        let mask = FormInputMask("#")
        #expect(mask.apply(to: "5") == "5")
        #expect(mask.apply(to: "a") == "")
    }

    @Test("A slot accepts only letters")
    func letterSlotAcceptsOnlyLetters() {
        let mask = FormInputMask("A")
        #expect(mask.apply(to: "a") == "a")
        #expect(mask.apply(to: "Z") == "Z")
        #expect(mask.apply(to: "3") == "")
    }

    @Test("* slot accepts any character")
    func wildcardSlotAcceptsAny() {
        let mask = FormInputMask("*")
        #expect(mask.apply(to: "a") == "a")
        #expect(mask.apply(to: "3") == "3")
        #expect(mask.apply(to: "!") == "!")
    }

    @Test("literals are auto-inserted between slots")
    func literalsAutoInserted() {
        let mask = FormInputMask("##-##")
        #expect(mask.apply(to: "1234") == "12-34")
    }

    @Test("apply does not exceed input length — extra pattern slots produce no output")
    func applyDoesNotPadBeyondInput() {
        // Pattern has 4 slots but input has 2 digits — should not pad
        let mask = FormInputMask("####")
        #expect(mask.apply(to: "12") == "12")
    }

    // MARK: - strip(from:)

    @Test("strip usPhone removes all literals")
    func stripUsPhoneRemovesLiterals() {
        #expect(FormInputMask.usPhone.strip(from: "(415) 555-1234") == "4155551234")
    }

    @Test("strip date removes all literals")
    func stripDateRemovesLiterals() {
        #expect(FormInputMask.date.strip(from: "12/25/2026") == "12252026")
    }

    @Test("strip returns empty string when given empty input")
    func stripEmptyInput() {
        #expect(FormInputMask.usPhone.strip(from: "") == "")
    }

    @Test("strip partial formatted string returns raw digits only")
    func stripPartialFormatted() {
        // "(415)" → "415"
        #expect(FormInputMask.usPhone.strip(from: "(415)") == "415")
    }

    @Test("apply then strip is identity for valid full input")
    func applyThenStripIsIdentity() {
        let raw = "4155551234"
        let formatted = FormInputMask.usPhone.apply(to: raw)
        let stripped = FormInputMask.usPhone.strip(from: formatted)
        #expect(stripped == raw)
    }

    @Test("apply then strip is identity for date")
    func applyThenStripDateIsIdentity() {
        let raw = "12252026"
        let formatted = FormInputMask.date.apply(to: raw)
        let stripped = FormInputMask.date.strip(from: formatted)
        #expect(stripped == raw)
    }

    // MARK: - maxInputLength

    @Test("maxInputLength counts only slot characters")
    func maxInputLengthCountsSlots() {
        let mask = FormInputMask("##-##-####")
        #expect(mask.maxInputLength == 8)
    }

    @Test("maxInputLength is zero for a pattern with no slots")
    func maxInputLengthZeroForLiteralsOnly() {
        // "---" contains only literal hyphens — no #, A, or * slots
        let mask = FormInputMask("---")
        #expect(mask.maxInputLength == 0)
    }

    // MARK: - Equatable

    @Test("two masks with identical patterns are equal")
    func identicalMasksAreEqual() {
        let a = FormInputMask("##/##/####")
        let b = FormInputMask("##/##/####")
        #expect(a == b)
    }

    @Test("two masks with different patterns are not equal")
    func differentMasksAreNotEqual() {
        let a = FormInputMask("##/##/####")
        let b = FormInputMask("(###) ###-####")
        #expect(a != b)
    }

    @Test("usPhone and date presets are not equal")
    func presetsAreNotEqual() {
        #expect(FormInputMask.usPhone != FormInputMask.date)
    }

    @Test("date preset and plain same-pattern mask are equal (equality is pattern-only)")
    func dateMaskAndPlainMaskEqualOnPattern() {
        // Equality is based on pattern alone — closures are not compared.
        let plain = FormInputMask("##/##/####")
        #expect(plain == FormInputMask.date)
    }

    // MARK: - toStorable / fromStorable

    @Test("plain mask has no toStorable or fromStorable")
    func plainMaskHasNoClosures() {
        let mask = FormInputMask("(###) ###-####")
        #expect(mask.toStorable == nil)
        #expect(mask.fromStorable == nil)
    }

    @Test("date preset has toStorable and fromStorable")
    func dateMaskHasClosures() {
        #expect(FormInputMask.date.toStorable != nil)
        #expect(FormInputMask.date.fromStorable != nil)
    }

    @Test("toStorable returns .date for a complete valid raw input")
    func toStorableReturnsDate() {
        let result = FormInputMask.date.toStorable?("12252026")
        if case .date = result {
            // pass
        } else {
            Issue.record("Expected .date, got \(String(describing: result))")
        }
    }

    @Test("toStorable returns nil for incomplete input")
    func toStorableNilForIncomplete() {
        #expect(FormInputMask.date.toStorable?("1225") == nil)
    }

    @Test("toStorable returns nil for empty input")
    func toStorableNilForEmpty() {
        #expect(FormInputMask.date.toStorable?("") == nil)
    }

    @Test("fromStorable round-trips with toStorable for a full date")
    func fromStorableRoundTrip() {
        let raw = "12252026"
        guard let stored = FormInputMask.date.toStorable?(raw) else {
            Issue.record("toStorable returned nil for \(raw)")
            return
        }
        #expect(FormInputMask.date.fromStorable?(stored) == raw)
    }

    @Test("fromStorable returns nil for a non-date stored value")
    func fromStorableNilForNonDate() {
        #expect(FormInputMask.date.fromStorable?(.string("12252026")) == nil)
    }

    @Test("custom mask toStorable is called with raw chars")
    func customMaskToStorable() {
        let mask = FormInputMask(
            "####",
            toStorable: { .string($0.uppercased()) },
            fromStorable: { $0.typed(String.self) }
        )
        #expect(mask.toStorable?("abcd") == .string("ABCD"))
    }

    @Test("custom mask fromStorable is called with stored value")
    func customMaskFromStorable() {
        let mask = FormInputMask(
            "####",
            toStorable: { .string($0.uppercased()) },
            fromStorable: { $0.typed(String.self) }
        )
        #expect(mask.fromStorable?(.string("ABCD")) == "ABCD")
    }
}

// MARK: - NumberInputRow Tests

@Suite("NumberInputRow")
struct NumberInputRowTests {
    // MARK: Construction

    @Test("NumberInputRow stores id and title")
    func numberInputRowStoresIdAndTitle() {
        let row = NumberInputRow(id: "count", title: "Count")
        #expect(row.id == "count")
        #expect(row.title == "Count")
    }

    @Test("NumberInputRow defaults to .int(defaultValue: nil) kind")
    func numberInputRowDefaultKindIsIntegerNil() {
        let row = NumberInputRow(id: "count", title: "Count")
        if case let .int(val) = row.kind {
            #expect(val == nil)
        } else {
            Issue.record("Expected .int(defaultValue: nil) kind")
        }
    }

    @Test("NumberInputRow .int(defaultValue: nil) is not decimal")
    func numberInputRowIntegerNotDecimal() {
        let row = NumberInputRow(id: "count", title: "Count")
        #expect(row.isDecimal == false)
    }

    @Test("NumberInputRow .decimal(defaultValue: nil) is decimal")
    func numberInputRowDecimalIsDecimal() {
        let row = NumberInputRow(id: "rate", title: "Rate", kind: .decimal(defaultValue: nil))
        #expect(row.isDecimal == true)
    }

    @Test("NumberInputRow .int(defaultValue: 42) stores kind and default")
    func numberInputRowIntegerWithDefault() {
        let row = NumberInputRow(id: "count", title: "Count", kind: .int(defaultValue: 42))
        if case let .int(val) = row.kind {
            #expect(val == 42)
        } else {
            Issue.record("Expected .int(defaultValue: 42) kind")
        }
        if case let .int(defaultVal) = row.defaultValue {
            #expect(defaultVal == 42)
        } else {
            Issue.record("Expected .int(42) defaultValue")
        }
    }

    @Test("NumberInputRow .decimal(defaultValue: 3.14) stores kind and default")
    func numberInputRowDecimalWithDefault() {
        let row = NumberInputRow(id: "rate", title: "Rate", kind: .decimal(defaultValue: 3.14))
        if case let .decimal(val) = row.kind {
            #expect(val != nil)
            #expect(abs(val! - 3.14) < 0.0001)
        } else {
            Issue.record("Expected .decimal(defaultValue: 3.14) kind")
        }
        if case let .double(defaultVal) = row.defaultValue {
            #expect(abs(defaultVal - 3.14) < 0.0001)
        } else {
            Issue.record("Expected .double(3.14) defaultValue")
        }
    }

    @Test("NumberInputRow .int(defaultValue: nil) has nil defaultValue")
    func numberInputRowIntegerNilHasNilDefault() {
        let row = NumberInputRow(id: "count", title: "Count", kind: .int(defaultValue: nil))
        #expect(row.defaultValue == nil)
    }

    @Test("NumberInputRow .decimal(defaultValue: nil) has nil defaultValue")
    func numberInputRowDecimalNilHasNilDefault() {
        let row = NumberInputRow(id: "rate", title: "Rate", kind: .decimal(defaultValue: nil))
        #expect(row.defaultValue == nil)
    }

    @Test("NumberInputRow stores placeholder")
    func numberInputRowPlaceholder() {
        let row = NumberInputRow(id: "count", title: "Count", placeholder: "0")
        #expect(row.placeholder == "0")
    }

    @Test("NumberInputRow nil placeholder by default")
    func numberInputRowNilPlaceholderByDefault() {
        let row = NumberInputRow(id: "count", title: "Count")
        #expect(row.placeholder == nil)
    }

    @Test("NumberInputRow nil defaultValue when not provided")
    func numberInputRowNilDefault() {
        let row = NumberInputRow(id: "count", title: "Count")
        #expect(row.defaultValue == nil)
    }

    @Test("NumberInputRow stores subtitle")
    func numberInputRowSubtitle() {
        let row = NumberInputRow(id: "count", title: "Count", subtitle: "Number of items")
        #expect(row.subtitle == "Number of items")
    }

    @Test("NumberInputRow stores validators")
    func numberInputRowStoresValidators() {
        let v = FormValidator { _ in nil }
        let row = NumberInputRow(id: "count", title: "Count", validators: [v])
        #expect(row.validators.count == 1)
    }

    @Test("NumberInputRow stores onChange actions")
    func numberInputRowStoresOnChangeActions() {
        let row = NumberInputRow(
            id: "count",
            title: "Count",
            onChange: [.showRow(id: "other", when: [])]
        )
        #expect(row.onChange.count == 1)
    }

    // MARK: RawRepresentable id overload

    @Test("NumberInputRow RawRepresentable id overload (.int(defaultValue: nil))")
    func numberInputRowRawRepresentableIdInteger() {
        enum RowID: String { case timeout = "network_timeout" }
        let row = NumberInputRow(id: RowID.timeout, title: "Timeout", kind: .int(defaultValue: nil))
        #expect(row.id == "network_timeout")
        #expect(row.isDecimal == false)
    }

    @Test("NumberInputRow RawRepresentable id overload (.decimal(defaultValue: nil))")
    func numberInputRowRawRepresentableIdDecimal() {
        enum RowID: String { case price = "item_price" }
        let row = NumberInputRow(id: RowID.price, title: "Price", kind: .decimal(defaultValue: nil))
        #expect(row.id == "item_price")
        #expect(row.isDecimal == true)
    }

    @Test("NumberInputRow RawRepresentable id with .int(defaultValue: 3)")
    func numberInputRowRawRepresentableIdWithIntDefault() {
        enum RowID: String { case retries = "max_retries" }
        let row = NumberInputRow(id: RowID.retries, title: "Retries", kind: .int(defaultValue: 3))
        #expect(row.id == "max_retries")
        if case let .int(val) = row.defaultValue {
            #expect(val == 3)
        } else {
            Issue.record("Expected .int(3) defaultValue")
        }
    }

    @Test("NumberInputRow RawRepresentable id with .decimal(defaultValue: 1.78)")
    func numberInputRowRawRepresentableIdWithDoubleDefault() {
        enum RowID: String { case ratio = "aspect_ratio" }
        let row = NumberInputRow(id: RowID.ratio, title: "Ratio", kind: .decimal(defaultValue: 1.78))
        #expect(row.id == "aspect_ratio")
        if case let .double(val) = row.defaultValue {
            #expect(abs(val - 1.78) < 0.0001)
        } else {
            Issue.record("Expected .double(1.78) defaultValue")
        }
    }

    // MARK: AnyFormRow wrapping

    @Test("AnyFormRow wraps NumberInputRow and casts back correctly (.int)")
    func anyFormRowWrapsNumberInputRowInteger() {
        let row = NumberInputRow(id: "count", title: "Count", kind: .int(defaultValue: 10))
        let anyRow = AnyFormRow(row)
        let cast = anyRow.asType(NumberInputRow.self)
        #expect(cast != nil)
        #expect(cast?.id == "count")
        #expect(cast?.isDecimal == false)
    }

    @Test("AnyFormRow wraps NumberInputRow and casts back correctly (.decimal)")
    func anyFormRowWrapsNumberInputRowDecimal() {
        let row = NumberInputRow(id: "rate", title: "Rate", kind: .decimal(defaultValue: 2.5))
        let anyRow = AnyFormRow(row)
        let cast = anyRow.asType(NumberInputRow.self)
        #expect(cast != nil)
        #expect(cast?.id == "rate")
        #expect(cast?.isDecimal == true)
    }

    @Test("AnyFormRow wrapping NumberInputRow carries id and title")
    func anyFormRowNumberInputRowCarriesMetadata() {
        let row = NumberInputRow(id: "meta", title: "Meta")
        let anyRow = AnyFormRow(row)
        #expect(anyRow.id == "meta")
        #expect(anyRow.title == "Meta")
    }

    @Test("NumberInputRow .int(defaultValue: 5) default is seeded into FormViewModel")
    func numberInputRowIntDefaultSeededIntoViewModel() {
        let form = FormDefinition(
            id: "test",
            title: "Test",
            rows: [AnyFormRow(NumberInputRow(id: "count", title: "Count", kind: .int(defaultValue: 5)))],
            saveBehaviour: .none
        )
        let vm = FormViewModel(formDefinition: form)
        let value: Int? = vm.value(for: "count")
        #expect(value == 5)
    }

    @Test("NumberInputRow .decimal(defaultValue: 1.5) default is seeded into FormViewModel")
    func numberInputRowDoubleDefaultSeededIntoViewModel() {
        let form = FormDefinition(
            id: "test",
            title: "Test",
            rows: [AnyFormRow(NumberInputRow(id: "rate", title: "Rate", kind: .decimal(defaultValue: 1.5)))],
            saveBehaviour: .none
        )
        let vm = FormViewModel(formDefinition: form)
        let value: Double? = vm.value(for: "rate")
        #expect(value == 1.5)
    }
}
