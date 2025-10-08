import SwiftUI

struct StoryRowView: View {
    let story: Story
    @EnvironmentObject private var persistence: PersistenceStore

    private let imageAspectRatio: CGFloat = 4.0 / 5.0
    private let imageCornerRadius: CGFloat = 12

    @State private var selectedPage: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Nagłówek: avatar + imię + Follow + kropki
            HStack(spacing: 10) {
                StoryAvatarView(url: story.user.avatarURL, seen: false, displayedPlace: .storyDetail)
                Text(story.user.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button {
                } label: {
                    Text("Follow")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.black)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 18)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.05))
                        )
                }
                Button {
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.primary)
                        .padding(8)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)

            if !story.items.isEmpty {
                GeometryReader { geo in
                    let width = geo.size.width
                    let height = width / imageAspectRatio
                    ZStack {
                        RoundedRectangle(cornerRadius: imageCornerRadius, style: .continuous)
                            .fill(Color.gray.opacity(0.12))
                            .frame(width: width, height: height)

                        TabView(selection: $selectedPage) {
                            ForEach(Array(story.items.enumerated()), id: \.element.id) { idx, item in
                                AsyncImage(url: item.imageURL) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                            .scaleEffect(1.3)
                                            .frame(width: width, height: height)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: width, height: height)
                                            .clipped()
                                    case .failure:
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 42, height: 42)
                                            .foregroundColor(.gray.opacity(0.36))
                                            .frame(width: width, height: height)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .frame(width: width, height: height)
                                .clipped()
                                .tag(idx)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                        .frame(width: width, height: height)
                    }
                    .frame(width: width, height: height)
                }
                .frame(maxWidth: .infinity)
                .frame(height: UIScreen.main.bounds.width / imageAspectRatio)
                .padding([.horizontal, .bottom], 0)
            }
        }
        .background(Color(.systemBackground))
        .shadow(color: Color(.black).opacity(0.03), radius: 4, x: 0, y: 2)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
