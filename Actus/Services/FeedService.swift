import Foundation

struct FeedFetchResult: Sendable {
    var articles: [Article] = []
    var failedSourceNames: [String] = []
}

struct FeedService: Sendable {
    enum FetchError: Error {
        case badStatus
    }

    func fetchAll(sources: [FeedSource]) async -> FeedFetchResult {
        await withTaskGroup(of: (FeedSource, [Article]?).self) { group in
            for source in sources {
                group.addTask { (source, try? await fetch(source)) }
            }
            var result = FeedFetchResult()
            for await (source, articles) in group {
                if let articles {
                    result.articles += articles
                } else if !result.failedSourceNames.contains(source.name) {
                    result.failedSourceNames.append(source.name)
                }
            }
            return result
        }
    }

    func fetch(_ source: FeedSource) async throws -> [Article] {
        var request = URLRequest(url: source.url, timeoutInterval: 15)
        request.setValue("Actus/1.0", forHTTPHeaderField: "User-Agent")
        if let maxBytes = source.maxBytes {
            request.setValue("bytes=0-\(maxBytes)", forHTTPHeaderField: "Range")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let status = (response as? HTTPURLResponse)?.statusCode, status == 200 || status == 206 else {
            throw FetchError.badStatus
        }

        // Les 60 plus récents suffisent (certains flux en contiennent plusieurs centaines).
        let recent = FeedParser.parse(data)
            .sorted { ($0.date ?? .now) > ($1.date ?? .now) }
            .prefix(60)
        return recent.map { item in
            let originalSource = item.originalSource
            let title = originalSource.map { item.title.removingSuffix(" - \($0)") } ?? item.title
            return Article(
                id: item.link.absoluteString,
                title: title,
                summary: item.description,
                link: item.link,
                imageURL: item.imageURL,
                date: item.date ?? .now,
                sourceID: source.id,
                sourceName: originalSource ?? source.name,
                category: source.category
            )
        }
    }
}

private extension String {
    func removingSuffix(_ suffix: String) -> String {
        hasSuffix(suffix) ? String(dropLast(suffix.count)) : self
    }
}
