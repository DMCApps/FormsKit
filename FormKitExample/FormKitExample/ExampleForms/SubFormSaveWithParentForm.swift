import FormsKit

// MARK: - SubFormSaveWithParentForm

/// Demonstrates `FormSaveBehaviour.withParent`: two sub-forms whose save UI and persistence
/// are deferred to this root form. Editing a sub-form and tapping the system back button
/// keeps the edit alive — only tapping Save on the root form persists it, for both
/// sub-forms and the root itself, in one pass.
enum SubFormSaveWithParentForm {
    // MARK: Sub-form 1 row IDs

    /// Typed row IDs for "Profile" — demonstrates the RawRepresentable row/child accessor.
    enum ProfileRowID: String {
        case displayName
        case bio
    }

    // MARK: Sub-forms

    /// First sub-form. Uses enum row IDs throughout.
    static let profileForm = FormDefinition(
        id: "subFormSaveWithParent.profile",
        title: "Profile",
        persistence: FormPersistenceMemory(),
        saveBehaviour: .withParent
    ) {
        TextInputRow(id: ProfileRowID.displayName, title: "Display Name", placeholder: "Jane Doe")
        TextInputRow(id: ProfileRowID.bio, title: "Bio", placeholder: "A short bio")
    }

    /// Second sub-form, nested one level deeper via its own NavigationRow, to show the
    /// save cascade isn't limited to a single level.
    static let notificationsDetailForm = FormDefinition(
        id: "subFormSaveWithParent.notifications.detail",
        title: "Notification Sounds",
        persistence: FormPersistenceMemory(),
        saveBehaviour: .withParent
    ) {
        BooleanSwitchRow(id: "soundEnabled", title: "Play Sound", defaultValue: true)
    }

    static let notificationsForm = FormDefinition(
        id: "subFormSaveWithParent.notifications",
        title: "Notifications",
        persistence: FormPersistenceMemory(),
        saveBehaviour: .withParent
    ) {
        BooleanSwitchRow(id: "marketingEmails", title: "Marketing Emails", defaultValue: false)

        NavigationRow(
            id: "sounds",
            title: "Notification Sounds",
            destination: notificationsDetailForm
        )
    }

    // MARK: Root form

    static let definition = FormDefinition(
        id: "subFormSaveWithParent.root",
        title: "Account",
        persistence: FormPersistenceMemory(),
        saveBehaviour: .buttonNavigationBar(),
        onSave: [
            FormSaveAction { _ in
                // A real app might do something irreversible here (e.g. relaunch),
                // safe in the knowledge every sub-form above has already persisted.
                print("SubFormSaveWithParentForm: root saved, including both sub-forms")
            }
        ]
    ) {
        TextInputRow(id: "username", title: "Username", placeholder: "jdoe")

        NavigationRow(
            id: "profile",
            title: "Profile",
            subtitle: "Display name and bio — saves with Account",
            destination: profileForm
        )

        NavigationRow(
            id: "notifications",
            title: "Notifications",
            subtitle: "Email and sound preferences — saves with Account",
            destination: notificationsForm
        )
    }
}
