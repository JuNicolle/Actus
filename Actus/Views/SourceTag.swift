import SwiftUI

struct SourceTag: View {
    let name: String
    let category: NewsCategory
    var onImage = false

    var body: some View {
        Text(name)
            .font(.caption.weight(.semibold))
            .foregroundStyle(onImage ? .white : category.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(onImage ? AnyShapeStyle(.black.opacity(0.35)) : AnyShapeStyle(category.color.opacity(0.14)), in: .capsule)
    }
}
