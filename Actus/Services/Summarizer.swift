import FoundationModels

/// Résumés générés sur l'appareil par Apple Intelligence : gratuit, hors ligne, rien n'est envoyé.
enum Summarizer {
    /// `nil` si le modèle est disponible, sinon la raison à afficher.
    static var unavailabilityReason: String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            nil
        case .unavailable(.deviceNotEligible):
            "Cet appareil ne prend pas en charge Apple Intelligence."
        case .unavailable(.appleIntelligenceNotEnabled):
            "Active Apple Intelligence dans Réglages pour générer des résumés."
        case .unavailable(.modelNotReady):
            "Le modèle se télécharge encore, réessaie dans quelques minutes."
        case .unavailable:
            "Les résumés IA ne sont pas disponibles pour le moment."
        }
    }

    static func summarize(_ article: Article) async throws -> String {
        let session = LanguageModelSession(instructions: """
            Tu résumes des articles d'actualité en français, en 2 ou 3 phrases factuelles et neutres. \
            N'ajoute aucune information absente du texte.
            """)
        let response = try await session.respond(to: "\(article.title)\n\n\(article.summary)")
        return response.content
    }

    static func digest(of articles: [Article]) async throws -> String {
        let session = LanguageModelSession(instructions: """
            Tu rédiges chaque jour « l'essentiel de l'actualité » en français à partir d'une liste de titres. \
            Format : une courte rubrique par thème (France, Monde, Économie, Tech, Sport) avec 1 à 3 puces \
            d'une phrase chacune. Ton neutre, factuel, sans opinion. Ignore les thèmes sans article.
            """)
        let list = articles.map { article in
            "[\(article.category.title)] \(article.title). \(article.summary.prefix(160))"
        }.joined(separator: "\n")
        let response = try await session.respond(to: list)
        return response.content
    }
}
