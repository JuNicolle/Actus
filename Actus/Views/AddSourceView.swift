import SwiftUI

struct AddSourceView: View {
    @Environment(NewsStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var urlString = ""
    @State private var category: NewsCategory = .france
    @State private var isFrench = true
    @State private var isChecking = false
    @State private var errorMessage: String?

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !urlString.trimmingCharacters(in: .whitespaces).isEmpty
            && !isChecking
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nom (ex. Mediapart)", text: $name)
                    TextField("Adresse du flux RSS", text: $urlString)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } footer: {
                    Text("Cherche « RSS » en bas du site, ou essaie /rss, /feed ou /rss.xml après l'adresse du site.")
                }

                Section {
                    Picker("Rubrique", selection: $category) {
                        ForEach(NewsCategory.allCases) { category in
                            Label(category.title, systemImage: category.systemImage).tag(category)
                        }
                    }
                    Toggle("Articles en français", isOn: $isFrench)
                }

                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Nouvelle source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isChecking {
                        ProgressView()
                    } else {
                        Button("Ajouter", action: add).disabled(!canSubmit)
                    }
                }
            }
        }
    }

    private func add() {
        isChecking = true
        errorMessage = nil
        Task {
            do {
                try await store.addCustomSource(name: name, urlString: urlString, category: category, isFrench: isFrench)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isChecking = false
            }
        }
    }
}
