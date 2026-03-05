import Foundation

// MARK: - FormDefinition

/// Describes a complete form: its identity, title, rows, and optional persistence.
/// Create one using the `init(id:title:rows:)` initialiser or the `@FormRowBuilder` DSL.
public struct FormDefinition: Sendable, Identifiable {
    /// Unique identifier for this form. Used as the persistence key.
    public let id: String

    /// Display title shown in the navigation bar.
    public let title: String

    /// Ordered array of type-erased rows.
    public let rows: [AnyFormRow]

    /// Optional persistence backend. When nil, values live in-memory for the session.
    public let persistence: (any FormPersistence)?

    /// Whether to render a Save button at the bottom of the form.
    public let showsSaveButton: Bool

    /// Label for the Save button. Defaults to "Save".
    public let saveButtonTitle: String

    // MARK: Initialiser — Array of AnyFormRow

    public init(id: String,
                title: String,
                rows: [AnyFormRow],
                persistence: (any FormPersistence)? = nil,
                showsSaveButton: Bool = true,
                saveButtonTitle: String = "Save") {
        self.id = id
        self.title = title
        self.rows = rows
        self.persistence = persistence
        self.showsSaveButton = showsSaveButton
        self.saveButtonTitle = saveButtonTitle
    }

    // MARK: Initialiser — Result Builder DSL

    /// Construct a form using a `@FormRowBuilder` closure for an ergonomic DSL.
    ///
    /// ```swift
    /// let form = FormDefinition(id: "settings", title: "Settings") {
    ///     BooleanSwitchRow(id: "notifications", title: "Enable Notifications")
    ///     TextInputRow(id: "name", title: "Display Name")
    /// }
    /// ```
    public init(id: String,
                title: String,
                persistence: (any FormPersistence)? = nil,
                showsSaveButton: Bool = true,
                saveButtonTitle: String = "Save",
                @FormRowBuilder rows: () -> [AnyFormRow]) {
        self.id = id
        self.title = title
        self.rows = rows()
        self.persistence = persistence
        self.showsSaveButton = showsSaveButton
        self.saveButtonTitle = saveButtonTitle
    }
}

// MARK: - FormRowBuilder

/// A result builder that converts concrete FormRow expressions into [AnyFormRow].
/// Supports `if`, `if/else`, `for` loops, and optional rows.
@resultBuilder
public struct FormRowBuilder {
    // Single expression — wraps any FormRow in AnyFormRow.
    public static func buildExpression(_ expression: some FormRow) -> [AnyFormRow] {
        [AnyFormRow(expression)]
    }

    // Multiple blocks concatenated.
    public static func buildBlock(_ components: [AnyFormRow]...) -> [AnyFormRow] {
        components.flatMap { $0 }
    }

    // `if` without `else`.
    public static func buildOptional(_ component: [AnyFormRow]?) -> [AnyFormRow] {
        component ?? []
    }

    // `if/else` — first branch.
    public static func buildEither(first component: [AnyFormRow]) -> [AnyFormRow] {
        component
    }

    // `if/else` — second branch.
    public static func buildEither(second component: [AnyFormRow]) -> [AnyFormRow] {
        component
    }

    // `for` loop.
    public static func buildArray(_ components: [[AnyFormRow]]) -> [AnyFormRow] {
        components.flatMap { $0 }
    }

    // Allows passing an already-wrapped AnyFormRow directly.
    public static func buildExpression(_ expression: AnyFormRow) -> [AnyFormRow] {
        [expression]
    }
}
