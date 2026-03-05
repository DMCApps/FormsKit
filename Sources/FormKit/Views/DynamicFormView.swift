import SwiftUI

// MARK: - DynamicFormView

/// The main entry point for rendering a `FormDefinition` as a SwiftUI Form.
///
/// Provide a `FormDefinition` and optionally a pre-existing `FormViewModel`
/// (useful when you need to read the values back after the user saves).
///
/// ```swift
/// @State private var viewModel = FormViewModel(formDefinition: myForm)
///
/// NavigationStack {
///     DynamicFormView(formDefinition: myForm, viewModel: viewModel)
/// }
/// ```
@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
public struct DynamicFormView: View {
    private let formDefinition: FormDefinition
    @State private var viewModel: FormViewModel

    // MARK: - Init

    /// - Parameters:
    ///   - formDefinition: Describes the form to display.
    ///   - viewModel: An externally-created view model.
    ///     Pass one in if you need to read values after the form closes.
    ///     If nil, a new view model is created internally.
    public init(formDefinition: FormDefinition,
                viewModel: FormViewModel? = nil) {
        self.formDefinition = formDefinition
        _viewModel = State(
            initialValue: viewModel ?? FormViewModel(formDefinition: formDefinition)
        )
    }

    // MARK: - Body

    public var body: some View {
        Form {
            ForEach(formDefinition.rows) { row in
                if viewModel.isRowVisible(row) {
                    FormRowContainer(row: row, viewModel: viewModel)
                        .animation(.default, value: viewModel.isRowVisible(row))
                }
            }

            if case let .buttonBottomForm(title) = formDefinition.saveBehaviour {
                Section {
                    SaveButtonView(
                        title: title,
                        isLoading: viewModel.isSaving,
                        isDisabled: viewModel.isSaving
                    ) {
                        Task { await viewModel.save() }
                    }
                }
            }
        }
        .navigationTitle(formDefinition.title)
        .toolbar {
            if case let .buttonNavigationBar(title) = formDefinition.saveBehaviour {
                ToolbarItem(placement: .confirmationAction) {
                    Button(title) {
                        Task { await viewModel.save() }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
        }
        .task {
            await viewModel.loadFromPersistence()
        }
        // Surface save errors as an alert.
        .alert("Save Failed", isPresented: .constant(viewModel.saveError != nil)) {
            Button("OK") { }
        } message: {
            if let error = viewModel.saveError {
                Text(error.localizedDescription)
            }
        }
    }
}

// MARK: - FormRowContainer

/// Internal view that dispatches to the correct row view based on the underlying row type.
/// Non-generic row types are matched directly via `asType(_:)`.
/// Generic row types (`SingleValueRow<T>`, `MultiValueRow<T>`) are matched via their
/// marker protocols (`SingleValueRowRepresentable`, `MultiValueRowRepresentable`).
@available(iOS 17, tvOS 17, macOS 14, visionOS 1, *)
struct FormRowContainer: View {
    let row: AnyFormRow
    @Bindable var viewModel: FormViewModel

    var body: some View {
        Group {
            if let buttonRow = row.asType(ButtonRow.self) {
                ButtonRowView(row: buttonRow)
            } else if let boolRow = row.asType(BooleanSwitchRow.self) {
                BooleanSwitchRowView(row: boolRow, viewModel: viewModel)
            } else if let textRow = row.asType(TextInputRow.self) {
                TextInputRowView(row: textRow, viewModel: viewModel)
            } else if let emailRow = row.asType(EmailInputRow.self) {
                EmailInputRowView(row: emailRow, viewModel: viewModel)
            } else if let numberRow = row.asType(NumberInputRow.self) {
                NumberInputRowView(row: numberRow, viewModel: viewModel)
            } else if let navRow = row.asType(NavigationRow.self) {
                NavigationRowView(row: navRow, viewModel: viewModel)
            } else if let singleRow = row.asSingleValueRepresentable {
                // Handles SingleValueRow<T> for any T without needing to know T.
                SingleValueRowView(row: singleRow, rowId: row.id, viewModel: viewModel)
            } else if let multiRow = row.asMultiValueRepresentable {
                // Handles MultiValueRow<T> for any T without needing to know T.
                MultiValueRowView(row: multiRow, rowId: row.id, viewModel: viewModel)
            } else {
                // Fallback for any future custom row types that haven't added
                // a view dispatch case. Shows the row title as plain text.
                Text(row.title)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
