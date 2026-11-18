import Foundation

struct RawFeedItem: Sendable {
    let title: String
    let link: URL
    let description: String
    let imageURL: URL?
    let date: Date?
    /// Média d'origine quand le flux agrège plusieurs sources (ex. Google Actualités).
    let originalSource: String?
}

/// Parseur RSS 2.0 / Atom / RDF minimaliste. À utiliser de façon synchrone via `parse(_:)`.
final class FeedParser: NSObject, XMLParserDelegate {
    private struct Draft {
        var title = ""
        var link = ""
        var description = ""
        var date = ""
        var imageURL: URL?
        var originalSource = ""
    }

    private var items: [RawFeedItem] = []
    private var draft: Draft?
    private var buffer = ""
    private let dateFormatters: [DateFormatter]

    static func parse(_ data: Data) -> [RawFeedItem] {
        let delegate = FeedParser()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return delegate.items
    }

    private override init() {
        let formats = [
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "EEE, dd MMM yyyy HH:mm:ss zzz",
            "EEE, d MMM yyyy HH:mm:ss Z",
            "dd MMM yyyy HH:mm:ss Z",
        ]
        dateFormatters = formats.map { format in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format  // format d'échange fixe, pas d'affichage
            return formatter
        }
        super.init()
    }

    // MARK: XMLParserDelegate

    func parser(
        _ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
        qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]
    ) {
        buffer = ""
        switch elementName {
        case "item", "entry":
            draft = Draft()
        case "link":
            if draft?.link.isEmpty == true, let href = attributeDict["href"],
               (attributeDict["rel"] ?? "alternate") == "alternate" {
                draft?.link = href
            }
        case "itunes:image":
            if draft?.imageURL == nil, let href = attributeDict["href"] { draft?.imageURL = URL(string: href) }
        case "enclosure", "media:thumbnail", "media:content":
            guard draft?.imageURL == nil, let value = attributeDict["url"] else { break }
            let type = attributeDict["type"] ?? ""
            let isImage = elementName == "media:thumbnail" || attributeDict["medium"] == "image" || type.hasPrefix("image")
            if isImage { draft?.imageURL = URL(string: value) }
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        buffer += string
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        buffer += String(decoding: CDATABlock, as: UTF8.self)
    }

    func parser(
        _ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        guard draft != nil else { return }
        let text = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        switch elementName {
        case "title":
            if draft?.title.isEmpty == true { draft?.title = text }
        case "link":
            if draft?.link.isEmpty == true { draft?.link = text }
        case "description", "summary":
            if draft?.description.isEmpty == true { draft?.description = text }
        case "pubDate", "published", "updated", "dc:date":
            if draft?.date.isEmpty == true { draft?.date = text }
        case "source":
            if draft?.originalSource.isEmpty == true, !text.contains("\n") { draft?.originalSource = text }
        case "item", "entry":
            finishItem()
        default:
            break
        }
    }

    // MARK: Construction

    private func finishItem() {
        defer { draft = nil }
        guard let draft, let link = URL(string: draft.link) else { return }
        let title = draft.title.strippingHTML
        guard !title.isEmpty else { return }
        items.append(RawFeedItem(
            title: title,
            link: link,
            description: draft.description.strippingHTML,
            imageURL: draft.imageURL ?? draft.description.firstImageURL,
            date: parseDate(draft.date),
            originalSource: draft.originalSource.isEmpty ? nil : draft.originalSource
        ))
    }

    private func parseDate(_ string: String) -> Date? {
        guard !string.isEmpty else { return nil }
        if let date = try? Date(string, strategy: .iso8601) { return date }
        if let date = try? Date(string, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true)) {
            return date
        }
        for formatter in dateFormatters {
            if let date = formatter.date(from: string) { return date }
        }
        return nil
    }
}
