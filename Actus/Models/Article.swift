import Foundation

struct Article: Identifiable, Hashable, Codable, Sendable {
    /// Lien canonique de l'article : stable d'un rafraîchissement à l'autre.
    let id: String
    let title: String
    let summary: String
    let link: URL
    let imageURL: URL?
    let date: Date
    let sourceID: String
    let sourceName: String
    let category: NewsCategory
}
