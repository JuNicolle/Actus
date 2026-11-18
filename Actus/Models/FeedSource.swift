import Foundation

struct FeedSource: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
    let category: NewsCategory
    let url: URL
    let isFrench: Bool
    /// Limite de téléchargement pour les flux très volumineux (les épisodes récents sont en tête).
    let maxBytes: Int?
    /// Durée de conservation des articles (7 jours par défaut ; plus longue pour les sujets peu fréquents).
    let retentionDays: Int?

    init(_ id: String, _ name: String, _ category: NewsCategory, _ urlString: String, french: Bool = true, maxBytes: Int? = nil, retentionDays: Int? = nil) {
        guard let url = URL(string: urlString) else {
            fatalError("URL de flux invalide : \(urlString)")
        }
        self.id = id
        self.name = name
        self.category = category
        self.url = url
        self.isFrench = french
        self.maxBytes = maxBytes
        self.retentionDays = retentionDays
    }
}

extension FeedSource {
    /// Flux RSS publics et gratuits : aucun compte, aucun réseau social.
    static let all: [FeedSource] = [
        // France
        FeedSource("franceinfo-une", "franceinfo", .france, "https://www.francetvinfo.fr/titres.rss"),
        FeedSource("20minutes", "20 Minutes", .france, "https://www.20minutes.fr/feeds/rss-une.xml"),
        FeedSource("ouestfrance", "Ouest-France", .france, "https://www.ouest-france.fr/rss/une"),
        FeedSource("bfmtv", "BFMTV", .france, "https://www.bfmtv.com/rss/news-24-7/"),
        FeedSource("tf1info", "TF1 Info", .france, "https://www.tf1info.fr/feeds/rss-une.xml"),
        FeedSource("slate", "Slate.fr", .france, "https://www.slate.fr/rss.xml"),
        FeedSource("conversation", "The Conversation", .france, "https://theconversation.com/fr/articles.atom"),
        FeedSource("mrmondialisation", "Mr Mondialisation", .france, "https://mrmondialisation.org/feed/"),
        // Monde
        FeedSource("franceinfo-monde", "franceinfo", .monde, "https://www.francetvinfo.fr/monde.rss"),
        FeedSource("rfi", "RFI", .monde, "https://www.rfi.fr/fr/rss"),
        FeedSource("france24", "France 24", .monde, "https://www.france24.com/fr/rss"),
        FeedSource("bbc-world", "BBC News", .monde, "https://feeds.bbci.co.uk/news/world/rss.xml", french: false),
        FeedSource("guardian", "The Guardian", .monde, "https://www.theguardian.com/world/rss", french: false),
        FeedSource("aljazeera", "Al Jazeera", .monde, "https://www.aljazeera.com/xml/rss/all.xml", french: false),
        FeedSource("hugodecrypte", "HugoDécrypte", .monde,
                   "https://feeds.acast.com/public/shows/95497e34-ecc2-596a-b910-bb3342918621", maxBytes: 250_000),
        // Économie
        FeedSource("franceinfo-eco", "franceinfo", .economie, "https://www.francetvinfo.fr/economie.rss"),
        FeedSource("bbc-business", "BBC News", .economie, "https://feeds.bbci.co.uk/news/business/rss.xml", french: false),
        FeedSource("bfmbusiness", "BFM Business", .economie, "https://www.bfmtv.com/rss/economie/"),
        // Tech
        FeedSource("franceinfo-tech", "franceinfo", .tech, "https://www.francetvinfo.fr/internet.rss"),
        FeedSource("bbc-tech", "BBC News", .tech, "https://feeds.bbci.co.uk/news/technology/rss.xml", french: false),
        FeedSource("numerama", "Numerama", .tech, "https://www.numerama.com/feed/"),
        FeedSource("frandroid", "Frandroid", .tech, "https://www.frandroid.com/feed"),
        FeedSource("jdg", "Journal du Geek", .tech, "https://www.journaldugeek.com/feed/"),
        FeedSource("clubic", "Clubic", .tech, "https://www.clubic.com/feed/news.rss"),
        FeedSource("korben", "Korben", .tech, "https://korben.info/feed"),
        FeedSource("lesnumeriques", "Les Numériques", .tech, "https://www.lesnumeriques.com/rss.xml"),
        FeedSource("01net", "01net", .tech, "https://www.01net.com/feed/"),
        FeedSource("developpez", "Developpez", .tech, "https://www.developpez.com/index/rss"),
        FeedSource("hackernews", "Hacker News", .tech, "https://hnrss.org/frontpage", french: false),
        FeedSource("devto", "DEV Community", .tech, "https://dev.to/feed", french: false),
        // Sport
        FeedSource("franceinfo-sport", "franceinfo", .sport, "https://www.francetvinfo.fr/sports.rss"),
        FeedSource("sportsfr", "Sports.fr", .sport, "https://www.sports.fr/feed"),
        FeedSource("topsante", "Top Santé", .sport, "https://www.topsante.com/feed"),
        FeedSource("futura-sante", "Futura Santé", .sport, "https://www.futura-sciences.com/rss/sante/actualites.xml"),
        FeedSource("greatist", "Greatist", .sport, "https://greatist.com/feed", french: false),
        // Culture
        FeedSource("franceinfo-culture", "franceinfo", .culture, "https://www.francetvinfo.fr/culture.rss"),
        FeedSource("konbini", "Konbini", .culture, "https://www.konbini.com/feed/"),
        FeedSource("jeuxvideo", "Jeuxvideo.com", .culture, "https://www.jeuxvideo.com/rss/rss.xml"),
        FeedSource("gamekult", "Gamekult", .culture, "https://www.gamekult.com/feed.xml"),
        FeedSource("allocine", "Allociné", .culture, "https://www.allocine.fr/rss/news.xml"),
        FeedSource("ecranlarge", "Écran Large", .culture, "https://www.ecranlarge.com/feed"),
        // Le site d'Ankama refuse les accès automatiques : on passe par la recherche Google Actualités.
        FeedSource("dofus", "Dofus", .culture,
                   "https://news.google.com/rss/search?q=Dofus&hl=fr&gl=FR&ceid=FR:fr", retentionDays: 90),
        // Science
        FeedSource("franceinfo-sante", "franceinfo Santé", .science, "https://www.francetvinfo.fr/sante.rss"),
        FeedSource("futura", "Futura", .science, "https://www.futura-sciences.com/rss/actualites.xml"),
        FeedSource("technoscience", "Techno-Science", .science, "https://www.techno-science.net/include/news.xml"),
        FeedSource("sciencepost", "Sciencepost", .science, "https://sciencepost.fr/feed/"),
        FeedSource("sciencedaily", "ScienceDaily", .science, "https://www.sciencedaily.com/rss/all.xml", french: false),
        FeedSource("nasa", "NASA", .science, "https://www.nasa.gov/rss/dyn/breaking_news.rss", french: false),
        FeedSource("quanta", "Quanta Magazine", .science, "https://www.quantamagazine.org/feed/", french: false),
    ]
}
