import SwiftUI

/// Màn hình Tab 5: Profile Analytics hiển thị tài khoản, gói FormFit Pro và chỉ số tổng quan
public struct ProfileAnalyticsView: View {
    @Environment(AppNavigationCoordinator.self) private var coordinator
    @State private var subscriptionManager = SubscriptionManager.shared

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Profile
                userProfileCard

                // Thẻ trạng thái FormFit Pro / Paywall
                proSubscriptionBanner

                // Liên kết sang màn hình theo dõi số đo & Kho ảnh Before/After
                bodyProgressNavigationCard

                // Cài đặt ứng dụng
                appSettingsSection
            }
            .padding(16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Hồ Sơ & Thống Kê")
    }

    private var userProfileCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 58))
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Nguyễn Văn A")
                    .font(.title3.bold())
                Text("Học viên FormFit • 24 tuổi")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Mục tiêu: Tăng cơ (Bulking)")
                    .font(.caption2.bold())
                    .foregroundStyle(.orange)
            }
            Spacer()
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private var proSubscriptionBanner: some View {
        Button {
            coordinator.showPaywall = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundStyle(.purple)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("FormFit Pro")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if subscriptionManager.isProUser {
                            Text("ĐANG HOẠT ĐỘNG")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green, in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }

                    Text(subscriptionManager.isProUser ? "Toàn bộ tính năng nâng cao đã mở khóa" : "Nâng cấp để mở khóa toàn bộ 3D và không giới hạn giáo án")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var bodyProgressNavigationCard: some View {
        NavigationLink(destination: BodyProgressDashboardView()) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "camera.viewfinder")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Kho Ảnh Before/After & Số Đo")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Biểu đồ Swift Charts cân nặng, vòng eo, ngực & Ghost Overlay")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private var appSettingsSection: some View {
        VStack(spacing: 12) {
            settingRow(icon: "heart.fill", color: .red, title: "Đồng bộ Apple Health", subtitle: "Đang bật (Nhịp tim & Calo)")
            Divider()
            settingRow(icon: "wifi", color: .green, title: "Chế độ Offline-First", subtitle: "Tự động lưu SwiftData & đồng bộ nền")
            Divider()
            settingRow(icon: "bell.fill", color: .orange, title: "Thông báo & Live Activities", subtitle: "Đếm giờ nghỉ trên Dynamic Island")
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private func settingRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
