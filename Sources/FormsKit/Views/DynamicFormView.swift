import SwiftUI

// MARK: - DynamicFormView

/// The main entry point for rendering a `FormDefinition` as a SwiftUI Form.
///
/// When you need to read values back or observe form state externally, pass a
/// `FormViewModel` directly:
///
/// ```swift
/// @State private var viewModel = FormViewModel(formDefinition: myForm)
///
/// NavigationStack {
///     DynamicFormView(viewModel: viewModel)
/// }
/// ```
///
/// When rendering a standalone form with no external state requirements, pass
/// just the definition:
///
/// ```swift
/// DynamicFormView(formDefinition: myForm)
/// ```
public struct DynamicFormView: View {
    private let formDefinition: FormDefinition
    @State private var viewModel: FormViewModel
    @Environment(\.formTheme) private var environmentTheme

    // MARK: - Init

    /// Creates a view from an externally-owned view model.
    /// Use this when you need to observe form state or read values from outside the view.
    ///
    /// - Parameter viewModel: The view model to use. The form definition is derived from it.
    public init(viewModel: FormViewModel) {
        self.formDefinition = viewModel.formDefinition
        _viewModel = State(initialValue: viewModel)
    }

    /// Creates a view from a form definition, managing the view model internally.
    /// Use this when you don't need to observe or read form state from outside the view.
    ///
    /// - Parameter formDefinition: Describes the form to display.
    public init(formDefinition: FormDefinition) {
        self.formDefinition = formDefinition
        _viewModel = State(initialValue: FormViewModel(formDefinition: formDefinition))
    }

    /// The resolved theme: an explicit theme on the definition takes precedence over the
    /// ambient environment theme (set via `.formTheme(_:)`), which in turn falls back to
    /// `FormTheme.default` via the `EnvironmentKey` default.
    private var theme: FormTheme {
        formDefinition._theme ?? environmentTheme
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
                            ValidationErrorView(errors: viewModel.formTopErrors, rowId: "formTop")
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
                            ValidationErrorView(errors: viewModel.formBottomErrors, rowId: "formBottom")
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
                            .accessibilityIdentifier("formkit.saveButton")
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
                    .accessibilityIdentifier("formkit.saveButton")
                }
            }
        }
        .environment(\.formTheme, theme)
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
                    .accessibilityIdentifier("formkit.saveButton")
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
                .font(theme.fonts.loadFailedTitle)
            Text(error.localizedDescription)
                .font(theme.fonts.loadFailedSubtitle)
                .foregroundStyle(theme.colors.subtitle)
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
struct FormRowContainer: View {
    let row: AnyFormRow
    @Bindable var viewModel: FormViewModel
    @Environment(\.formTheme) private var theme

    var body: some View {
        Group {
            if let section = row.asType(FormSection.self) {
                FormSectionView(section: section, viewModel: viewModel)
            } else if let collapsible = row.asType(CollapsibleSection.self) {
                CollapsibleSectionView(section: collapsible, viewModel: viewModel)
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
                    .foregroundStyle(theme.colors.subtitle)
            }
        }
        .disabled(viewModel.isRowDisabled(row))
    }
}
