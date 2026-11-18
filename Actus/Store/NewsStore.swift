import Foundation
import Observation

@MainActor @Observable
final class NewsStore {
    private(set) var articles: [Article] = []
    private(set) var readIDs: Set<String> = []
    private(set) var isLoading = false
    private(set) var lastUpdated: Date?
    private(set) var failedSourceNames: [String] = []

    var disabledSourceIDs: Set<String> {
        didSet { defaults.set(Array(disabledSourceIDs), forKey: Keys.disabledSources) }
    }
    var frenchOnly: Bool {
        didSet { defaults.set(frenchOnly, forKey: Keys.frenchOnly) }
    }
    private(set) var customSources: [FeedSource] {
        didSet { saveCustomSources() }
    }
    var mutedKeywords: [String] {
        didSet { defaults.set(mutedKeywords, forKey: Keys.mutedKeywords) }
    }

    private let service = FeedService()
    private let defaults = UserDefaults.standard
    private let cacheURL = URL.cachesDirectory.appending(path: "articles.json")
    private let refreshInterval: TimeInterval = 10 * 60

    private enum Keys {
        static let customSources = "customSources"
        static let frenchOnly = "frenchOnly"
        static let disabledSources = "disabledSources"
        static let mutedKeywords = "mutedKeywords"
        static let readIDs = "readIDs"
        static let lastUpdated = "lastUpdated"
    }

    init() {
        disabledSourceIDs = Set(defaults.stringArray(forKey: Keys.disabledSources) ?? [])
        frenchOnly = defaults.bool(forKey: Keys.frenchOnly)
        customSources = defaults.data(forKey: Keys.customSources)
            .flatMap { try? JSONDecoder().decode([FeedSource].self, from: $0) } ?? []
        mutedKeywords = defaults.stringArray(forKey: Keys.mutedKeywords) ?? []
        readIDs = Set(defaults.stringArray(forKey: Keys.readIDs) ?? [])
        lastUpdated = defaults.object(forKey: Keys.lastUpdated) as? Date
        let knownSourceIDs = Set((FeedSource.all + customSources).map(\.id))
        articles = Self.deduplicated(loadCache().filter { knownSourceIDs.contains($0.sourceID) })
    }

    // MARK: Lecture

    func articles(in category: NewsCategory?, matching query: String = "") -> [Article] {
        articles.filter { article in
            guard isEnabled(sourceID: article.sourceID) else { return false }
            if let category, article.category != category { return false }
            if mutedKeywords.contains(where: { article.title.localizedStandardContains($0) }) { return false }
            return query.isEmpty
                || article.title.localizedStandardContains(query)
                || article.summary.localizedStandardContains(query)
        }
    }

    var allSources: [FeedSource] { FeedSource.all + customSources }

    private func isEnabled(sourceID: String) -> Bool {
        guard !disabledSourceIDs.contains(sourceID) else { return false }
        guard frenchOnly else { return true }
        return allSources.first(where: { $0.id == sourceID })?.isFrench ?? true
    }

    // MARK: Sources personnalisées

