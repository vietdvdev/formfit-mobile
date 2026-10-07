import SwiftUI
import SwiftData

/// Điểm khởi đầu chính của ứng dụng FormFit (App Entry Point)
/// 1. Cấu hình ModelContainer cho SwiftData (Offline-First Entities).
/// 2. Khởi tạo và đưa Dependency Injection vào @Environment (AppNavigationCoordinator, SubscriptionManager, HealthKitManager).
/// 3. Xử lý mở màn hình từ URL Scheme / Universal Link (Deep Link) vào thẳng bài tập hoặc chat với PT.
@main
public struct FormFitApp: App {
    // MARK: - State Objects & Coordinators
    @State private var coordinator = AppNavigationCoordinator()
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var healthKitManager = HealthKitManager.shared
    @State private var syncService = WorkoutSyncService.shared

    // MARK: - SwiftData Container
    private let sharedModelContainer: ModelContainer

    public init() {
        do {
            let schema = Schema([
                WorkoutSession.self,
                WorkoutExercise.self,
                SetEntry.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            self.sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("[FormFitApp] ❌ Không thể khởi tạo SwiftData ModelContainer: \(error.localizedDescription)")
        }
    }

    public var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(coordinator)
                .environment(subscriptionManager)
                .environment(healthKitManager)
                .modelContainer(sharedModelContainer)
                .task {
                    // Gán ModelContext cho Sync Engine
                    let context = sharedModelContainer.mainContext
                    syncService.attachModelContext(context)

                    // Kiểm tra và cập nhật trạng thái bản quyền Pro
                    await subscriptionManager.updateSubscriptionStatus()
                }
                .onOpenURL { url in
                    // Xử lý Deep Linking (formfit://exercises/bench_press hoặc formfit://chat/1)
                    coordinator.handleDeepLink(url: url)
                }
        }
    }
}
