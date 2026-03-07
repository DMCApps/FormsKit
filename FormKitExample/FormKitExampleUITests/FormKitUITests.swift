import XCTest

// MARK: - FormKitUITests
//
// These UI tests exercise behaviour that unit tests cannot cover:
// - @FocusState / blur firing rowDidBlur in a real UIKit responder chain
// - Row show/hide animations (the row is actually removed from the hierarchy)
// - disableRow blocking user interaction
// - Input mask formatting as the user types
// - Save button placement per FormSaveBehaviour
// - Error banners appearing at the correct position (belowRow vs formTop vs alert)
//
// Accessibility identifier scheme (set in FormKit source):
//   "formkit.field.<rowId>"   — TextField / SecureField / NumberInputRow
//   "formkit.toggle.<rowId>"  — BooleanSwitchRow Toggle
//   "formkit.saveButton"      — all save button variants
//   "formkit.errors.<rowId>"  — inline ValidationErrorView
//   "formkit.errors.formTop"  — form-top error banner
//   "formkit.errors.formBottom" — form-bottom error banner

final class FormKitUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Helpers

    /// Navigate from the catalogue into a named form.
    private func openForm(titled title: String) {
        app.tables.staticTexts[title].tap()
    }

    /// Return the TextField / SecureField for the given row ID.
    private func field(_ rowId: String) -> XCUIElement {
        app.textFields["formkit.field.\(rowId)"]
    }

    /// Return the Toggle for the given row ID.
    private func toggle(_ rowId: String) -> XCUIElement {
        app.switches["formkit.toggle.\(rowId)"]
    }

    /// Return the error container for a specific row.
    private func errorView(_ rowId: String) -> XCUIElement {
        app.otherElements["formkit.errors.\(rowId)"]
    }

    /// Return the form-level error banner at the top.
    private func formTopErrorView() -> XCUIElement {
        app.otherElements["formkit.errors.formTop"]
    }

    /// Return the save button (any variant).
    private func saveButton() -> XCUIElement {
        app.buttons["formkit.saveButton"]
    }

    // MARK: - 1. Blur triggers onBlur validation

    func testBlurTriggersOnBlurValidation() throws {
        openForm(titled: "Validation")

        // "onBlur" field — error fires on blur, not on typing.
        let blurField = field("onBlurTrigger")
        XCTAssertTrue(blurField.waitForExistence(timeout: 3))

        // Tap into the field — no error yet.
        blurField.tap()
        XCTAssertFalse(errorView("onBlurTrigger").exists)

        // Tap away to blur the field — error should now appear.
        app.navigationBars.firstMatch.tap()
        XCTAssertTrue(errorView("onBlurTrigger").waitForExistence(timeout: 2))
    }

    func testOnChangeValidationFiresImmediately() throws {
        openForm(titled: "Validation")

        let changeField = field("onChangeTrigger")
        XCTAssertTrue(changeField.waitForExistence(timeout: 3))

        // Tap then clear — error should appear without blurring.
        changeField.tap()
        changeField.typeText("x")
        changeField.clearText()
        XCTAssertTrue(errorView("onChangeTrigger").waitForExistence(timeout: 2))
    }

    // MARK: - 2. Input mask formatting

    func testUSPhoneMaskFormatsCorrectly() throws {
        openForm(titled: "Input Masks")

        let phoneField = field("usPhone")
        XCTAssertTrue(phoneField.waitForExistence(timeout: 3))

        phoneField.tap()
        phoneField.typeText("4155551234")

        // The mask should format "4155551234" → "(415) 555-1234".
        XCTAssertEqual(phoneField.value as? String, "(415) 555-1234")
    }

    func testMaskLimitsInputToPatternLength() throws {
        openForm(titled: "Input Masks")

        let phoneField = field("usPhone")
        XCTAssertTrue(phoneField.waitForExistence(timeout: 3))

        phoneField.tap()
        // Type more digits than the mask allows (10 slots).
        phoneField.typeText("41555512349999")

        // Value should be clamped to 10 digits formatted.
        XCTAssertEqual(phoneField.value as? String, "(415) 555-1234")
    }

    // MARK: - 3. Conditional row visibility

    func testShowRowAppearsWhenConditionMet() throws {
        openForm(titled: "Conditions")

        // "shownWhenTrue" starts hidden (toggle is off).
        let targetField = field("shownWhenTrue")
        XCTAssertFalse(targetField.exists)

        // Turn the toggle on.
        let boolToggle = toggle("boolToggle")
        XCTAssertTrue(boolToggle.waitForExistence(timeout: 3))
        boolToggle.tap()

        // Row should now be visible.
        XCTAssertTrue(targetField.waitForExistence(timeout: 2))
    }

    func testHideRowDisappearsWhenConditionMet() throws {
        openForm(titled: "Conditions")

        // "shownWhenFalse" starts visible (toggle is off = isFalse = true).
        let targetField = field("shownWhenFalse")
        XCTAssertTrue(targetField.waitForExistence(timeout: 3))

        // Turn the toggle on — isFalse becomes false → row should hide.
        let boolToggle = toggle("boolToggle")
        XCTAssertTrue(boolToggle.waitForExistence(timeout: 3))
        boolToggle.tap()

        XCTAssertFalse(targetField.waitForExistence(timeout: 2))
    }

    // MARK: - 4. disableRow blocks interaction

    func testDisabledRowBlocksInput() throws {
        openForm(titled: "Row Actions")

        // disableTarget starts enabled.
        let target = field("disableTarget")
        XCTAssertTrue(target.waitForExistence(timeout: 3))
        XCTAssertTrue(target.isEnabled)

        // Turn on the disable toggle.
        let disableToggle = toggle("disableToggle")
        XCTAssertTrue(disableToggle.waitForExistence(timeout: 3))
        disableToggle.tap()

        // Row should now be disabled.
        XCTAssertFalse(target.isEnabled)
    }

    // MARK: - 5. Error position — belowRow

    func testBelowRowErrorAppearsAfterSave() throws {
        openForm(titled: "Error Positions")
        app.tables.staticTexts["Below Row"].tap()

        // Tap Save without filling in the required field.
        let save = saveButton()
        XCTAssertTrue(save.waitForExistence(timeout: 3))
        save.tap()

        // Inline error should appear below the row.
        XCTAssertTrue(errorView("field1").waitForExistence(timeout: 2))
    }

    // MARK: - 6. Error position — formTop

    func testFormTopErrorAppearsAfterSave() throws {
        openForm(titled: "Error Positions")
        app.tables.staticTexts["Form Top"].tap()

        let save = saveButton()
        XCTAssertTrue(save.waitForExistence(timeout: 3))
        save.tap()

        XCTAssertTrue(formTopErrorView().waitForExistence(timeout: 2))
    }

    // MARK: - 7. Error position — alert

    func testAlertErrorAppearsAfterSave() throws {
        openForm(titled: "Error Positions")
        app.tables.staticTexts["Alert"].tap()

        let save = saveButton()
        XCTAssertTrue(save.waitForExistence(timeout: 3))
        save.tap()

        // An alert should be presented.
        XCTAssertTrue(app.alerts["Validation Error"].waitForExistence(timeout: 2))
    }

    // MARK: - 8. Save button placement

    func testNavBarSaveButtonExists() throws {
        openForm(titled: "Save Behaviour")
        app.tables.staticTexts[".buttonNavigationBar()"].tap()

        // Save button should be in the navigation bar area.
        let save = saveButton()
        XCTAssertTrue(save.waitForExistence(timeout: 3))
        XCTAssertTrue(app.navigationBars.buttons["Save"].exists)
    }

    func testStickyBottomSaveButtonExists() throws {
        openForm(titled: "Save Behaviour")
        app.tables.staticTexts[".buttonStickyBottom()"].tap()

        let save = saveButton()
        XCTAssertTrue(save.waitForExistence(timeout: 3))
    }
}

// MARK: - XCUIElement helpers

private extension XCUIElement {
    /// Clears all text in a text field.
    func clearText() {
        guard let stringValue = value as? String, !stringValue.isEmpty else { return }
        tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }
}
