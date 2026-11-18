import SwiftUI
import WebKit

struct ArticleWebView: View {
    @Environment(\.dismiss) private var dismiss
    let url: URL

    var body: some View {
        NavigationStack {
            WebView(url: url)
                .navigationTitle(url.host() ?? "")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Fermer", action: dismiss.callAsFunction)
                    }
                }
        }
    }
}
