import SwiftUI

/// Grande carte pour l'article à la une.
struct ArticleHeroCard: View {
    let article: Article
    let isRead: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle()
                .fill(article.category.color.gradient)
                .frame(height: 280)
                .overlay {
                    if let imageURL = article.imageURL {
                        AsyncImage(url: imageURL) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.clear
                        }
                    }
                }
                .overlay {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.55), .black.opacity(0.9)],
                        startPoint: .init(x: 0.5, y: 0.3), endPoint: .bottom
                    )
                }
                .clipped()


            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    SourceTag(name: article.sourceName, category: article.category, onImage: true)
                    Text(article.date, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Text(article.title)
                    .font(.system(.title3, design: .serif, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
        }
        .frame(height: 280)
        .clipShape(.rect(cornerRadius: 24))
        .accessibilityElement(children: .combine)
        .accessibilityValue(isRead ? "Lu" : "Non lu")
    }
}
