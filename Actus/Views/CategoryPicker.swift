import SwiftUI

struct CategoryPicker: View {
    @Binding var selection: NewsCategory?

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                chip("À la une", systemImage: "newspaper", color: .primary, isSelected: selection == nil) {
                    selection = nil
                }
                ForEach(NewsCategory.allCases) { category in
                    chip(category.title, systemImage: category.systemImage, color: category.color,
                         isSelected: selection == category) {
                        selection = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
    }

    private func chip(
        _ title: String, systemImage: String, color: Color, isSelected: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(title, systemImage: systemImage, action: action)
            .font(.subheadline.weight(isSelected ? .bold : .regular))
            .buttonStyle(.glass)
            .tint(isSelected ? color : nil)
            .foregroundStyle(isSelected ? color : .secondary)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
