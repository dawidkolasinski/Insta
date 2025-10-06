import SwiftUI

struct ListFeedPlaceholderView: View {
    let number: Int
    // Upewnij się, że proporcja jest taka sama jak w StoryRowView!
    private let imageAspectRatio: CGFloat = 4.0 / 5.0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(.gray.opacity(0.3))
                    .frame(width: 32, height: 32)
                Text("user_\(number + 1)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                let width = geo.size.width
                let height = width / imageAspectRatio
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: width, height: height)
                    .overlay(
                        Text("Feed content placeholder")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    )
            }
            // Wymuś docelową wysokość na podstawie szerokości kontenera
            .frame(maxWidth: .infinity)
            .frame(height: UIScreen.main.bounds.width / imageAspectRatio)
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
    }
}
