@testable import FormsKit
import Testing

// MARK: - Duplicate Row ID Detection

/// Regression coverage for the `isRowVisible` infinite-recursion bug: a `FormSection`
/// (or `CollapsibleSection`) whose own ID matches one of its child rows' IDs makes
/// `parentSection(of:in:)` resolve the section as its own parent, so `isRowVisible`
/// recurses on itself forever. `FormViewModel.duplicateRowIDs(in:)` is the pure check
/// that catches this before the view model is even constructed — `FormViewModel.init`
/// wires it to a `fatalError`, which is trivial glue not covered here.
@Suite("FormViewModel Duplicate Row ID Detection")
struct FormViewModelDuplicateRowIDTests {
    @Test("Section ID reused by one of its own child rows is detected")
    func sectionIDReusedByChildRow() {
        // Mirrors the real-world bug shape: FormSection(id: "sec1") containing a child
        // row that was accidentally given the same literal ID as the section itself.
        let rows: [AnyFormRow] = [
            AnyFormRow(FormSection(id: "sec1", title: "Section") {
                TextInputRow(id: "sec1", title: "Oops")
            })
        ]
        let flatRows = FormViewModel.allRows(in: rows)
        #expect(FormViewModel.duplicateRowIDs(in: flatRows) == ["sec1"])
    }

    @Test("Top-level row ID reused by a row nested inside a section is detected")
    func topLevelRowIDReusedByNestedRow() {
        let rows: [AnyFormRow] = [
            AnyFormRow(TextInputRow(id: "dup", title: "Top")),
            AnyFormRow(FormSection(id: "sec", title: "Section") {
                TextInputRow(id: "dup", title: "Child")
            })
        ]
        let flatRows = FormViewModel.allRows(in: rows)
        #expect(FormViewModel.duplicateRowIDs(in: flatRows) == ["dup"])
    }

    @Test("CollapsibleSection ID reused by one of its own child rows is detected")
    func collapsibleSectionIDReusedByChildRow() {
        let rows: [AnyFormRow] = [
            AnyFormRow(CollapsibleSection(id: "sec1", title: "Section") {
                TextInputRow(id: "sec1", title: "Oops")
            })
        ]
        let flatRows = FormViewModel.allRows(in: rows)
        #expect(FormViewModel.duplicateRowIDs(in: flatRows) == ["sec1"])
    }

    @Test("Multiple distinct duplicate IDs are all reported, sorted")
    func multipleDuplicateIDsAllReported() {
        let rows: [AnyFormRow] = [
            AnyFormRow(TextInputRow(id: "b", title: "B1")),
            AnyFormRow(TextInputRow(id: "b", title: "B2")),
            AnyFormRow(TextInputRow(id: "a", title: "A1")),
            AnyFormRow(TextInputRow(id: "a", title: "A2"))
        ]
        let flatRows = FormViewModel.allRows(in: rows)
        #expect(FormViewModel.duplicateRowIDs(in: flatRows) == ["a", "b"])
    }

    @Test("Legit nested sections with all-unique IDs report no duplicates")
    func legitNestedSectionsReportNoDuplicates() {
        let rows: [AnyFormRow] = [
            AnyFormRow(TextInputRow(id: "top", title: "Top")),
            AnyFormRow(FormSection(id: "sec1", title: "Section 1") {
                TextInputRow(id: "sec1_child1", title: "Child 1")
                TextInputRow(id: "sec1_child2", title: "Child 2")
            }),
            AnyFormRow(CollapsibleSection(id: "sec2", title: "Section 2") {
                TextInputRow(id: "sec2_child1", title: "Child 1")
            })
        ]
        let flatRows = FormViewModel.allRows(in: rows)
        #expect(FormViewModel.duplicateRowIDs(in: flatRows).isEmpty)
    }
}
