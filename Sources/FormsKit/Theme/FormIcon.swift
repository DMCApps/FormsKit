import SwiftUI

// MARK: - FormIcon

/// Represents an icon source that FormsKit views can render.
///
/// Use this type wherever FormsKit accepts an icon — in `FormTheme.Icons` tokens and
/// per-row style overrides — instead of bare SF Symbol name strings.
///
/// ```swift
/// // SF Symbol (most common)
/// FormIcon.system("checkmark.circle.fill")
///
/// // Asset catalog image in the app's main bundle
/// FormIcon.named("MyAppCheckmark")
///
/// // Asset catalog image in a specific bundle (e.g. a Swift package)
/// FormIcon.named("MyIcon", bundle: .module)
///
/// // Fully custom SwiftUI Image
/// FormIcon.custom(Image("brand-logo"))
/// ```
public enum FormIcon: Sendable, Equatable {

    /// An SF Symbol, identified by name (e.g. `"checkmark"`, `"chevron.right"`).
    case system(String)

    /// An image from an asset catalog, identified by name.
    ///
    /// - Parameters:
    ///   - name: The asset catalog image name.
    ///   - bundle: The bundle to search. Pass `nil` (the default) to use the app's
    ///     main bundle, or pass `Bundle.module` to load from a Swift package's own bundle.
    case named(String, bundle: Bundle? = nil)

    /// An arbitrary SwiftUI `Image` value.
    case custom(Image)

    // MARK: Equatable

    public static func == (lhs: FormIcon, rhs: FormIcon) -> Bool {
        switch (lhs, rhs) {
        case (.system(let a), .system(let b)):
            return a == b
        case (.named(let a, let ba), .named(let b, let bb)):
            return a == b && ba == bb
        // Image has no Equatable conformance; treat two .custom values as always unequal.
        case (.custom, .custom):
            return false
        default:
            return false
        }
    }
}

// MARK: - View helpers

extension FormIcon {
    /// Returns a SwiftUI `Image` for this icon source.
    func image() -> Image {
        switch self {
        case .system(let name):
            return Image(systemName: name)
        case .named(let name, let bundle):
            return Image(name, bundle: bundle)
        case .custom(let image):
            return image
        }
    }
}
