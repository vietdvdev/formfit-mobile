import Foundation
import ActivityKit
import UserNotifications
import AudioToolbox
import UIKit
import Observation

/// Controller Service quản lý toàn diện vòng đời Live Activity, Dynamic Island,
/// Local Notification hẹn giờ và phản hồi rung/âm thanh báo hết hiệp nghỉ
@Observable
@MainActor
public final class RestTimerActivityManager {
    public static let shared = RestTimerActivityManager()

    // MARK: - Observable States
    public private(set) var isActivityRunning: Bool = false
    public private(set) var currentEndTime: Date = Date()
    public private(set) var currentTotalDuration: TimeInterval = 90
    public private(set) var currentExerciseName: String = ""
    public private(set) var currentNextSetNumber: Int = 1
    public private(set) var currentTargetWeightKg: Double = 0.0
    public private(set) var currentTargetReps: Int = 0

    private var activeActivity: Activity<RestTimerActivityAttributes>?
    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {
        requestNotificationPermission()
    }

    private func requestNotificationPermission() {
        Task {
            do {
                _ = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                print("[RestTimerActivityManager] ⚠️ Lỗi xin quyền notification: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 1. Start Activity
    /// Khởi tạo hoặc thay thế Live Activity khi hoàn thành một set
    public func startActivity(
        exerciseName: String,
        nextSet: Int,
        weight: Double,
        reps: Int,
        duration: TimeInterval
    ) async {
        // Kiểm tra quyền kích hoạt Live Activity từ iOS Settings
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("[RestTimerActivityManager] ⚠️ Người dùng chưa bật Live Activities trong Cài đặt.")
            return
        }

        // Hủy các activity cũ đang chạy để tránh trùng lặp
        await endActivity(dismissalPolicy: .immediate)

        let targetDuration = max(5, duration)
        let targetEndTime = Date().addingTimeInterval(targetDuration)

        self.currentExerciseName = exerciseName
        self.currentNextSetNumber = nextSet
        self.currentTargetWeightKg = weight
        self.currentTargetReps = reps
        self.currentTotalDuration = targetDuration
        self.currentEndTime = targetEndTime
        self.isActivityRunning = true

        let attributes = RestTimerActivityAttributes(
            exerciseName: exerciseName,
            nextSetNumber: nextSet,
            targetReps: reps,
            targetWeightKg: weight
        )

        let initialContentState = RestTimerActivityAttributes.ContentState(
            endTime: targetEndTime,
            totalRestDuration: targetDuration,
            isPaused: false
        )

        let activityContent = ActivityContent(
            state: initialContentState,
            staleDate: targetEndTime.addingTimeInterval(5)
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: activityContent,
                pushType: nil
            )
            self.activeActivity = activity
            print("[RestTimerActivityManager] ✅ Đã kích hoạt Live Activity ID: \(activity.id)")

            // Lập lịch thông báo báo hết giờ kèm âm thanh và rung
            scheduleNotification(for: targetEndTime, exerciseName: exerciseName, nextSet: nextSet)
        } catch {
            print("[RestTimerActivityManager] ⚠️ Lỗi khởi tạo Live Activity: \(error.localizedDescription)")
        }
    }

    // MARK: - 2. Add Time (+30s)
    /// Cộng thêm thời gian nghỉ vào Live Activity và đẩy lùi mốc notification
    public func addTime(seconds: TimeInterval) async {
        guard isActivityRunning, let activity = activeActivity else { return }

        let newEndTime = currentEndTime.addingTimeInterval(seconds)
        let newTotalDuration = currentTotalDuration + seconds

        self.currentEndTime = newEndTime
        self.currentTotalDuration = newTotalDuration

        var updatedState = activity.content.state
        updatedState.endTime = newEndTime
        updatedState.totalRestDuration = newTotalDuration

        let updatedContent = ActivityContent(
            state: updatedState,
            staleDate: newEndTime.addingTimeInterval(5)
        )

        await activity.update(updatedContent)

        // Rung phản hồi nhẹ
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()

        // Lập lịch lại notification với mốc endTime mới
        scheduleNotification(for: newEndTime, exerciseName: currentExerciseName, nextSet: currentNextSetNumber)
    }

    // MARK: - 3. End Activity
    /// Kết thúc Live Activity
    public func endActivity(dismissalPolicy: ActivityUIDismissalPolicy = .immediate) async {
        cancelScheduledNotification()

        self.isActivityRunning = false

        if let activity = activeActivity {
            let finalState = activity.content.state
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: dismissalPolicy
            )
            self.activeActivity = nil
        }

        // Dọn sạch bất kỳ activities nào còn sót lại
        for act in Activity<RestTimerActivityAttributes>.activities {
            let finalState = act.content.state
            await act.end(ActivityContent(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        }
    }

    // MARK: - 4. Background Notification & Haptic Scheduling
    private func scheduleNotification(for targetDate: Date, exerciseName: String, nextSet: Int) {
        cancelScheduledNotification()

        let interval = targetDate.timeIntervalSinceNow
        guard interval > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Hết giờ nghỉ! 💪"
        content.body = "Sẵn sàng vào Hiệp \(nextSet) của bài \(exerciseName)."
        content.sound = UNNotificationSound.defaultCritical // Âm thanh nổi bật
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "formfit_rest_timer_alert",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("[RestTimerActivityManager] ⚠️ Lỗi lập lịch thông báo: \(error.localizedDescription)")
            }
        }
    }

    private func cancelScheduledNotification() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["formfit_rest_timer_alert"])
    }
}
