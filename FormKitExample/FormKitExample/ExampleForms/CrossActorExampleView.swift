import FormsKit
import os
import SwiftUI

// MARK: - FormViewModel + valueStream

extension FormViewModel {
    /// Emits a value-type copy of `values` on the main actor each time any value changes.
    ///
    /// Because `FormValueStore` is a value type, each emitted snapshot is independent
    /// and safe to hand off to non-`@MainActor` code.
    @MainActor
    var valueStream: AsyncStream<FormValueStore> {
        AsyncStream { continuation in
            func observe() {
                withObservationTracking {
                    continuation.yield(values)
                } onChange: {
                    Task { @MainActor in observe() }
                }
            }
            observe()
        }
    }
}

// MARK: - DebugSettings

/// Thread-safe container that mirrors the latest `FormValueStore` snapshot.
///
/// Updated on the main actor via `valueStream`; read synchronously from any
/// thread via `OSAllocatedUnfairLock` — no `async`/`await` required at call sites.
final class DebugSettings: @unchecked Sendable {
    static let shared = DebugSettings()
    private let lock = OSAllocatedUnfairLock(initialState: FormValueStore())

    func value<T: Decodable>(for key: String) -> T? {
        lock.withLock { $0.value(for: key) }
    }

    fileprivate func update(from store: FormValueStore) {
        lock.withLock { $0 = store }
    }
}

// MARK: - Support types

private enum CrossActorLogLevel: String, CaseIterable, CustomStringConvertible, Hashable, Sendable, Codable {
    case verbose, debug, info, warning, error
    var description: String { rawValue.capitalized }
}

// MARK: - Form definition

enum CrossActorForm {
    enum Row: String {
        case apiBaseURL  = "crossActor.apiBaseURL"
        case logLevel    = "crossActor.logLevel"
        case slowNetwork = "crossActor.slowNetwork"
        case cacheBypass = "crossActor.cacheBypass"
    }

    static let definition = FormDefinition(
        id: "crossActorExample",
        title: "Debug Settings",
        saveBehaviour: .onChange
    ) {
        FormSection(id: "crossActorNetwork", title: "Network") {
            TextInputRow(
                id: Row.apiBaseURL.rawValue,
                title: "API Base URL",
                subtitle: "Overrides the default endpoint",
                defaultValue: "https://api.example.com",
                keyboardType: .url,
                placeholder: "https://api.example.com"
            )
            BooleanSwitchRow(
                id: Row.slowNetwork.rawValue,
                title: "Simulate Slow Network",
                subtitle: "Adds artificial latency to all requests",
                defaultValue: false
            )
            BooleanSwitchRow(
                id: Row.cacheBypass.rawValue,
                title: "Bypass Cache",
                subtitle: "Skips the response cache on every request",
                defaultValue: false
            )
        }
        FormSection(id: "crossActorLogging", title: "Logging") {
            SingleValueRow<CrossActorLogLevel>(
                id: Row.logLevel.rawValue,
                title: "Log Level",
                subtitle: "Minimum severity sent to the console",
                defaultValue: .info
            )
        }
    }
}

// MARK: - CrossActorExampleView

/// Demonstrates three patterns for reading `FormViewModel.values` outside the main actor.
///
/// **Pattern 1 — Continuous stream + lock**
/// `valueStream` emits a value-type snapshot on every change. A `Task { @MainActor in }`
/// iterates it and pushes each copy into `DebugSettings.shared` via `OSAllocatedUnfairLock`.
/// Any thread then reads synchronously with no `await`. Best for long-lived background
/// consumers (networking layers, analytics, feature-flag services).
///
/// **Pattern 2 — One-shot snapshot**
/// Capture `viewModel.values` directly in a `@MainActor` context (e.g. a button tap)
/// and hand the value-type copy to a `Task.detached`. No stream, no lock needed.
/// Best for fire-and-forget operations triggered by a user action.
///
/// **Pattern 3 — `MainActor.assumeIsolated`**
/// Works in synchronous non-`async` callbacks that are guaranteed to run on the main
/// thread (e.g. UIKit delegates). Reads directly from the view model without a copy.
/// Tradeoff: it is a runtime assertion, not a compile-time guarantee — it crashes if
/// ever called off the main thread.
struct CrossActorExampleView: View {
    @State private var viewModel = FormViewModel(formDefinition: CrossActorForm.definition)
    @State private var readLog: [ReadEntry] = []

