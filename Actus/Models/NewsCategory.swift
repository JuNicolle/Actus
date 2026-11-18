import SwiftUI

enum NewsCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case france, monde, economie, tech, sport, culture, science

    var id: String { rawValue }

    var title: String {
        switch self {
        case .france: "France"
        case .monde: "Monde"
        case .economie: "Économie"
        case .tech: "Tech"
        case .sport: "Sport & santé"
        case .culture: "Culture"
        case .science: "Science"
        }
    }

    var systemImage: String {
        switch self {
        case .france: "flag"
        case .monde: "globe.europe.africa"
        case .economie: "chart.line.uptrend.xyaxis"
        case .tech: "cpu"
        case .sport: "sportscourt"
        case .culture: "theatermasks"
        case .science: "atom"
        }
    }

    var color: Color {
        switch self {
        case .france: .blue
        case .monde: .teal
        case .economie: .green
        case .tech: .purple
        case .sport: .orange
        case .culture: .pink
        case .science: .indigo
        }
    }
}
