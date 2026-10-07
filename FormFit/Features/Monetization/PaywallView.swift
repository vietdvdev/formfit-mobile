import SwiftUI
import StoreKit

/// Màn hình Paywall phục vụ kiểm thử luồng mua gói FormFit Pro trên Xcode Simulator
/// Tích hợp trực tiếp với SubscriptionManager (StoreKit 2) và Products.storekit
public struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedProduct: Product?
    @State private var showSuccessAlert: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header trạng thái Pro hiện tại
                    statusHeader

                    // Quyền lợi gói Pro
                    benefitsSection

                    // Danh sách gói cước đọc trực tiếp từ StoreKit
                    if subscriptionManager.isLoading && subscriptionManager.subscriptions.isEmpty {
                        ProgressView("Đang tải gói từ StoreKit...")
                            .padding(.vertical, 32)
                    } else if subscriptionManager.subscriptions.isEmpty {
                        emptyProductsPlaceholder
                    } else {
                        productsListSection
                    }

                    // Nút Mua hàng / Kích hoạt Trial
                    ctaButtonSection

                    // Nút Restore và điều khoản
                    footerSection
                }
                .padding(20)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("FormFit Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Khôi phục") {
                        Task {
                            await subscriptionManager.restorePurchases()
                            if subscriptionManager.isProUser {
                                showSuccessAlert = true
                            }
                        }
                    }
                }
            }
            .alert("Kích hoạt thành công!", isPresented: $showSuccessAlert) {
                Button("OK") {}
            } message: {
                Text("Gói FormFit Pro của bạn đã sẵn sàng.")
            }
            .task {
                if subscriptionManager.subscriptions.isEmpty {
                    await subscriptionManager.loadProducts()
                }
                if selectedProduct == nil {
                    // Mặc định chọn gói năm (tiết kiệm hơn)
                    selectedProduct = subscriptionManager.subscriptions.first(where: { $0.id == SubscriptionManager.annualSubscriptionID })
                        ?? subscriptionManager.subscriptions.first
                }
            }
        }
    }

    // MARK: - Status Header
    private var statusHeader: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(subscriptionManager.isProUser ? Color.green.opacity(0.15) : Color.purple.opacity(0.15))
                    .frame(width: 68, height: 68)

                Image(systemName: subscriptionManager.isProUser ? "checkmark.seal.fill" : "crown.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(subscriptionManager.isProUser ? .green : .purple)
            }

            Text(subscriptionManager.isProUser ? "Tài Khoản FormFit Pro" : "Nâng Cấp Lên Pro")
                .font(.title2.bold())

            Text(subscriptionManager.isProUser ? "Bạn đang sở hữu toàn bộ đặc quyền cao cấp" : "Mở khóa toàn bộ mô hình giải phẫu 3D và không giới hạn giáo án")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Benefits Section
    private var benefitsSection: some View {
        VStack(spacing: 10) {
            benefitRow(icon: "cube.transparent.fill", title: "Toàn bộ thư viện mô hình 3D xoay 360°")
            benefitRow(icon: "list.clipboard.fill", title: "Không giới hạn số lượng giáo án tùy biến")
            benefitRow(icon: "camera.viewfinder", title: "Ghost Overlay Camera & So sánh Before/After")
            benefitRow(icon: "video.badge.waveform.fill", title: "Kênh chat 1-1 gửi clip sửa form cho PT")
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private func benefitRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.purple)
                .frame(width: 24)
            Text(title)
                .font(.subheadline)
            Spacer()
        }
    }

    // MARK: - Products List Section (Đọc trực tiếp từ StoreKit 2)
    private var productsListSection: some View {
        VStack(spacing: 12) {
            ForEach(subscriptionManager.subscriptions) { product in
                let isSelected = (selectedProduct?.id == product.id)
                let isAnnual = (product.id == SubscriptionManager.annualSubscriptionID)

                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        selectedProduct = product
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(product.displayName)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                if isAnnual {
                                    Text("Tiết kiệm 33%")
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.orange, in: Capsule())
                                        .foregroundStyle(.white)
                                } else if product.introductoryOffer != nil {
                                    Text("Dùng thử 7 ngày")
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.purple, in: Capsule())
                                        .foregroundStyle(.white)
                                }
                            }

                            Text(product.description)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(product.displayPrice)
                                .font(.subheadline.bold())
                                .foregroundStyle(isSelected ? .purple : .primary)

                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(isSelected ? .purple : .secondary.opacity(0.4))
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - CTA Button Section
    private var ctaButtonSection: some View {
        VStack(spacing: 8) {
            Button {
                guard let product = selectedProduct else { return }
                Task {
                    do {
                        let success = try await subscriptionManager.purchase(product)
                        if success {
                            showSuccessAlert = true
                        }
                    } catch {
                        print("Lỗi mua hàng:", error)
                    }
                }
            } label: {
                HStack {
                    if subscriptionManager.isLoading {
                        ProgressView().tint(.white).padding(.trailing, 4)
                    }
                    Text(ctaButtonTitle)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(selectedProduct == nil || subscriptionManager.isLoading)

            if let error = subscriptionManager.errorMessage {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var ctaButtonTitle: String {
        guard let p = selectedProduct else { return "Chọn gói thuê bao" }
        if p.id == SubscriptionManager.monthlySubscriptionID && p.introductoryOffer != nil {
            return "Bắt Đầu Dùng Thử 7 Ngày Miễn Phí"
        } else if p.id == SubscriptionManager.annualSubscriptionID {
            return "Đăng Ký Gói Năm (Tiết kiệm 33%)"
        } else {
            return "Đăng Ký Ngay • \(p.displayPrice)"
        }
    }

    private var footerSection: some View {
        VStack(spacing: 8) {
            Button("Khôi phục giao dịch đã mua") {
                Task {
                    await subscriptionManager.restorePurchases()
                }
            }
            .font(.caption.bold())
            .foregroundStyle(.secondary)

            Text("Gói thuê bao tự động gia hạn trừ khi bạn hủy trước ít nhất 24 giờ. Quản lý gói trong Cài đặt Apple ID.")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 4)
    }

    private var emptyProductsPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(.orange)
            Text("Chưa đọc được cấu hình StoreKit")
                .font(.subheadline.bold())
            Text("Hãy chọn Scheme -> Edit Scheme -> Run -> Options -> StoreKit Configuration -> Products.storekit")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
    }
}

#Preview {
    PaywallView()
}
