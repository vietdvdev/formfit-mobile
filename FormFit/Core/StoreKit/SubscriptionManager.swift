import Foundation
import StoreKit
import Observation

/// Quản lý toàn bộ vòng đời gói thuê bao FormFit Pro hoàn toàn bằng StoreKit 2
/// Tương thích 100% với file cấu hình Products.storekit trên Xcode Simulator
@Observable
@MainActor
public final class SubscriptionManager {
    public static let shared = SubscriptionManager()

    // MARK: - Product IDs
    public static let monthlySubscriptionID = "com.formfit.subscription.monthly"
    public static let annualSubscriptionID = "com.formfit.subscription.annual"

    public static let allProductIDs: Set<String> = [
        monthlySubscriptionID,
        annualSubscriptionID
    ]

    // MARK: - Observable States
    public private(set) var subscriptions: [Product] = []
    public private(set) var purchasedSubscriptions: [Product] = []
    public private(set) var isProUser: Bool = false
    public private(set) var isLoading: Bool = false
    public var errorMessage: String? = nil

    private var transactionListenerTask: Task<Void, Error>?

    private init() {
        // Khởi động listener lắng nghe transaction background updates
        self.transactionListenerTask = listenForTransactions()

        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - 1. Load Products from StoreKit
    public func loadProducts() async {
        self.isLoading = true
        self.errorMessage = nil
        defer { self.isLoading = false }

        do {
            let storeProducts = try await Product.products(for: Self.allProductIDs)
            // Sắp xếp đưa gói năm lên trước hoặc sắp xếp theo mức giá
            self.subscriptions = storeProducts.sorted(by: { $0.price > $1.price })
        } catch {
            self.errorMessage = "Không thể tải danh sách sản phẩm: \(error.localizedDescription)"
            print("[SubscriptionManager] ⚠️ Lỗi tải gói: \(error.localizedDescription)")
        }
    }

    // MARK: - 2. Purchase Flow (StoreKit 2)
    public func purchase(_ product: Product) async throws -> Bool {
        self.isLoading = true
        self.errorMessage = nil
        defer { self.isLoading = false }

        let result: Product.PurchaseResult
        do {
            result = try await product.purchase()
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }

        switch result {
        case .success(let verificationResult):
            // Xác thực chữ ký JWS từ App Store
            let transaction = try checkVerified(verificationResult)
            
            // Cập nhật trạng thái người dùng Pro ngay lập tức
            await updateSubscriptionStatus()
            
            // Kết thúc transaction để StoreKit ghi nhận hoàn tất giao dịch
            await transaction.finish()
            return true

        case .userCancelled:
            return false

        case .pending:
            // Chờ phụ huynh phê duyệt (Ask to Buy) hoặc xác thực ngân hàng
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - 3. Restore Purchases
    public func restorePurchases() async {
        self.isLoading = true
        self.errorMessage = nil
        defer { self.isLoading = false }

        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            self.errorMessage = "Không thể khôi phục giao dịch: \(error.localizedDescription)"
            print("[SubscriptionManager] ⚠️ Lỗi restore: \(error.localizedDescription)")
        }
    }

    // MARK: - 4. Listen for Background Transaction Updates
    public func listenForTransactions() -> Task<Void, Error> {
        return Task.detached(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { break }
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    print("[SubscriptionManager] ⚠️ Transaction chưa được xác minh: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - 5. Update Subscription Status & Entitlements
    public func updateSubscriptionStatus() async {
        var purchased: [Product] = []
        var hasActivePro = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }

            if Self.allProductIDs.contains(transaction.productID) {
                // Kiểm tra xem giao dịch đã bị thu hồi (Revoke/Refund) chưa
                if transaction.revocationDate == nil {
                    // Kiểm tra ngày hết hạn của gói thuê bao
                    if let expirationDate = transaction.expirationDate {
                        if expirationDate > Date() {
                            hasActivePro = true
                            if let matchingProduct = self.subscriptions.first(where: { $0.id == transaction.productID }) {
                                purchased.append(matchingProduct)
                            }
                        }
                    } else {
                        hasActivePro = true
                    }
                }
            }
        }

        self.purchasedSubscriptions = purchased
        self.isProUser = hasActivePro
    }

    // MARK: - JWS Verification Helper
    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safeValue):
            return safeValue
        }
    }
}
