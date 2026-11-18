import SwiftUI

/// Carte compacte : texte à gauche, vignette à droite.
struct ArticleRow: View {
    let article: Article
    let isRead: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    if !isRead {
                        Circle().fill(article.category.color).frame(width: 8, height: 8)
                    }
                    SourceTag(name: article.sourceName, category: article.category)
                    Text(article.date, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(article.title)
                    .font(.system(.headline, design: .serif, weight: .bold))
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(isRead ? .secondary : .primary)
                if !article.summary.isEmpty {
                    Text(article.summary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            Spacer(minLength: 0)
            if let imageURL = article.imageURL {
                AsyncImage(url: imageURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(.fill.tertiary)
                }
                .frame(width: 88, height: 88)
                .clipShape(.rect(cornerRadius: 12))
                .opacity(isRead ? 0.6 : 1)
                .accessibilityHidden(true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: .rect(cornerRadius: 20))
        .accessibilityElement(children: .combine)
        .accessibilityValue(isRead ? "Lu" : "Non lu")
    }
}
