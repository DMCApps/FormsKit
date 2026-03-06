import SwiftUI

// MARK: - FormLoadingStyle

/// Controls what is displayed while a form's values are loading from persistence.
///
/// Set via `FormDefinition(loadingStyle:)`. Defaults to `.activityIndicator`, which
/// preserves the existing behaviour.
///
/// ```swift
/// // Default: spinner
/// FormDefinition(id: "settings", title: "Settings") { ... }
///
/// // Skeleton: shimmer placeholders shaped like each row
/// FormDefinition(id: "settings", title: "Settings", loadingStyle: .skeleton) { ... }
///
/// // Custom: any view you like
/// FormDefinition(id: "settings", title: "Settings",
///     loadingStyle: .custom { AnyView(MyBrandedLoader()) }) { ... }
/// ```
public enum FormLoadingStyle: Sendable {
    /// A centered `ProgressView` spinner (the default).
    case activityIndicator

    /// Shimmer placeholders that mirror the shapes of the form's rows.
    case skeleton

    /// A caller-supplied view shown while loading.
    /// Use `AnyView` to wrap your view: `.custom { AnyView(MyView()) }`.
    case custom(@Sendable () -> AnyView)
}