    var body: some View {
        List {
            Section {
                NavigationLink("Edit Debug Settings") {
                    DynamicFormView(viewModel: viewModel)
                }
            } header: {
                Text("Form (main actor)")
            } footer: {
                Text("saveBehaviour: .onChange — every edit auto-saves and streams into DebugSettings.shared.")
            }

            // Pattern 1 -------------------------------------------------------
            Section {
                Text(
                    "valueStream bridges each FormValueStore snapshot into an " +
                    "OSAllocatedUnfairLock. Any thread reads synchronously — " +
                    "no await. Best for long-lived consumers (network layer, analytics)."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)

                Button("Simulate Background Read") {
                    simulateStreamRead()
                }
            } header: {
                Text("Pattern 1 — Continuous stream + lock")
            }

            // Pattern 2 -------------------------------------------------------
            Section {
                Text(
                    "Capture viewModel.values once in a @MainActor context (button tap) " +
                    "and pass the value-type copy to Task.detached. No stream or lock needed. " +
                    "Best for fire-and-forget actions triggered by the user."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)

                Button("Simulate Network Request") {
                    simulateSnapshot()
                }
            } header: {
                Text("Pattern 2 — One-shot snapshot")
            }

            // Pattern 3 -------------------------------------------------------
            Section {
                Text(
                    "MainActor.assumeIsolated reads directly from the view model in a " +
                    "synchronous callback known to run on the main thread (e.g. a UIKit " +
                    "delegate). Tradeoff: runtime assertion only — crashes if called off " +
                    "the main thread. Prefer patterns 1 or 2 in async contexts."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)

                Button("Simulate UIKit Callback Read") {
                    simulateAssumeIsolated()
                }
            } header: {
                Text("Pattern 3 — MainActor.assumeIsolated")
            }

            // Log -------------------------------------------------------------
            if !readLog.isEmpty {
                Section("Read log") {
                    ForEach(readLog) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(entry.pattern)
                                    .font(.caption2)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(entry.patternColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                Text(entry.timestamp)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Text(entry.message)
                                .font(.caption)
                                .fontDesign(.monospaced)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Cross-Actor Access")
        .task {
            // Pattern 1 wiring: main-actor stream → lock-protected container.
            for await snapshot in viewModel.valueStream {
                DebugSettings.shared.update(from: snapshot)
            }
        }
    }

    // MARK: - Pattern 1: Continuous stream + lock

    private func simulateStreamRead() {
        Task.detached {
            // No @MainActor. No await. Reads synchronously from the lock-protected store.
            let url: String?   = DebugSettings.shared.value(for: CrossActorForm.Row.apiBaseURL.rawValue)
            let slow: Bool?    = DebugSettings.shared.value(for: CrossActorForm.Row.slowNetwork.rawValue)
            let cache: Bool?   = DebugSettings.shared.value(for: CrossActorForm.Row.cacheBypass.rawValue)
            let level: String? = DebugSettings.shared.value(for: CrossActorForm.Row.logLevel.rawValue)

            let message =
                "url=\(url ?? "nil")  slow=\(slow ?? false)  " +
                "cacheBypass=\(cache ?? false)  level=\(level ?? "nil")"

            await MainActor.run { appendEntry(.init(pattern: "stream+lock", patternColor: .indigo, message: message)) }
        }
    }

    // MARK: - Pattern 2: One-shot snapshot

    private func simulateSnapshot() {
        // Already on @MainActor (SwiftUI button action). Capture is free — FormValueStore is a value type.
        let snapshot = viewModel.values

        Task.detached {
            // snapshot is a Sendable value type — safe to use from any thread.
            let url: String?   = snapshot.value(for: CrossActorForm.Row.apiBaseURL.rawValue)
            let slow: Bool?    = snapshot.value(for: CrossActorForm.Row.slowNetwork.rawValue)
            let cache: Bool?   = snapshot.value(for: CrossActorForm.Row.cacheBypass.rawValue)
            let level: String? = snapshot.value(for: CrossActorForm.Row.logLevel.rawValue)

            let message =
                "url=\(url ?? "nil")  slow=\(slow ?? false)  " +
                "cacheBypass=\(cache ?? false)  level=\(level ?? "nil")"

            await MainActor.run { appendEntry(.init(pattern: "snapshot", patternColor: .teal, message: message)) }
        }
    }

    // MARK: - Pattern 3: MainActor.assumeIsolated

    private func simulateAssumeIsolated() {
        // This closure is called from a @MainActor SwiftUI button action — assumeIsolated is safe here.
        // In a real app this would be inside a UIKit delegate (e.g. tableView(_:didSelectRowAt:))
        // that is guaranteed to run on the main thread but isn't annotated @MainActor.
        //
        // WARNING: If this function were ever called from a background thread or Task.detached,
        // assumeIsolated would crash at runtime. Prefer the snapshot or stream+lock patterns
        // in any context where thread-of-execution is uncertain.
        let url: String? = MainActor.assumeIsolated {
            viewModel.values.value(for: CrossActorForm.Row.apiBaseURL.rawValue)
        }
        let slow: Bool? = MainActor.assumeIsolated {
            viewModel.values.value(for: CrossActorForm.Row.slowNetwork.rawValue)
        }
        let cache: Bool? = MainActor.assumeIsolated {
            viewModel.values.value(for: CrossActorForm.Row.cacheBypass.rawValue)
        }
        let level: String? = MainActor.assumeIsolated {
            viewModel.values.value(for: CrossActorForm.Row.logLevel.rawValue)
        }

        let message =
            "url=\(url ?? "nil")  slow=\(slow ?? false)  " +
            "cacheBypass=\(cache ?? false)  level=\(level ?? "nil")"

        appendEntry(.init(pattern: "assumeIsolated", patternColor: .orange, message: message))
    }

    // MARK: - Helpers

    private func appendEntry(_ entry: ReadEntry) {
        readLog.insert(entry, at: 0)
        if readLog.count > 12 { readLog = Array(readLog.prefix(12)) }
    }
}

// MARK: - ReadEntry

private struct ReadEntry: Identifiable {
    let id = UUID()
    let pattern: String
    let patternColor: Color
    let timestamp: String
    let message: String

    init(pattern: String, patternColor: Color, message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        self.pattern = pattern
        self.patternColor = patternColor
        self.timestamp = formatter.string(from: Date())
        self.message = message
    }
}

#Preview {
    NavigationStack {
        CrossActorExampleView()
    }
}
