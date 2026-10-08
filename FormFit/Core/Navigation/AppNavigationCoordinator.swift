import SwiftUI
import Observation
import SwiftData

/// Điều phối toàn bộ trạng thái điều hướng, NavigationPath cho từng tab,
/// Deep Linking, trạng thái buổi tập đang diễn ra và các Fullscreen Sheets
@Observable
@MainActor
public final class AppNavigationCoordinator {
    // MARK: - Selected Tab
    public var selectedTab: AppTab = .workout

    // MARK: - Tab-specific Navigation Paths (Hỗ trợ pop-to-root & deep link)
    public var workoutPath = NavigationPath()
    public var exercisesPath = NavigationPath()
    public var nutritionPath = NavigationPath()
    public var coachingPath = NavigationPath()
    public var profilePath = NavigationPath()

    // MARK: - Active Workout State
    public var isWorkoutActive: Bool = false
    public var activeWorkoutSession: WorkoutSession? = nil
    public var activeWorkoutDurationSeconds: Int = 0

    // MARK: - Fullscreen Modal Presentations
    public var showActiveWorkoutSheet: Bool = false
    public var showPaywall: Bool = false

    private var workoutTimerTask: Task<Void, Never>?

    public init() {}

    // MARK: - Tab Selection & Pop to Root
    public func selectTab(_ tab: AppTab) {
        if selectedTab == tab {
            // Khi người dùng bấm lại tab hiện tại -> Reset path về Root
            resetPath(for: tab)
        } else {
            selectedTab = tab
        }
    }

    public func resetPath(for tab: AppTab) {
        switch tab {
        case .workout:
            workoutPath = NavigationPath()
        case .exercises:
            exercisesPath = NavigationPath()
        case .nutrition:
            nutritionPath = NavigationPath()
        case .coaching:
            coachingPath = NavigationPath()
        case .profile:
            profilePath = NavigationPath()
        }
    }

    // MARK: - Active Workout Lifecycle Management

    /// Bắt đầu buổi tập và mở toàn màn hình
    public func startWorkout(session: WorkoutSession) {
        self.activeWorkoutSession = session
        self.isWorkoutActive = true
        self.activeWorkoutDurationSeconds = 0
        self.showActiveWorkoutSheet = true

        startTimer()
    }

    /// Thu nhỏ buổi tập xuống Mini-Player Bar
    public func minimizeWorkout() {
        self.showActiveWorkoutSheet = false
    }

    /// Mở lại buổi tập dạng toàn màn hình
    public func maximizeWorkout() {
        guard isWorkoutActive else { return }
        self.showActiveWorkoutSheet = true
    }

    /// Kết thúc buổi tập
    public func endWorkout() {
        self.isWorkoutActive = false
        self.showActiveWorkoutSheet = false
        self.activeWorkoutSession = nil
        self.activeWorkoutDurationSeconds = 0

        workoutTimerTask?.cancel()
        workoutTimerTask = nil
    }

    private func startTimer() {
        workoutTimerTask?.cancel()
        workoutTimerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { break }
                self.activeWorkoutDurationSeconds += 1
            }
        }
    }

    // MARK: - Deep Linking (formfit://exercises/{id} hoặc formfit://chat/{contract_id})
    public func handleDeepLink(url: URL) {
        guard let host = url.host else { return }

        switch host {
        case "workout":
            self.selectedTab = .workout

        case "exercises":
            self.selectedTab = .exercises
            // Nếu có exercise ID: formfit://exercises/bench_press
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            if let exerciseId = pathComponents.first {
                exercisesPath.append(exerciseId)
            }

        case "nutrition":
            self.selectedTab = .nutrition

        case "coaching", "chat":
            self.selectedTab = .coaching
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            if let contractIdStr = pathComponents.first, let contractId = Int(contractIdStr) {
                coachingPath.append(contractId)
            }

        case "paywall", "pro":
            self.showPaywall = true

        default:
            break
        }
    }
}
