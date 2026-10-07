import SwiftUI

/// Màn hình Tab 4: Coach Marketplace hiển thị danh sách các PT kèm nút thuê và chat
public struct CoachMarketplaceView: View {
    @Environment(AppNavigationCoordinator.self) private var coordinator

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Banner giới thiệu
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Kết Nối Huấn Luyện Viên (PT)")
                            .font(.headline)
                        Text("Đồng hành 1-1, nhận giáo án độc quyền và gửi video sửa form động tác.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "person.badge.shield.checkmark.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                }
                .padding(16)
                .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))

                // Danh sách PT mẫu
                coachCard(
                    name: "Hoàng Nam (NASM-CPT)",
                    specialty: "Tăng cơ & Sức mạnh (Hypertrophy)",
                    rating: "4.9 ★ (42 đánh giá)",
                    price: "1.500.000 ₫ / tháng",
                    avatarIcon: "person.crop.circle.fill",
                    contractId: 1
                )

                coachCard(
                    name: "Lê Minh Thảo (ISSA-CPT)",
                    specialty: "Giảm mỡ nữ & Chỉnh sửa Form",
                    rating: "5.0 ★ (68 đánh giá)",
                    price: "1.800.000 ₫ / tháng",
                    avatarIcon: "person.crop.circle.fill",
                    contractId: 2
                )

                coachCard(
                    name: "Trần Quốc Hưng (CSCS)",
                    specialty: "Powerlifting & Thể lực thi đấu",
                    rating: "4.8 ★ (35 đánh giá)",
                    price: "2.000.000 ₫ / tháng",
                    avatarIcon: "person.crop.circle.fill",
                    contractId: 3
                )
            }
            .padding(16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Huấn Luyện Viên")
    }

    private func coachCard(
        name: String,
        specialty: String,
        rating: String,
        price: String,
        avatarIcon: String,
        contractId: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: avatarIcon)
                    .font(.system(size: 44))
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(name)
                            .font(.headline)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    Text(specialty)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(rating)
                        .font(.caption2.bold())
                        .foregroundStyle(.orange)
                }
                Spacer()
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Học phí:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(price)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                }

                Spacer()

                NavigationLink(destination: ChatConversationView(contractId: contractId, partnerName: name)) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                        Text("Nhắn tin & Sửa Form")
                    }
                    .font(.caption.bold())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.blue, in: Capsule())
                    .foregroundStyle(.white)
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.02), radius: 6, x: 0, y: 2)
    }
}
