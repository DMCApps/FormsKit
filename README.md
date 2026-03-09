# FormKit

A declarative, type-safe form building framework for SwiftUI on iOS 17+. FormKit handles row types, validation, conditional visibility, reactive actions, persistence, and error display — all described in a single, composable DSL.

---

## Contents

- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Row Types](#row-types)
- [Validation](#validation)
- [Conditions](#conditions)
- [Row Actions](#row-actions)
- [Save Behaviour](#save-behaviour)
- [Persistence](#persistence)
- [Error Positions](#error-positions)
- [Loading States](#loading-states)
- [Type-Safe API](#type-safe-api)
- [FormViewModel](#formviewmodel)
- [Example App](#example-app)
- [Accessibility Identifiers](#accessibility-identifiers)

---

## Requirements

- iOS 17+
- Swift 5.9+

---

## Quick Start

Define a `FormDefinition`, then hand it to `DynamicFormView`:

```swift
import FormKit
import SwiftUI

struct ProfileForm: View {
    let form = FormDefinition(
        id: "profile",
        title: "Profile",
        saveBehaviour: .buttonNavigationBar()
    ) {
        TextInputRow(id: "name", title: "Name", placeholder: "Jane Appleseed",
                     validators: [.required()])
        TextInputRow(id: "email", title: "Email", keyboardType: .emailAddress,
                     validators: [.required(), .email()])
        BooleanSwitchRow(id: "notifications", title: "Push Notifications",
                         defaultValue: true)
    }

    var body: some View {
        NavigationStack {
            DynamicFormView(formDefinition: form)
        }
    }
}
```

---

## Row Types

### TextInputRow

Free-text input. Supports secure entry, keyboard hints, and input masks.

```swift
// Plain text
TextInputRow(id: "username", title: "Username", placeholder: "e.g. jappleseed")

// Password field
TextInputRow(id: "password", title: "Password", isSecure: true)

// Password field with show/hide toggle (eye button rendered inside the field)
TextInputRow(id: "password", title: "Password", isSecure: true, showSecureToggle: true)

// Specific keyboard type
TextInputRow(id: "email", title: "Email", keyboardType: .emailAddress)

// With an input mask — see Input Masks section
TextInputRow(id: "phone", title: "Phone", mask: .usPhone)
```

**FormKeyboardType cases:** `.default`, `.emailAddress`, `.url`, `.phonePad`, `.numberPad`, `.decimalPad`

When `isSecure: true` and `showSecureToggle: true`, an eye button is rendered inside the field. Tapping it toggles between `SecureField` (hidden) and `TextField` (visible) using SF Symbols `eye` / `eye.slash`.

---

### NumberInputRow

Numeric input, either integer or decimal. Displays a numeric keypad.

```swift
// Integer field
NumberInputRow(id: "count", title: "Quantity", kind: .int(defaultValue: 1))

// Decimal field with no default
NumberInputRow(id: "price", title: "Price (USD)", kind: .decimal(defaultValue: nil))
```

---

### BooleanSwitchRow

A toggle (on/off switch).

```swift
BooleanSwitchRow(
    id: "darkMode",
    title: "Dark Mode",
    subtitle: "Apply system-wide",
    defaultValue: false
)
```

---

### SingleValueRow

A picker for choosing one value from a `CaseIterable` enum.

```swift
enum Environment: String, CaseIterable, CustomStringConvertible, Codable, Sendable {
    case development, staging, production
    var description: String { rawValue.capitalized }
}

SingleValueRow<Environment>(
    id: "env",
    title: "Environment",
    defaultValue: .development
)
```

---

### MultiValueRow

A checkmark list for selecting zero or more values from a `CaseIterable` enum.

```swift
enum Permission: String, CaseIterable, CustomStringConvertible, Codable, Sendable, Hashable {
    case read, write, delete
    var description: String { rawValue.capitalized }
}

MultiValueRow<Permission>(
    id: "permissions",
    title: "Permissions",
    defaultValue: [.read]
)
```

---

### InfoRow

Read-only label/value pair. Never persisted. Value is re-evaluated at each render.

```swift
InfoRow(id: "version", title: "App Version") {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
}

// Capture mutable state
var counter = 0
InfoRow(id: "count", title: "Tap Count") { "\(counter)" }
```

---

### ButtonRow

Tappable row that fires a closure (does not navigate).

```swift
ButtonRow(id: "clearCache", title: "Clear Cache") {
    Cache.shared.clear()
}
```

---

### NavigationRow

Drills into a sub-form when tapped.

```swift
NavigationRow(
    id: "advanced",
    title: "Advanced Settings",
    destination: advancedFormDefinition
)
```

---

### FormSection

Groups rows under a section header. The entire section can be shown, hidden, or disabled as a unit.

```swift
FormSection(id: "address", title: "Shipping Address") {
    TextInputRow(id: "street", title: "Street")
    TextInputRow(id: "city",   title: "City")
    TextInputRow(id: "zip",    title: "Postcode")
}
```

---

## Input Masks

`FormInputMask` enforces a fixed-format pattern as the user types. Slot characters are `#` (digit), `A` (letter), `*` (any); everything else is a literal auto-inserted between slots.

```swift
// Built-in US phone mask — (###) ###-####
// Stores raw digits "4155551234"
TextInputRow(id: "phone", title: "Phone", mask: .usPhone)

// Built-in date mask — ##/##/####
// Stores a typed Date value (not a string)
TextInputRow(id: "dob", title: "Date of Birth", mask: .date)

// Custom pattern — Canadian postal code
TextInputRow(id: "postal", title: "Postal Code",
             mask: FormInputMask("A#A #A#"))

// Custom mask with round-trip conversion closures
let creditCard = FormInputMask("#### #### #### ####",
    toStorable: { rawDigits in .string(rawDigits) },
    fromStorable: { stored in
        if case let .string(s) = stored { return s }
        return nil
    }
)
TextInputRow(id: "card", title: "Card Number", mask: creditCard)
```

---

## Validation

Validators are attached to individual rows. Each validator has a **trigger** (when it fires) and an **error position** (where the message appears).

### Built-in Validators

```swift
// Required (non-null, non-empty)
.required()
.required(message: "This field is mandatory")

// Email address format
.email()

// String length
.minLength(3)
.maxLength(50)

// Numeric range — works with Int or Double
.range(1...100)
.range(0.0...9.99)

// Regex
.regex("^[A-Z]{2}[0-9]{6}$", message: "Invalid passport number")

// Type constraints
.double()     // must parse as Double
.integer()    // must parse as Int

// Network addresses
.ipv4()
.url()

// Date validity
.date()                     // uses mask format when mask is set
.date(format: "MM/dd/yyyy") // explicit format

// Cross-field equality (e.g. password confirmation)
.matches(rowId: "password", message: "Passwords must match")

// Custom predicate
.custom(message: "Must be even") { value, _ in
    guard case let .int(n) = value else { return true }
    return n % 2 == 0
}
```

### Validation Triggers

```swift
// Default — fires when user taps Save
.required(trigger: .onSave)

// Fires immediately on every keystroke (text/number rows)
.required(trigger: .onChange)

// Fires after the user stops typing for 0.5 seconds
.email(trigger: .onChangeDebounced(seconds: 0.5))

// Fires when the field loses focus (text/number rows)
.required(trigger: .onBlur)
```

### SelectionValidator

A simplified validator for `SingleValueRow`, `MultiValueRow`, and `BooleanSwitchRow` (trigger is always `.onSave`):

```swift
SingleValueRow<Environment>(
    id: "env", title: "Environment",
    validators: [
        SelectionValidator.required(),
        SelectionValidator.custom(message: "Production requires approval") { value, _ in
            value != "production"
        }
    ]
)
```

---

## Conditions

`FormCondition` evaluates against the current form store and is used by row actions to decide when they fire.

### Equality

```swift
.equals(rowId: "env", string: "production")
.equals(rowId: "count", int: 0)
.equals(rowId: "enabled", bool: true)
.notEquals(rowId: "plan", string: "free")
```

### Existence

```swift
.isEmpty(rowId: "notes")       // null, empty string, or empty array
.isNotEmpty(rowId: "email")    // has a value
```

### Boolean Shorthands

```swift
.isTrue(rowId: "showAdvanced")
.isFalse(rowId: "isGuest")
```

### Comparisons

```swift
.greaterThan(rowId: "quantity", value: .int(0))
.lessThanOrEqual(rowId: "discount", value: .double(0.5))
```

### Collection

```swift
.contains(rowId: "permissions", value: .string("write"))
.notContains(rowId: "tags", value: .string("archived"))
```

### Composition

```swift
// All must be true
.and([
    .isTrue(rowId: "enabled"),
    .isNotEmpty(rowId: "email")
])

// At least one must be true
.or([
    .equals(rowId: "role", string: "admin"),
    .equals(rowId: "role", string: "moderator")
])

// Negate
.not(.isEmpty(rowId: "username"))
```

### Custom

```swift
.custom { store in
    guard let age: Int = store.value(for: "age") else { return false }
    return age >= 18
}
```

---

## Row Actions

Row actions are attached to a row's `onChange` array and fire reactively whenever that row's value changes.

### Show / Hide

```swift
BooleanSwitchRow(
    id: "showAddress",
    title: "Ship to different address",
    onChange: [
        .showRow(id: "address", when: [.isTrue(rowId: "showAddress")]),
        .hideRow(id: "address", when: [.isFalse(rowId: "showAddress")])
    ]
)
```

### Disable / Enable

```swift
BooleanSwitchRow(
    id: "lockFields",
    title: "Lock form",
    onChange: [
        .disableRow(id: "name",  when: [.isTrue(rowId: "lockFields")]),
        .disableRow(id: "email", when: [.isTrue(rowId: "lockFields")])
    ]
)
```

### Set Value on Another Row

```swift
SingleValueRow<Environment>(
    id: "env",
    title: "Environment",
    onChange: [
        .setValue(on: "apiURL", timing: .immediate) { store in
            guard case let .string(env) = store["env"] else { return nil }
            return .string(env == "production" ? "https://api.example.com" : "https://staging.example.com")
        }
    ]
)
```

### Clear Value

```swift
BooleanSwitchRow(
    id: "guestMode",
    title: "Guest Mode",
    onChange: [
        .clearValue(id: "email",    when: [.isTrue(rowId: "guestMode")]),
        .clearValue(id: "password", when: [.isTrue(rowId: "guestMode")])
    ]
)
```

### Re-run Validation

```swift
TextInputRow(
    id: "confirmPassword",
    title: "Confirm Password",
    isSecure: true,
    onChange: [
        .runValidation(timing: .immediate)
    ]
)
```

### Custom Action

```swift
NumberInputRow(
    id: "quantity",
    title: "Quantity",
    kind: .int(defaultValue: 1),
    onChange: [
        .custom(timing: .debounced(0.3)) { store, rowId in
            guard let qty: Int = store.value(for: rowId) else { return }
            Analytics.track("quantity_changed", properties: ["value": qty])
        }
    ]
)
```

### Timing

```swift
// Fire immediately on change (default)
.showRow(id: "details", when: [...], timing: .immediate)

// Debounce — wait until value is stable
.custom(timing: .debounced(0.5)) { store, rowId in ... }
```

---

## Save Behaviour

Controls where the save button appears (or whether saving is automatic).

```swift
// Navigation bar "Save" button
FormDefinition(id: "settings", title: "Settings",
               saveBehaviour: .buttonNavigationBar()) { ... }

// Custom title
FormDefinition(id: "settings", title: "Settings",
               saveBehaviour: .buttonNavigationBar(title: "Apply")) { ... }

// Prominent button inside the scroll area, below all rows
FormDefinition(id: "profile", title: "Profile",
               saveBehaviour: .buttonBottomForm()) { ... }

// Button pinned to bottom, outside the scroll area
FormDefinition(id: "checkout", title: "Checkout",
               saveBehaviour: .buttonStickyBottom(title: "Place Order")) { ... }

// Auto-save on every change — no save button shown
FormDefinition(id: "preferences", title: "Preferences",
               saveBehaviour: .onChange) { ... }

// No save button, no automatic saving (display-only or manual control)
FormDefinition(id: "about", title: "About",
               saveBehaviour: .none) { ... }
```

### Post-Save Actions

```swift
FormDefinition(
    id: "profile",
    title: "Profile",
    saveBehaviour: .buttonNavigationBar(),
    onSave: [
        FormSaveAction { store in
            if let name: String = store.value(for: "name") {
                print("Saved name:", name)
            }
        }
    ]
) { ... }
```

---

## Persistence

FormKit ships three persistence backends. Pass one to `FormDefinition` or `FormViewModel`.

### UserDefaults

```swift
let form = FormDefinition(
    id: "settings",
    title: "Settings",
    persistence: FormPersistenceUserDefaults(),
    saveBehaviour: .onChange
) { ... }
```

### File (Application Support)

```swift
FormDefinition(
    id: "profile",
    title: "Profile",
    persistence: FormPersistenceFile(),
    saveBehaviour: .buttonNavigationBar()
) { ... }

// Custom directory
FormDefinition(
    id: "profile",
    title: "Profile",
    persistence: FormPersistenceFile(directory: myDirectory),
    saveBehaviour: .buttonNavigationBar()
) { ... }
```

### In-Memory

Useful for testing or ephemeral state that shouldn't survive app restarts.

```swift
FormDefinition(
    id: "draft",
    title: "New Post",
    persistence: FormPersistenceMemory(),
    saveBehaviour: .buttonNavigationBar()
) { ... }
```

### Key Prefix

All backends support a `keyPrefix` to namespace data across forms or environments:

```swift
FormPersistenceUserDefaults(keyPrefix: "debug")
FormPersistenceFile(keyPrefix: "v2")
FormPersistenceMemory(keyPrefix: "test")
```

### Custom Backend

Conform to `FormPersistence` to implement any storage mechanism:

```swift
actor MyCloudPersistence: FormPersistence {
    func save(_ values: FormValueStore, formId: String) async throws {
        let data = try JSONEncoder().encode(values)
        try await CloudAPI.upload(data, key: formId)
    }

    func load(formId: String) async throws -> FormValueStore {
        guard let data = try await CloudAPI.download(key: formId) else {
            return FormValueStore()
        }
        return try JSONDecoder().decode(FormValueStore.self, from: data)
    }

    func clear(formId: String) async throws {
        try await CloudAPI.delete(key: formId)
    }
}
```

### Mixed Persistence (routing rows to different backends)

`FormPersistenceMixed` fans out a single form's values to multiple backends, with each backend responsible for a declared subset of row IDs. This is the recommended approach when different rows have different security requirements — for example, persisting most fields to UserDefaults while routing sensitive fields (passwords, PINs) to the Keychain.

#### RowScope

Each backend entry declares a `RowScope` that controls which keys it receives:

| Scope | Behaviour |
|-------|-----------|
| `.all` | Backend receives every key in the store (default) |
| `.including(["id1", "id2"])` | Backend receives **only** the listed row IDs |
| `.excluding(["id1", "id2"])` | Backend receives every row ID **except** the listed ones |

#### Basic usage

```swift
let persistence = FormPersistenceMixed([
    .init(FormPersistenceUserDefaults(), scope: .excluding(["password"])),
    .init(MyKeychainPersistence(),       scope: .including(["password"]))
])

let form = FormDefinition(
    id: "login",
    title: "Sign In",
    persistence: persistence,
    saveBehaviour: .buttonNavigationBar()
) {
    TextInputRow(id: "email",    title: "Email",    keyboardType: .emailAddress)
    TextInputRow(id: "password", title: "Password", isSecure: true)
}
```

#### With a typed RowID enum

If you use `TypedFormDefinition`, pass your enum values directly — no `.rawValue` needed:

```swift
enum LoginRow: String {
    case email, password, pin
}

FormPersistenceMixed([
    .init(FormPersistenceUserDefaults(), scope: .excluding([LoginRow.password, LoginRow.pin])),
    .init(MyKeychainPersistence(),       scope: .including([LoginRow.password, LoginRow.pin]))
])
```

#### Execution order

**Save** — entries are processed in array order, sequentially. Each backend receives only the keys permitted by its scope. If a backend throws, execution stops immediately and subsequent backends are **not** called. Place the most critical backend first if partial failure is a concern.

**Load** — entries are loaded in array order, sequentially. Results are merged using last-writer-wins: if two backends return a value for the same key, the **later entry** in the array wins. This is deterministic and predictable; in practice it should never trigger when scopes are non-overlapping.

**Clear** — entries are cleared in array order, sequentially. The same early-exit-on-throw behaviour applies as with save.

---

## Error Positions

Each validator declares where its error message appears:

```swift
// Default — below the row that owns the validator
.required(errorPosition: .belowRow)

// Below a different row (e.g. show confirm-password error on the first field)
.matches(rowId: "password", errorPosition: .belowRow(id: "password"))

// Scrolls to top — useful for summary errors
.required(errorPosition: .formTop)

// Appears below all rows, above the save button
.required(errorPosition: .formBottom)

// Presented as a dismissible alert dialog
.required(errorPosition: .alert)

// Mix positions on the same row
TextInputRow(
    id: "email",
    title: "Email",
    validators: [
        .required(trigger: .onSave, errorPosition: .alert),
        .email(trigger: .onBlur, errorPosition: .belowRow)
    ]
)
```

---

## Loading States

While loading persisted values, FormKit displays a placeholder. Three options are available:

```swift
// Default — centered spinner
FormDefinition(id: "form", title: "Form",
               loadingStyle: .activityIndicator) { ... }

// Shimmer skeleton matching the row layout
FormDefinition(id: "form", title: "Form",
               loadingStyle: .skeleton) { ... }

// Fully custom loading view
FormDefinition(id: "form", title: "Form",
               loadingStyle: .custom { AnyView(MyLoadingView()) }) { ... }
```

---

## Type-Safe API

`TypedFormDefinition` and `TypedFormViewModel` bind a `RawRepresentable` enum as the row ID type, making row IDs compile-time checked.

```swift
// 1. Declare your row ID enum
enum ProfileRow: String {
    case name, email, bio, notifications
}

// 2. Build a TypedFormDefinition
let form = TypedFormDefinition<ProfileRow>(
    id: "profile",
    title: "Profile",
    saveBehaviour: .buttonNavigationBar()
) {
    TextInputRow(id: ProfileRow.name.rawValue,          title: "Name")
    TextInputRow(id: ProfileRow.email.rawValue,         title: "Email")
    TextInputRow(id: ProfileRow.bio.rawValue,           title: "Bio")
    BooleanSwitchRow(id: ProfileRow.notifications.rawValue, title: "Notifications")
}

// 3. Create a typed view model
let typedVM = TypedFormViewModel(form: form)

// 4. Use the typed API — row IDs are enums, not strings
let name: String? = typedVM.value(for: .name)
typedVM.setString("Jane", for: .name)
typedVM.rowDidBlur(.email)

// 5. Bind the inner viewModel to DynamicFormView
DynamicFormView(formDefinition: form.definition, viewModel: typedVM.viewModel)
```

### RawRepresentable Overloads

Conditions and validators also accept your enum directly:

```swift
// Condition
.isTrue(rowId: ProfileRow.notifications)

// Validator cross-field match
.matches(rowId: ProfileRow.email)

// Error position targeting another row
.required(errorPosition: .belowRow(id: ProfileRow.email))
```

---

## FormViewModel

`DynamicFormView` creates and manages a `FormViewModel` internally. For custom UIs or programmatic control, create one directly:

```swift
@State private var viewModel = FormViewModel(formDefinition: myForm)

// Read values
let email: String? = viewModel.value(for: "email")
let raw: AnyCodableValue? = viewModel.rawValue(for: "email")

// Write values
viewModel.setString("jane@example.com", for: "email")
viewModel.setBool(true, for: "notifications")
viewModel.setInt(42, for: "count")
viewModel.setDouble(3.14, for: "price")
viewModel.setDate(Date(), for: "dob")

// Multi-value toggle
viewModel.toggleArrayValue(.string("write"), for: "permissions")

// Lifecycle
await viewModel.loadFromPersistence()
let success = await viewModel.save()
viewModel.reset()
await viewModel.clearPersistence()

// Validation
let isValid = viewModel.validateAll()
viewModel.rowDidBlur("email")
let errors = viewModel.errorsForRow("email")

// State
viewModel.status       // FormStatus: needsLoad | loading | ready | saving | loadFailed(Error)
viewModel.isDirty      // Bool — changed since last save
viewModel.isValid      // Bool — no errors on visible rows
viewModel.saveError    // Error? — most recent save failure

// Visibility
viewModel.isRowVisible(row)
viewModel.isRowDisabled(row)
viewModel.visibleRows
```

### FormStatus

```swift
switch viewModel.status {
case .needsLoad:           // Awaiting initial load
case .loading:             // Load in progress
case .ready:               // Ready for interaction
case .saving:              // Save in progress
case .loadFailed(let err): // Load failed — defaults shown
}
```

---

## Example App

The `FormKitExample` app (in `FormKitExample/`) demonstrates every capability. Run it in Xcode after generating the project with Tuist (`tuist generate` from the `FormKitExample` directory).

| Screen | Demonstrates |
|--------|-------------|
| **Row Types** | All 9 row types in a single form |
| **Validation** | All built-in validators, all triggers (.onSave, .onChange, .onChangeDebounced, .onBlur), all error positions |
| **Conditions** | isTrue/isFalse, equals, isEmpty/isNotEmpty, numeric comparisons, contains, and/or/not composition |
| **Actions** | showRow, hideRow, disableRow, clearValue, setValue, runValidation, custom; immediate vs. debounced timing |
| **Save Behaviour** | All 5 saveBehaviour variants side-by-side |
| **Error Positions** | belowRow, belowRow(id:), formTop, formBottom, alert |
| **Input Masks** | .usPhone, .date, custom patterns, character slot behaviour |
| **Persistence** | Memory, UserDefaults, and File backends; auto-save and manual save |

---

## Accessibility Identifiers

FormKit sets stable accessibility identifiers on all interactive elements, enabling XCUITest automation:

| Identifier | Element |
|------------|---------|
| `formkit.field.<rowId>` | TextField, SecureField, NumberInputRow |
| `formkit.toggle.<rowId>` | BooleanSwitchRow Toggle |
| `formkit.saveButton` | All save button variants |
| `formkit.errors.<rowId>` | Per-row inline ValidationErrorView |
| `formkit.errors.formTop` | Form-top error banner |
| `formkit.errors.formBottom` | Form-bottom error banner |

Example XCUITest usage:

```swift
// Tap a field
app.textFields["formkit.field.email"].tap()

// Flip a toggle
app.switches["formkit.toggle.notifications"].tap()

// Tap save
app.buttons["formkit.saveButton"].tap()

// Assert inline error appeared
XCTAssertTrue(app.otherElements["formkit.errors.email"].waitForExistence(timeout: 2))

// Assert form-top banner
XCTAssertTrue(app.otherElements["formkit.errors.formTop"].waitForExistence(timeout: 2))
```
