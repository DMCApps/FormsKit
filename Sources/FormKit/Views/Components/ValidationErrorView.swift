import SwiftUI

// MARK: - ValidationErrorView

/// Displays inline validation error messages below a form row.
/// Renders nothing if `errors` is empty.
struct ValidationErrorView: View {
    let errors: [String]

    var body: some View {
        if !errors.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(errors, id: \.self) { error in
                    Label {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    } icon: {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
        }
    }
}
