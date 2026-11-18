import SwiftUI

struct ArticleDetailView: View {
    @Environment(NewsStore.self) private var store
    let article: Article

    @State private var showingWebPage = false
    @State private var aiSummary: String?
    @State private var isSummarizing = false
    @State private var summaryError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let imageURL = article.imageURL {
                    // Le conteneur fixe la taille ; l'image ne fait que le remplir (overlay n'influe pas sur la mise en page).
                    Color.secondary.opacity(0.15)
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                        .overlay {
                            AsyncImage(url: imageURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Color.clear
                            }
                        }
                        .clipShape(.rect(cornerRadius: 24))
                        .accessibilityHidden(true)
                }

                HStack(spacing: 8) {
                    SourceTag(name: article.sourceName, category: article.category)
                    Text(article.date, format: .dateTime.day().month().hour().minute())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(article.title)
                    .font(.system(.title, design: .serif, weight: .bold))

                if !article.summary.isEmpty {
                    Text(article.summary)
                        .font(.system(.body, design: .serif))
                        .lineSpacing(4)
                }

                summarySection

                Button("Lire l'article", systemImage: "safari") { showingWebPage = true }
                    .buttonStyle(.borderedProminent)
                    .tint(article.category.color)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: article.link)
            }
        }
        .sheet(isPresented: $showingWebPage) {
            ArticleWebView(url: article.link)
        }
        .task { store.markRead(article) }
    }

    @ViewBuilder
    private var summarySection: some View {
        if let reason = Summarizer.unavailabilityReason {
            Label(reason, systemImage: "sparkles")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } else if let aiSummary {
            VStack(alignment: .leading, spacing: 8) {
                Label("Résumé IA", systemImage: "sparkles")
                    .font(.subheadline.bold())
                Text(aiSummary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: .rect(cornerRadius: 16))
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Button("Résumer avec l'IA", systemImage: "sparkles", action: summarize)
                    .buttonStyle(.bordered)
                    .disabled(isSummarizing)
                if isSummarizing { ProgressView() }
                if let summaryError {
                    Text(summaryError).font(.footnote).foregroundStyle(.red)
                }
            }
        }
    }

    private func summarize() {
        isSummarizing = true
        summaryError = nil
        Task {
            do {
                aiSummary = try await Summarizer.summarize(article)
            } catch {
                summaryError = "Résumé impossible : \(error.localizedDescription)"
            }
            isSummarizing = false
        }
    }
}
