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

    /// Navigate from the catalogue into a named form by title.
    /// Scrolls the catalogue list until the row is visible and tappable.
    private func openForm(titled title: String) {
        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        let cell = app.staticTexts[title]
        // Scroll until the cell exists in the hierarchy.
        var existenceAttempts = 0
        while !cell.exists, existenceAttempts < 5 {
            list.swipeUp(velocity: .slow)
            existenceAttempts += 1
        }
        XCTAssertTrue(cell.waitForExistence(timeout: 3), "Could not find '\(title)' after \(existenceAttempts) swipes")
        // Scroll a little more if needed to make it hittable (not obscured).
        var hittableAttempts = 0
        while !cell.isHittable, hittableAttempts < 5 {
            list.swipeUp(velocity: .slow)
            hittableAttempts += 1
        }
        // If still not hittable, scroll back up in case we overshot.
        if !cell.isHittable {
            list.swipeDown(velocity: .slow)
        }
        cell.tap()
        // Wait for the navigation bar title to update, confirming the push completed.
        let navBar = app.navigationBars[title]
        _ = navBar.waitForExistence(timeout: 5)
    }

    /// Navigate into a FormKit NavigationRow sub-form by its row ID.
    private func openSubForm(id rowId: String) {
        let cell = app.descendants(matching: .any).matching(identifier: "formkit.navrow.\(rowId)").firstMatch
        // Wait for the cell to appear (navigation may still be animating).
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        let list = app.collectionViews.firstMatch
        var attempts = 0
        while !cell.isHittable, attempts < 5 {
            list.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(cell.isHittable, "Could not reach navrow '\(rowId)'")
        cell.tap()
        // Wait for the sub-form content to appear before proceeding.
        _ = app.collectionViews.firstMatch.waitForExistence(timeout: 5)
    }

    /// Return the TextField or SecureField for the given row ID.
    /// Checks textFields first; falls back to secureTextFields for isSecure rows.
    private func field(_ rowId: String) -> XCUIElement {
        let identifier = "formkit.field.\(rowId)"
        let textField = app.textFields[identifier]
        if textField.exists { return textField }
        return app.secureTextFields[identifier]
    }
    
    /// Return the full Toggle row for the given row ID.
    private func toggle(_ rowId: String) -> XCUIElement {
        app.switches["formkit.toggle.\(rowId)"]
    }
    
    /// Return the inner switch of the Toggle for the given row ID.
    private func toggleSwitch(_ rowId: String) -> XCUIElement {
        app.switches["formkit.toggle.\(rowId)"].switches.firstMatch
    }

    /// Return the error container for a specific row.
    /// Uses descendants(matching: .any) because the identifier is on a VStack container,
    /// not a staticText — querying staticTexts directly is unreliable for container views.
    private func errorView(_ rowId: String) -> XCUIElement {
        app.descendants(matching: .any)["formkit.errors.\(rowId)"]
    }

    /// Return the form-level error banner at the top.
    /// Uses descendants(matching: .any) because the identifier is on a VStack container,
    /// not a staticText — querying staticTexts directly is unreliable for container views.
    private func formTopErrorView() -> XCUIElement {
        app.descendants(matching: .any)["formkit.errors.formTop"]
    }

    /// Return the save button (any variant).
    private func saveButton() -> XCUIElement {
        app.buttons["formkit.saveButton"]
    }

    /// Type text character by character to allow the SwiftUI binding to process
    /// each keystroke incrementally (important for input mask fields).
    private func typeSlowly(_ text: String, into element: XCUIElement) {
        for char in text {
            element.typeText(String(char))
        }
    }

    // MARK: - 1. Blur triggers onBlur validation

    func testBlurTriggersOnBlurValidation() throws {
        openForm(titled: "Validation")

        // "onBlur" field — error fires on blur, not on typing.
        let blurField = field("onBlurTrigger")
        XCTAssertTrue(blurField.waitForExistence(timeout: 5))

        // Tap into the field — no error yet.
        blurField.tap()
        XCTAssertFalse(errorView("onBlurTrigger").exists)

        // Tap a different field to blur this one and trigger onBlur validation.
        let otherField = field("onChangeTrigger")
        XCTAssertTrue(otherField.waitForExistence(timeout: 3))
        otherField.tap()

        // Error should now appear — wait for @FocusState onChange + SwiftUI re-render.
        XCTAssertTrue(errorView("onBlurTrigger").waitForExistence(timeout: 5))
    }

    func testOnChangeValidationFiresImmediately() throws {
        openForm(titled: "Validation")

        let changeField = field("onChangeTrigger")
        XCTAssertTrue(changeField.waitForExistence(timeout: 5))

        // Tap then type, then clear — error should appear without blurring.
        changeField.tap()
        changeField.typeText("x")
        changeField.clearText()

        // Error should appear immediately on onChange — wait for SwiftUI re-render.
        XCTAssertTrue(errorView("onChangeTrigger").waitForExistence(timeout: 5))
    }

    func testFocusAloneDoesNotTriggerOnChangeValidation() throws {
        openForm(titled: "Validation")

        let changeField = field("onChangeTrigger")
        XCTAssertTrue(changeField.waitForExistence(timeout: 5))

        // Tap the onChange field — gaining focus must NOT fire validation.
        changeField.tap()
        XCTAssertFalse(
            errorView("onChangeTrigger").exists,
            "Error should not appear on focus before any value change"
        )

        // Blur by tapping another field — still no error (nothing was typed).
        let blurField = field("onBlurTrigger")
        XCTAssertTrue(blurField.waitForExistence(timeout: 3))
        blurField.tap()
        XCTAssertFalse(
            errorView("onChangeTrigger").exists,
            "Error should not appear after blur when no value was typed"
        )
    }

    func testFocusAloneDoesNotTriggerOnChangeDebounceValidation() throws {
        openForm(titled: "Validation")

        let debouncedField = field("onDebouncedTrigger")
        XCTAssertTrue(debouncedField.waitForExistence(timeout: 5))

        // Tap the debounced field — gaining focus must NOT fire validation.
        debouncedField.tap()
        XCTAssertFalse(
            errorView("onDebouncedTrigger").exists,
            "Error should not appear on focus before any value change"
        )

        // Wait longer than the debounce interval (0.5 s) to ensure the timer
        // did not start from a spurious focus-triggered value change.
        Thread.sleep(forTimeInterval: 1.0)
        XCTAssertFalse(
            errorView("onDebouncedTrigger").exists,
            "Error should not appear after debounce interval when no value was typed"
        )

        // Blur by tapping another field — still no error.
        let blurField = field("onBlurTrigger")
        XCTAssertTrue(blurField.waitForExistence(timeout: 3))
        blurField.tap()
        XCTAssertFalse(
            errorView("onDebouncedTrigger").exists,
            "Error should not appear after blur when no value was typed"
        )
    }

    // MARK: - 2. Input mask formatting

    func testUSPhoneMaskFormatsCorrectly() throws {
        openForm(titled: "Input Masks")

        let phoneField = field("usPhone")
        XCTAssertTrue(phoneField.waitForExistence(timeout: 5))

        phoneField.tap()
        // Type one character at a time so the binding processes each keystroke.
        typeSlowly("4155551234", into: phoneField)

        // The mask should format "4155551234" → "(415) 555-1234".
        // Wait for SwiftUI binding to settle and re-render the field.
        let formattedPredicate = NSPredicate(format: "value == '(415) 555-1234'")
        let expectation = XCTNSPredicateExpectation(predicate: formattedPredicate, object: phoneField)
        XCTWaiter().wait(for: [expectation], timeout: 5)
        XCTAssertEqual(phoneField.value as? String, "(415) 555-1234")
    }

    func testMaskLimitsInputToPatternLength() throws {
        openForm(titled: "Input Masks")

        let phoneField = field("usPhone")
        XCTAssertTrue(phoneField.waitForExistence(timeout: 5))

        phoneField.tap()
        // Type more digits than the mask allows (10 slots), one char at a time.
        typeSlowly("41555512349999", into: phoneField)

        // Value should be clamped to 10 digits formatted.
        let clampedPredicate = NSPredicate(format: "value == '(415) 555-1234'")
        let expectation = XCTNSPredicateExpectation(predicate: clampedPredicate, object: phoneField)
        XCTWaiter().wait(for: [expectation], timeout: 5)
        XCTAssertEqual(phoneField.value as? String, "(415) 555-1234")
    }

    // MARK: - 3. Conditional row visibility

    func testShowRowAppearsWhenConditionMet() throws {
        openForm(titled: "Conditions")

        // Wait for the toggle to confirm the form has fully settled, then verify
        // "shownWhenTrue" is hidden (toggle is off). Re-query rather than capturing
        // upfront to avoid a stale element reference from the navigation transition.
        let boolToggle = toggleSwitch("boolToggle")
        XCTAssertTrue(boolToggle.waitForExistence(timeout: 5))
        XCTAssertFalse(field("shownWhenTrue").exists)

        // Turn the toggle on.
        boolToggle.tap()

        // Row should now be visible — wait up to 5 s for SwiftUI re-render.
        XCTAssertTrue(field("shownWhenTrue").waitForExistence(timeout: 5))
    }

    func testHideRowDisappearsWhenConditionMet() throws {
        openForm(titled: "Conditions")

        // "shownWhenFalse" starts visible (toggle is off = isFalse = true).
        let boolToggle = toggleSwitch("boolToggle")
        XCTAssertTrue(boolToggle.waitForExistence(timeout: 5))
        XCTAssertTrue(field("shownWhenFalse").waitForExistence(timeout: 5))

        // Turn the toggle on — isFalse becomes false → row should hide.
        boolToggle.tap()

        // Row should now be gone — waitForExistence should timeout and return false.
        XCTAssertFalse(field("shownWhenFalse").waitForExistence(timeout: 3))
    }

    // MARK: - 4. disableRow blocks interaction

    func testDisabledRowBlocksInput() throws {
        openForm(titled: "Row Actions")

        // disableTarget starts enabled.
        let target = field("disableTarget")
        XCTAssertTrue(target.waitForExistence(timeout: 5))
        XCTAssertTrue(target.isEnabled)

        // Turn on the disable toggle.
        let disableToggle = toggleSwitch("disableToggle")
        XCTAssertTrue(disableToggle.waitForExistence(timeout: 3))
        disableToggle.tap()

        // Wait for SwiftUI to propagate the disabled state via @Observable re-render.
        // XCTNSPredicateExpectation polls the accessibility snapshot, which can be one
        // run-loop cycle behind the SwiftUI state update. We use waitForExistence on a
        // non-interactive query instead, which forces a fresh snapshot before asserting.
        let disabledPredicate = NSPredicate(format: "enabled == false")
        let disabledExpectation = XCTNSPredicateExpectation(predicate: disabledPredicate, object: target)
        let result = XCTWaiter().wait(for: [disabledExpectation], timeout: 5)
        XCTAssertEqual(result, .completed, "Timed out waiting for disableTarget to become disabled")

        // Re-query the element to get a fresh accessibility snapshot before asserting.
        let freshTarget = field("disableTarget")
        XCTAssertFalse(freshTarget.isEnabled)
    }

    // MARK: - 5. Error position — belowRow

    func testBelowRowErrorAppearsAfterSave() throws {
        openForm(titled: "Error Positions")
        openSubForm(id: "belowRowExample")

        // Tap Save without filling in the required field.
        let save = saveButton()
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        save.tap()

        // Inline error should appear below the row after async save + re-render.
        XCTAssertTrue(errorView("field1").waitForExistence(timeout: 5))
    }

    // MARK: - 6. Error position — formTop

    func testFormTopErrorAppearsAfterSave() throws {
        openForm(titled: "Error Positions")
        openSubForm(id: "formTopExample")

        let save = saveButton()
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        save.tap()

        XCTAssertTrue(formTopErrorView().waitForExistence(timeout: 5))
    }

    // MARK: - 7. Error position — alert

    func testAlertErrorAppearsAfterSave() throws {
        openForm(titled: "Error Positions")
        openSubForm(id: "alertExample")

        let save = saveButton()
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        save.tap()

        // An alert should be presented after async save + re-render.
        XCTAssertTrue(app.alerts["Validation Error"].waitForExistence(timeout: 5))
    }

    // MARK: - 8. Save button placement

    func testNavBarSaveButtonExists() throws {
        openForm(titled: "Save Behaviour")
        openSubForm(id: "navBarButton")

        // Save button should be in the navigation bar area.
        let save = saveButton()
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars.buttons["Save"].exists)
    }

    func testStickyBottomSaveButtonExists() throws {
        openForm(titled: "Save Behaviour")
        openSubForm(id: "stickyBottomButton")

        let save = saveButton()
        XCTAssertTrue(save.waitForExistence(timeout: 5))
    }

    // MARK: - 9. Collapsible Sections

    /// Returns the collapsible section header button for the given section ID.
    private func collapsibleHeader(_ sectionId: String) -> XCUIElement {
        app.buttons["formkit.collapsible.\(sectionId)"]
    }

    func testCollapsibleSectionExpandsAndCollapses() throws {
        openForm(titled: "Collapsible Sections")

        // "expandedByDefault" section starts expanded — child field should be visible.
        let childField = field("field1")
        XCTAssertTrue(childField.waitForExistence(timeout: 5))

        // Tap the header to collapse it.
        let header = collapsibleHeader("expandedByDefault")
        XCTAssertTrue(header.waitForExistence(timeout: 3))
        header.tap()

        // Child field should disappear after collapse.
        XCTAssertFalse(field("field1").waitForExistence(timeout: 3))

        // Tap the header again to expand.
        header.tap()

        // Child field should reappear.
        XCTAssertTrue(field("field1").waitForExistence(timeout: 5))
    }

    func testCollapsibleSectionStartsCollapsed() throws {
        openForm(titled: "Collapsible Sections")

        // "collapsedByDefault" section starts collapsed — child field should NOT be visible.
        let childField = field("field2")
        XCTAssertFalse(childField.waitForExistence(timeout: 3))

        // Tap the header to expand.
        let header = collapsibleHeader("collapsedByDefault")
        XCTAssertTrue(header.waitForExistence(timeout: 5))
        header.tap()

        // Child field should now appear.
        XCTAssertTrue(field("field2").waitForExistence(timeout: 5))
    }

    func testCollapsibleSectionAccessibilityValue() throws {
        openForm(titled: "Collapsible Sections")

        let header = collapsibleHeader("expandedByDefault")
        XCTAssertTrue(header.waitForExistence(timeout: 5))
        XCTAssertEqual(header.value as? String, "expanded")

        header.tap()
        // Allow animation to complete.
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertEqual(header.value as? String, "collapsed")
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
