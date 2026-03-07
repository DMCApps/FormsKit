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
        let isSaving = viewModel.status == .saving
        VStack(spacing: 0) {
            if viewModel.status == .needsLoad || viewModel.status == .loading {
                loadingView
            } else if case let .loadFailed(error) = viewModel.status {
                loadFailedView(error: error)
            } else {
                Form {
                    // Form-top errors: displayed above all rows.
                    if !viewModel.formTopErrors.isEmpty {
                        Section {
                            ValidationErrorView(errors: viewModel.formTopErrors)
                        }
                    }

                    ForEach(formDefinition.rows) { row in
                        if viewModel.isRowVisible(row) {
                            FormRowContainer(row: row, viewModel: viewModel)
                                .animation(.default, value: viewModel.isRowVisible(row))
                        }
                    }

                    // Form-bottom errors: displayed below all rows, above the save button.
                    if !viewModel.formBottomErrors.isEmpty {
                        Section {
                            ValidationErrorView(errors: viewModel.formBottomErrors)
                        }
                    }

                    if case let .buttonBottomForm(title) = formDefinition.saveBehaviour {
                        Section {
                            SaveButtonView(
                                title: title,
                                isLoading: isSaving,
                                isDisabled: isSaving
                            ) {
                                Task { await viewModel.save() }
                            }
                        }
                    }
                }

                if case let .buttonStickyBottom(title) = formDefinition.saveBehaviour {
                    StickyBottomSaveButtonView(
                        title: title,
                        isLoading: isSaving,
                        isDisabled: isSaving
                    ) {
                        Task { await viewModel.save() }
                    }
                }
            }
        }
        .navigationTitle(formDefinition.title)
        // Automatically load from persistence whenever status transitions to .needsLoad.
        // This covers: initial appearance, post-reset(), and re-navigation to the view.
        .task(id: viewModel.status == .needsLoad) {
            guard viewModel.status == .needsLoad else { return }
            await viewModel.loadFromPersistence()
        }
        .toolbar {
            if case let .buttonNavigationBar(title) = formDefinition.saveBehaviour {
                ToolbarItem(placement: .confirmationAction) {
                    Button(title) {
                        Task { await viewModel.save() }
                    }
                    .disabled(isSaving)
                }
            }
        }
        // Surface save errors as an alert.
        .alert("Save Failed", isPresented: Binding(
            get: { viewModel.saveError != nil },
            set: { if !$0 { viewModel.clearSaveError() } }
        )) {
            Button("OK") { viewModel.clearSaveError() }
        } message: {
            if let error = viewModel.saveError {
                Text(error.localizedDescription)
            }
        }
        // Surface .alert-positioned validator errors as a dismissible alert.
        .alert("Validation Error", isPresented: Binding(
            get: { !viewModel.alertErrors.isEmpty },
            set: { if !$0 { viewModel.clearAlertErrors() } }
        )) {
            Button("OK") { viewModel.clearAlertErrors() }
        } message: {
            Text(viewModel.alertErrors.joined(separator: "\n"))
        }
    }

    // MARK: - Loading View

    @ViewBuilder
    private var loadingView: some View {
        switch formDefinition.loadingStyle {
        case .activityIndicator:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .skeleton:
            FormSkeletonView(formDefinition: formDefinition)
        case let .custom(builder):
            builder()
        }
    }

    // MARK: - Load Failed View

    @ViewBuilder
    private func loadFailedView(error: Error) -> some View {
        VStack(spacing: 16) {
            Text("Failed to Load")
                .font(.headline)
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await viewModel.loadFromPersistence() }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            if let section = row.asType(FormSection.self) {
                FormSectionView(section: section, viewModel: viewModel)
            } else if let infoRow = row.asType(InfoRow.self) {
                InfoRowView(row: infoRow)
            } else if let buttonRow = row.asType(ButtonRow.self) {
                ButtonRowView(row: buttonRow)
            } else if let boolRow = row.asType(BooleanSwitchRow.self) {
                BooleanSwitchRowView(row: boolRow, viewModel: viewModel)
            } else if let textRow = row.asType(TextInputRow.self) {
                TextInputRowView(row: textRow, viewModel: viewModel)
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
        .disabled(viewModel.isRowDisabled(row))
    }
}
