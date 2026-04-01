import SwiftUI

// MARK: - Environment Key

private struct FormThemeKey: EnvironmentKey {
    static let defaultValue: FormTheme = .default
}

extension EnvironmentValues {
    /// The current FormsKit theme. Defaults to `FormTheme.default`.
    public var formTheme: FormTheme {
        get { self[FormThemeKey.self] }
        set { self[FormThemeKey.self] = newValue }
    }
}

// MARK: - View Modifier

extension View {
    /// Applies a FormsKit theme to this view and all its descendants.
    ///
    /// ```swift
    /// DynamicFormView(formDefinition: myForm)
    ///     .formTheme(FormTheme(colors: .init(error: .orange)))
    /// ```
    public func formTheme(_ theme: FormTheme) -> some View {
        environment(\.formTheme, theme)
    }
}
