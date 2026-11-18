import SwiftUI

struct ContentView: View {
    @Environment(NewsStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var path: [Article] = []
    @State private var selectedCategory: NewsCategory?
    @State private var searchText = ""
    @State private var showingSettings = false
    @State private var showingDigest = false

    var body: some View {
        NavigationStack(path: $path) {
            ArticleListView(path: $path, category: selectedCategory, searchText: searchText)
                .navigationTitle(selectedCategory?.title ?? "À la une")
                .navigationBarTitleDisplayMode(.large)
                .navigationDestination(for: Article.self) { article in
                    ArticleDetailView(article: article)
                }
                .searchable(text: $searchText, prompt: "Rechercher")
                .safeAreaBar(edge: .top) {
                    CategoryPicker(selection: $selectedCategory)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Réglages", systemImage: "gearshape") { showingSettings = true }
                    }
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button("Tout marquer comme lu", systemImage: "checkmark.circle") {
                            store.markAllRead(in: selectedCategory)
                        }
                        Button("L'essentiel du jour", systemImage: "sparkles") { showingDigest = true }
                    }
                }
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .sheet(isPresented: $showingDigest) { DigestView() }
        .task(id: scenePhase) {
            if scenePhase == .active { await store.refreshIfNeeded() }
        }
    }
}
