import Foundation
import UserNotifications
import AudioToolbox
import UIKit
import ActivityKit
import Observation

/// Service quản lý toàn diện bộ đếm giờ nghỉ (Rest Timer)
/// Tích hợp chặt chẽ với:
/// 1. Bộ đếm ngược thời gian thực (Swift Concurrency Task)
/// 2. Local Notifications & Audio/Haptics
/// 3. ActivityKit (Dynamic Island & Lock Screen Live Activities)
@Observable
@MainActor
public final class RestTimerService {
    // MARK: - Singleton
    public static let shared = RestTimerService()

    // MARK: - Observable States
    public private(set) var isRunning: Bool = false
    public private(set) var totalDurationSeconds: Int = 90
    public private(set) var remainingSeconds: Int = 90
    public private(set) var endTime: Date = Date()
    public private(set) var currentExerciseName: String = ""
    public private(set) var currentSetNumber: Int = 1
    public private(set) var nextSetNumber: Int = 2

    public var progress: Double {
        guard totalDurationSeconds > 0 else { return 0 }
        return Double(totalDurationSeconds - remainingSeconds) / Double(totalDurationSeconds)
    }

    // MARK: - Internal Properties
    private var timerTask: Task<Void, Never>?
    private var currentActivity: Activity<RestTimerActivityAttributes>?
    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {
        requestNotificationPermission()
    }

    // MARK: - Permission Setup
    public func requestNotificationPermission() {
        Task {
            do {
                _ = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                print("[RestTimerService] ⚠️ Không xin được quyền thông báo: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Timer Controls

    /// Khởi động bộ đếm giờ nghỉ ngay khi hoàn thành một set
    /// - Parameters:
    ///   - durationSeconds: Tổng thời gian nghỉ quy định (giây)
    ///   - exerciseName: Tên bài tập vừa hoàn thành
    ///   - completedSetNumber: Hiệp tập vừa xong
    public func startRestTimer(
        durationSeconds: Int,
        exerciseName: String,
        completedSetNumber: Int
    ) {
        stopRestTimer(cancelLiveActivity: false)

        self.isRunning = true
        self.totalDurationSeconds = max(5, durationSeconds)
        self.remainingSeconds = max(5, durationSeconds)
        self.endTime = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        self.currentExerciseName = exerciseName
        self.currentSetNumber = completedSetNumber
        self.nextSetNumber = completedSetNumber + 1

        // 1. Lên lịch Local Push Notification & Rung/Chuông khi hết giờ
        scheduleCompletionNotification(in: TimeInterval(remainingSeconds), exerciseName: exerciseName, nextSet: nextSetNumber)

        // 2. Kích hoạt Live Activity trên Dynamic Island & Lock Screen
        startOrUpdateLiveActivity()

        // 3. Khởi tạo vòng lặp đếm ngược thời gian
        timerTask = Task { [weak self] in
            while true {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self = self, !Task.isCancelled else { break }

                if self.remainingSeconds > 1 {
                    self.remainingSeconds -= 1
                    // Cập nhật Live Activity định kỳ mỗi 5s hoặc khi sắp hết giờ để tiết kiệm pin
                    if self.remainingSeconds % 5 == 0 || self.remainingSeconds <= 5 {
                        self.updateLiveActivityContent()
                    }
                } else {
                    self.remainingSeconds = 0
                    self.timerFinished()
                    break
                }
            }
        }
    }

    /// Cộng hoặc trừ thời gian nghỉ (ví dụ: +15s hoặc -15s)
    public func adjustTime(by deltaSeconds: Int) {
        guard isRunning else { return }

        let newRemaining = max(1, remainingSeconds + deltaSeconds)
        let diff = newRemaining - remainingSeconds
        self.remainingSeconds = newRemaining
        self.totalDurationSeconds = max(newRemaining, totalDurationSeconds + diff)
        self.endTime = Date().addingTimeInterval(TimeInterval(remainingSeconds))

        triggerHaptic(.light)

        // Cập nhật lại thông báo và Live Activity
        scheduleCompletionNotification(in: TimeInterval(remainingSeconds), exerciseName: currentExerciseName, nextSet: nextSetNumber)
        updateLiveActivityContent()
    }

    /// Bỏ qua (Skip) hoặc dừng bộ đếm ngay lập tức
    public func skipRestTimer() {
        triggerHaptic(.medium)
        stopRestTimer(cancelLiveActivity: true)
    }

    /// Hủy tác vụ đếm ngược
    public func stopRestTimer(cancelLiveActivity: Bool = true) {
        timerTask?.cancel()
        timerTask = nil
        self.isRunning = false

        cancelScheduledNotification()

        if cancelLiveActivity {
            endLiveActivity()
        }
    }

    // MARK: - Timer Completion Handler
    private func timerFinished() {
        self.isRunning = false
        triggerHaptic(.heavy)
        AudioServicesPlaySystemSound(1005) // Âm thanh hệ thống báo chuông ngắn gọn

        endLiveActivity()
    }

    // MARK: - Local Notification Scheduling
    private func scheduleCompletionNotification(in timeInterval: TimeInterval, exerciseName: String, nextSet: Int) {
        cancelScheduledNotification()

        guard timeInterval > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Hết giờ nghỉ! 💪"
        content.body = "Sẵn sàng cho hiệp \(nextSet) của bài \(exerciseName)."
        content.sound = UNNotificationSound.default
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "formfit_rest_timer_completion", content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                print("[RestTimerService] ⚠️ Lỗi thêm thông báo: \(error.localizedDescription)")
            }
        }
    }

    private func cancelScheduledNotification() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["formfit_rest_timer_completion"])
    }

    // MARK: - Live Activity Management (ActivityKit)
    private func startOrUpdateLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = RestTimerActivityAttributes(
            exerciseName: currentExerciseName,
            nextSetNumber: nextSetNumber,
            targetReps: 10,
            targetWeightKg: 0.0
        )
        let contentState = RestTimerActivityAttributes.ContentState(
            endTime: endTime,
            totalRestDuration: TimeInterval(totalDurationSeconds),
            isPaused: false
        )

        let activityContent = ActivityContent(state: contentState, staleDate: endTime.addingTimeInterval(10))

        if let activity = currentActivity {
            Task {
                await activity.update(activityContent)
            }
        } else {
            do {
                currentActivity = try Activity.request(
                    attributes: attributes,
                    content: activityContent,
                    pushType: nil
                )
            } catch {
                print("[RestTimerService] ⚠️ Không thể khởi tạo Live Activity: \(error.localizedDescription)")
            }
        }
    }

    private func updateLiveActivityContent() {
        guard let activity = currentActivity else { return }
        let contentState = RestTimerActivityAttributes.ContentState(
            endTime: endTime,
            totalRestDuration: TimeInterval(totalDurationSeconds),
            isPaused: false
        )

        Task {
            await activity.update(ActivityContent(state: contentState, staleDate: endTime.addingTimeInterval(10)))
        }
    }

    private func endLiveActivity() {
        guard let activity = currentActivity else { return }
        Task {
            let finalState = RestTimerActivityAttributes.ContentState(
                endTime: Date(),
                totalRestDuration: TimeInterval(totalDurationSeconds),
                isPaused: false
            )
            await activity.end(ActivityContent(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
            self.currentActivity = nil
        }
    }

    // MARK: - Haptic Helper
    private func triggerHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}
