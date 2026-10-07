import SwiftUI

/// Component thanh trượt so sánh 2 bức ảnh Before và After cạnh nhau theo thời gian thực
public struct BeforeAfterSliderView: View {
    public let beforeImage: UIImage?
    public let afterImage: UIImage?
    public let beforeDateText: String
    public let afterDateText: String

    @State private var splitPositionRatio: CGFloat = 0.5 // Vị trí thanh trượt từ 0.0 -> 1.0

    public init(
        beforeImage: UIImage? = nil,
        afterImage: UIImage? = nil,
        beforeDateText: String = "8 tuần trước",
        afterDateText: String = "Hôm nay"
    ) {
        self.beforeImage = beforeImage
        self.afterImage = afterImage
        self.beforeDateText = beforeDateText
        self.afterDateText = afterDateText
    }

    public var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let dividerX = width * splitPositionRatio

            ZStack(alignment: .leading) {
                // 1. Ảnh After (Nằm nền phía sau)
                imageOrPlaceholder(image: afterImage, title: "AFTER", isAfter: true)
                    .frame(width: width, height: height)

                // 2. Ảnh Before (Được clip mask theo vị trí thanh trượt)
                imageOrPlaceholder(image: beforeImage, title: "BEFORE", isAfter: false)
                    .frame(width: width, height: height)
                    .mask(
                        HStack(spacing: 0) {
                            Rectangle()
                                .frame(width: max(0, dividerX), height: height)
                            Spacer(minLength: 0)
                        }
                    )

                // 3. Đường phân cách dọc & Nút cầm kéo (Divider Handle)
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 2)

                    // Nút kéo tròn ở giữa
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 36, height: 36)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

                        HStack(spacing: 3) {
                            Image(systemName: "chevron.left")
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.black)
                    }

                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 2)
                }
                .position(x: dividerX, y: height / 2)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let newRatio = value.location.x / width
                            splitPositionRatio = min(0.95, max(0.05, newRatio))
                        }
                )

                // 4. Badges hiển thị ngày mốc thời gian
                VStack {
                    HStack {
                        // Badge Before
                        Text("BEFORE • \(beforeDateText)")
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.65), in: Capsule())
                            .foregroundStyle(.white)

                        Spacer()

                        // Badge After
                        Text("AFTER • \(afterDateText)")
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.85), in: Capsule())
                            .foregroundStyle(.white)
                    }
                    .padding(12)

                    Spacer()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .contentShape(RoundedRectangle(cornerRadius: 20))
    }

    private func imageOrPlaceholder(image: UIImage?, title: String, isAfter: Bool) -> some View {
        ZStack {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                // Placeholder đồ họa minh họa thay đổi hình thể
                LinearGradient(
                    colors: isAfter ? [Color.blue.opacity(0.6), Color.cyan.opacity(0.4)] : [Color.gray.opacity(0.5), Color.secondary.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 8) {
                    Image(systemName: isAfter ? "figure.strengthtraining.traditional" : "figure.walk")
                        .font(.system(size: 48))
                        .foregroundStyle(.white)

                    Text(title)
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                }
            }
        }
    }
}
