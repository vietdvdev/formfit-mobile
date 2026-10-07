import SwiftUI
import SwiftData

/// Root Shell của ứng dụng FormFit:
/// 1. Tích hợp TabView(selection: $coordinator.selectedTab) với 5 Tab độc lập.
/// 2. Mỗi Tab được bọc trong một NavigationStack(path:) riêng biệt hỗ trợ Reset-to-root & Deep Linking.
/// 3. Overlay Mini-Player Bar nổi phía trên TabBar khi có buổi tập đang chạy (isWorkoutActive).
/// 4. Quản lý Fullscreen Cover mở ActiveWorkoutView và PaywallView.
public struct MainTabView: View {
    @Environment(AppNavigationCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    public init() {}

    public var body: some View {
        @Bindable var coord = coordinator

        ZStack(alignment: .bottom) {
            // 1. TabView 5 Tabs
            TabView(selection: Binding(
                get: { coordinator.selectedTab },
                set: { newTab in
                    coordinator.selectTab(newTab)
                }
            )) {
                // Tab 1: Workout Dashboard
                NavigationStack(path: $coord.workoutPath) {
                    WorkoutDashboardView()
                }
                .tabItem {
                    Label(AppTab.workout.title, systemImage: AppTab.workout.iconName)
                }
                .tag(AppTab.workout)

                // Tab 2: Exercises Library
                NavigationStack(path: $coord.exercisesPath) {
                    ExerciseListView()
                }
                .tabItem {
                    Label(AppTab.exercises.title, systemImage: AppTab.exercises.iconName)
                }
                .tag(AppTab.exercises)

                // Tab 3: Nutrition Tracker
                NavigationStack(path: $coord.nutritionPath) {
                    NutritionDashboardView()
                }
                .tabItem {
                    Label(AppTab.nutrition.title, systemImage: AppTab.nutrition.iconName)
                }
                .tag(AppTab.nutrition)

                // Tab 4: Coaching (PT Marketplace & Chat)
                NavigationStack(path: $coord.coachingPath) {
                    CoachMarketplaceView()
                }
                .tabItem {
                    Label(AppTab.coaching.title, systemImage: AppTab.coaching.iconName)
                }
                .tag(AppTab.coaching)

                // Tab 5: Profile & Analytics
                NavigationStack(path: $coord.profilePath) {
                    ProfileAnalyticsView()
                }
                .tabItem {
                    Label(AppTab.profile.title, systemImage: AppTab.profile.iconName)
                }
                .tag(AppTab.profile)
            }

            // 2. Mini-Player Bar nổi phía trên TabBar khi buổi tập đang chạy
            if coordinator.isWorkoutActive && !coordinator.showActiveWorkoutSheet {
                ActiveWorkoutMiniBar(
                    session: coordinator.activeWorkoutSession,
                    durationSeconds: coordinator.activeWorkoutDurationSeconds,
                    onTap: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            coordinator.maximizeWorkout()
                        }
                    },
                    onFinish: {
                        coordinator.endWorkout()
                    }
                )
                // Khoảng cách an toàn để nổi ngay trên thanh TabBar
                .padding(.bottom, 54)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        // 3. Fullscreen Cover mở toàn màn hình ActiveWorkoutView
        .fullScreenCover(isPresented: $coord.showActiveWorkoutSheet) {
            ActiveWorkoutView()
        }
        // 4. Sheet mở FormFit Pro Paywall
        .sheet(isPresented: $coord.showPaywall) {
            PaywallView()
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppNavigationCoordinator())
}
