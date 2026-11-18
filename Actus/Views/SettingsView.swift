import SwiftUI

struct SettingsView: View {
    @Environment(NewsStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var newKeyword = ""
    @State private var confirmingReset = false
    @State private var showingAddSource = false

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            Form {
                Section {
                    Toggle("Français uniquement", isOn: $store.frenchOnly)
                } footer: {
                    Text("Masque les sources anglophones (BBC, Al Jazeera).")
                }

                Section {
                    ForEach(store.customSources) { source in
                        Toggle(isOn: $store[isEnabled: source]) {
                            VStack(alignment: .leading) {
                                Text(source.name)
                                Text(source.category.title).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: store.removeCustomSources)
                    Button("Ajouter une source…", systemImage: "plus.circle") { showingAddSource = true }
                } header: {
                    Text("Mes sources")
                } footer: {
                    Text("Ajoute n'importe quel site ou blog qui propose un flux RSS. Glisse vers la gauche pour supprimer.")
                }

                ForEach(NewsCategory.allCases) { category in
                    Section(category.title) {
                        ForEach(FeedSource.all.filter { $0.category == category }) { source in
                            Toggle(source.name, isOn: $store[isEnabled: source])
                        }
                    }
                }

                Section {
                    ForEach(store.mutedKeywords, id: \.self) { keyword in
                        Text(keyword)
                    }
                    .onDelete(perform: store.removeKeywords)
                    TextField("Ajouter un mot à masquer", text: $newKeyword)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onSubmit {
                            store.addKeyword(newKeyword)
                            newKeyword = ""
                        }
                } header: {
                    Text("Mots masqués")
                } footer: {
                    Text("Les articles dont le titre contient l'un de ces mots sont cachés.")
                }

                Section {
                    Button("Réinitialiser l'historique de lecture", role: .destructive) {
                        confirmingReset = true
                    }
                    .confirmationDialog(
                        "Marquer tous les articles comme non lus ?",
                        isPresented: $confirmingReset,
                        titleVisibility: .visible
                    ) {
                        Button("Réinitialiser", role: .destructive, action: store.resetReadState)
                    }
                } footer: {
                    if let lastUpdated = store.lastUpdated {
                        Text("Dernière mise à jour : \(lastUpdated.formatted(date: .abbreviated, time: .shortened))")
                    }
                }
            }
            .sheet(isPresented: $showingAddSource) { AddSourceView() }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK", action: dismiss.callAsFunction)
                }
            }
        }
    }
}
