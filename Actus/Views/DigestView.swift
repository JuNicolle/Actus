import SwiftUI

struct DigestView: View {
    @Environment(NewsStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var digest: String?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                content
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("L'essentiel du jour")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer", action: dismiss.callAsFunction)
                }
            }
            .task { await generate() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let reason = Summarizer.unavailabilityReason {
            ContentUnavailableView("Résumé indisponible", systemImage: "sparkles", description: Text(reason))
        } else if let digest {
            VStack(alignment: .leading, spacing: 16) {
                Text(digest)
                Button("Régénérer", systemImage: "arrow.clockwise") {
                    Task { await generate() }
                }
                .buttonStyle(.bordered)
            }
        } else if let errorMessage {
            ContentUnavailableView("Échec du résumé", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
        } else {
            ProgressView("Rédaction en cours…")
                .frame(maxWidth: .infinity)
        }
    }

    private func generate() async {
        guard Summarizer.unavailabilityReason == nil else { return }
        digest = nil
        errorMessage = nil
        do {
            digest = try await Summarizer.digest(of: store.digestArticles())
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