    /// Vérifie que l'adresse est bien un flux RSS/Atom lisible avant de l'ajouter.
    func addCustomSource(name: String, urlString: String, category: NewsCategory, isFrench: Bool) async throws {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), url.scheme?.hasPrefix("http") == true else {
            throw SourceError.invalidURL
        }
        let source = FeedSource(
            "custom-\(UUID().uuidString)", name.trimmingCharacters(in: .whitespacesAndNewlines),
            category, url.absoluteString, french: isFrench
        )
        guard let articles = try? await service.fetch(source), !articles.isEmpty else {
            throw SourceError.notAFeed
        }
        customSources.append(source)
        await refresh()
    }

    func removeCustomSources(at offsets: IndexSet) {
        let removed = offsets.map { customSources[$0].id }
        customSources.remove(atOffsets: offsets)
        articles.removeAll { removed.contains($0.sourceID) }
        disabledSourceIDs.subtract(removed)
    }

    enum SourceError: LocalizedError {
        case invalidURL, notAFeed

        var errorDescription: String? {
            switch self {
            case .invalidURL: "Adresse invalide. Elle doit commencer par https://"
            case .notAFeed: "Aucun article trouvé : ce n'est pas un flux RSS valide ou le site est injoignable."
            }
        }
    }

    func unreadCount(in category: NewsCategory?) -> Int {
        articles(in: category).count(where: { !readIDs.contains($0.id) })
    }

    func isRead(_ article: Article) -> Bool {
        readIDs.contains(article.id)
    }

    /// Sélection variée d'articles non lus pour « l'essentiel du jour ».
    func digestArticles() -> [Article] {
        let quotas: [(NewsCategory, Int)] = [(.france, 4), (.monde, 4), (.economie, 2), (.tech, 2), (.sport, 2)]
        let selection = quotas.flatMap { category, count in
            articles(in: category).filter { !isRead($0) }.prefix(count)
        }
        return selection.isEmpty ? Array(articles(in: nil).prefix(10)) : selection
    }

    // MARK: Lu / non lu

    func markRead(_ article: Article) {
        readIDs.insert(article.id)
        persistReadState()
    }

    func toggleRead(_ article: Article) {
        if readIDs.remove(article.id) == nil { readIDs.insert(article.id) }
        persistReadState()
    }

    func markAllRead(in category: NewsCategory?) {
        readIDs.formUnion(articles(in: category).map(\.id))
        persistReadState()
    }

    func resetReadState() {
        readIDs = []
        persistReadState()
    }

    // MARK: Réglages

    subscript(isEnabled source: FeedSource) -> Bool {
        get { !disabledSourceIDs.contains(source.id) }
        set {
            if newValue {
                disabledSourceIDs.remove(source.id)
            } else {
                disabledSourceIDs.insert(source.id)
            }
        }
    }

    func addKeyword(_ keyword: String) {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !mutedKeywords.contains(trimmed) else { return }
        mutedKeywords.append(trimmed)
    }

    func removeKeywords(at offsets: IndexSet) {
        mutedKeywords.remove(atOffsets: offsets)
    }

    // MARK: Rafraîchissement

    func refreshIfNeeded() async {
        if let lastUpdated, Date.now.timeIntervalSince(lastUpdated) < refreshInterval { return }
        await refresh()
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let sources = allSources.filter { isEnabled(sourceID: $0.id) }
        let result = await service.fetchAll(sources: sources)
        failedSourceNames = result.failedSourceNames

        // Hors ligne : on garde le cache tel quel.
        guard !result.articles.isEmpty else { return }

        let retention = Dictionary(uniqueKeysWithValues: allSources.map { ($0.id, $0.retentionDays ?? 7) })
        func isFresh(_ article: Article) -> Bool {
            guard let days = retention[article.sourceID] else { return false }
            return article.date > Date.now.addingTimeInterval(-Double(days) * 86_400)
        }

        var merged = Dictionary(articles.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for article in result.articles where merged[article.id] == nil {
            merged[article.id] = article
        }
        // Un même article publié dans plusieurs flux d'une même source n'apparaît qu'une fois.
        articles = Self.deduplicated(merged.values.filter(isFresh).sorted { $0.date > $1.date })
        readIDs.formIntersection(articles.map(\.id))
        lastUpdated = .now
        defaults.set(lastUpdated, forKey: Keys.lastUpdated)
        persistReadState()
        saveCache()
    }

    private static func deduplicated(_ articles: [Article]) -> [Article] {
        var seen = Set<String>()
        return articles.filter { seen.insert("\($0.sourceName)|\($0.title)").inserted }
    }

    // MARK: Persistance

    private func persistReadState() {
        defaults.set(Array(readIDs), forKey: Keys.readIDs)
    }

    private func loadCache() -> [Article] {
        guard let data = try? Data(contentsOf: cacheURL) else { return [] }
        return (try? JSONDecoder().decode([Article].self, from: data)) ?? []
    }

    private func saveCustomSources() {
        defaults.set(try? JSONEncoder().encode(customSources), forKey: Keys.customSources)
    }

    private func saveCache() {
        guard let data = try? JSONEncoder().encode(articles) else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }
}
