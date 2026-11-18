import SwiftUI

/// Raccourci vers les actualités officielles de Dofus, lues dans le navigateur intégré.
/// Le site d'Ankama bloque les accès automatisés : il n'y a donc pas de flux, seulement ce lien.
struct DofusShortcutRow: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: "gamecontroller.fill")
                    .font(.title2)
                    .foregroundStyle(NewsCategory.culture.color)
                    .frame(width: 44, height: 44)
                    .background(NewsCategory.culture.color.opacity(0.14), in: .rect(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Actualités officielles Dofus")
                        .font(.system(.headline, design: .serif, weight: .bold))
                    Text("Ouvre le site d'Ankama")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: .rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}
