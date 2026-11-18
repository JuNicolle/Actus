import Foundation

extension String {
    /// Retire les balises HTML, décode les entités courantes et compacte les espaces.
    var strippingHTML: String {
        var text = replacing(/<[^>]+>/, with: " ")
        text = text.replacing(/&#(\d+);/) { match in
            guard let code = UInt32(match.output.1), let scalar = Unicode.Scalar(code) else {
                return String(match.output.0)
            }
            return String(Character(scalar))
        }
        let entities = [
            "&nbsp;": " ", "&amp;": "&", "&quot;": "\"", "&apos;": "'",
            "&lt;": "<", "&gt;": ">", "&laquo;": "«", "&raquo;": "»",
            "&rsquo;": "’", "&lsquo;": "‘", "&hellip;": "…",
        ]
        for (entity, value) in entities {
            text = text.replacing(entity, with: value)
        }
        return text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    /// Premier `src` d'une balise `<img>` contenue dans du HTML.
    var firstImageURL: URL? {
        guard let match = firstMatch(of: /<img[^>]+src=["']([^"']+)["']/) else { return nil }
        return URL(string: String(match.output.1))
    }
}
