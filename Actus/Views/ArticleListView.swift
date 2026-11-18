import SwiftUI

struct ArticleListView: View {
    @Environment(NewsStore.self) private var store
    @Binding var path: [Article]
    let category: NewsCategory?
    let searchText: String

    @State private var showingDofusNews = false

    private static let dofusNewsURL = URL(string: "https://www.dofus.com/fr/mmorpg/actualites")

    var body: some View {
        let items = store.articles(in: category, matching: searchText)
        List {
            if !store.failedSourceNames.isEmpty {
                Label("Indisponible : \(store.failedSourceNames.formatted())", systemImage: "wifi.exclamationmark")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            if category == .culture, searchText.isEmpty {
                DofusShortcutRow { showingDofusNews = true }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }
            ForEach(items) { article in
                Button {
                    path.append(article)
                } label: {
                    if article.id == items.first?.id, searchText.isEmpty {
                        ArticleHeroCard(article: article, isRead: store.isRead(article))
                    } else {
                        ArticleRow(article: article, isRead: store.isRead(article))
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .swipeActions(edge: .leading) {
                    let isRead = store.isRead(article)
                    Button(isRead ? "Non lu" : "Lu", systemImage: isRead ? "circle" : "checkmark.circle") {
                        store.toggleRead(article)
                    }
                    .tint(.blue)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .overlay {
            if items.isEmpty { emptyState }
        }
        .refreshable { await store.refresh() }
        .sheet(isPresented: $showingDofusNews) {
            if let url = Self.dofusNewsURL { ArticleWebView(url: url) }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if !searchText.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else if store.isLoading {
            ProgressView("Chargement…")
        } else {
            ContentUnavailableView(
                "Aucun article",
                systemImage: "newspaper",
                description: Text("Tire vers le bas pour actualiser, ou vérifie tes sources dans les réglages.")
            )
        }
    }
}
