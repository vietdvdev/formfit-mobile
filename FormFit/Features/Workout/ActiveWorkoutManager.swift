import Foundation
import SwiftData
import Observation
import UIKit

/// Trạng thái của bộ đếm giờ nghỉ (Rest Timer)
public struct RestTimerState: Equatable, Sendable {
    public var isRunning: Bool
    public var totalDurationSeconds: Int
    public var remainingSeconds: Int
    public var targetExerciseName: String?
    public var targetSetNumber: Int?

    public var progress: Double {
        guard totalDurationSeconds > 0 else { return 0 }
        return Double(totalDurationSeconds - remainingSeconds) / Double(totalDurationSeconds)
    }

    public init(
        isRunning: Bool = false,
        totalDurationSeconds: Int = 90,
        remainingSeconds: Int = 90,
        targetExerciseName: String? = nil,
        targetSetNumber: Int? = nil
    ) {
        self.isRunning = isRunning
        self.totalDurationSeconds = totalDurationSeconds
        self.remainingSeconds = remainingSeconds
        self.targetExerciseName = targetExerciseName
        self.targetSetNumber = targetSetNumber
    }
}

/// Observable class điều phối toàn bộ state machine của buổi tập đang diễn ra
/// Hỗ trợ kiến trúc Offline-First (lưu trực tiếp vào ModelContext của SwiftData)
@Observable
@MainActor
public final class ActiveWorkoutManager {
    // MARK: - Properties
    public var currentSession: WorkoutSession?
    public var restTimerState: RestTimerState = RestTimerState()

    private var modelContext: ModelContext?
    private var timerTask: Task<Void, Never>?

    // MARK: - Initialization
    public init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }

    /// Gán ModelContext (ví dụ truyền từ View qua @Environment(\.modelContext))
    public func attachModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Session Lifecycle

    /// Bắt đầu một buổi tập mới hoặc tiếp tục buổi tập chưa hoàn thành
    @discardableResult
    public func startWorkout(title: String = "Buổi tập ngày \(Date().formatted(date: .numeric, time: .omitted))") -> WorkoutSession {
        let session = WorkoutSession(
            title: title,
            startedAt: Date(),
            isCompleted: false,
            isSyncedWithBackend: false
        )
        
        self.currentSession = session
        
        if let context = modelContext {
            context.insert(session)
            saveChanges()
        }

        // Xin quyền và bắt đầu đọc nhịp tim thời gian thực từ Apple Watch
        Task {
            _ = await HealthKitManager.shared.requestAuthorization()
            HealthKitManager.shared.startHeartRateMonitoring()
        }

        return session
    }

    /// Kết thúc buổi tập hiện tại và đồng bộ vào Apple Health
    public func finishWorkout() {
        guard let session = currentSession else { return }
        let now = Date()
        session.endedAt = now
        session.isCompleted = true
        session.isSyncedWithBackend = false // Đánh dấu để Background Sync Engine đẩy lên server
        
        // 1. Dừng bộ đếm nghỉ và nhịp tim
        stopRestTimer()
        HealthKitManager.shared.stopHeartRateMonitoring()

        // 2. Lưu bản ghi HKWorkout vào Apple Health
        let duration = now.timeIntervalSince(session.startedAt)
        let estimatedCal = HealthKitManager.shared.estimateCaloriesBurned(durationSeconds: duration)

        Task {
            do {
                try await HealthKitManager.shared.saveStrengthWorkout(
                    startDate: session.startedAt,
                    endDate: now,
                    activeCalories: estimatedCal
                )
            } catch {
                print("[ActiveWorkoutManager] ⚠️ Lưu Apple Health thất bại (tiếp tục lưu cục bộ): \(error.localizedDescription)")
            }
        }
        
        saveChanges()
        self.currentSession = nil

        // 3. Tự động kích hoạt đồng bộ hóa dữ liệu lên máy chủ Laravel nếu có kết nối mạng
        Task {
            await WorkoutSyncService.shared.triggerSync()
        }
    }

    /// Hủy bỏ buổi tập đang diễn ra
    public func discardWorkout() {
        guard let session = currentSession else { return }
        stopRestTimer()
        HealthKitManager.shared.stopHeartRateMonitoring()
        
        if let context = modelContext {
            context.delete(session)
            saveChanges()
        }
        self.currentSession = nil
    }

    // MARK: - Exercise Management

    /// Thêm một bài tập mới vào buổi tập
    public func addExercise(id: String, name: String, defaultRestTime: Int = 90) {
        guard let session = currentSession else { return }

        let nextOrder = session.exercises.count
        let workoutExercise = WorkoutExercise(
            exerciseId: id,
            exerciseName: name,
            orderIndex: nextOrder
        )

        // Tự động khởi tạo Set đầu tiên làm mẫu
        let firstSet = SetEntry(
            setNumber: 1,
            weightKg: 20.0,
            reps: 10,
            rpe: nil,
            restTimeSeconds: defaultRestTime,
            isCompleted: false
        )
        firstSet.workoutExercise = workoutExercise
        workoutExercise.sets.append(firstSet)

        workoutExercise.workoutSession = session
        session.exercises.append(workoutExercise)

        if let context = modelContext {
            context.insert(workoutExercise)
            context.insert(firstSet)
            saveChanges()
        }
    }

    /// Xóa một bài tập khỏi buổi tập (Cascade tự động xóa các Set con)
    public func removeExercise(at offsets: IndexSet) {
        guard let session = currentSession else { return }

        for index in offsets {
            let exercise = session.exercises[index]
            if let context = modelContext {
                context.delete(exercise)
            }
        }
        session.exercises.remove(atOffsets: offsets)

        // Cập nhật lại orderIndex
        for (index, exercise) in session.exercises.enumerated() {
            exercise.orderIndex = index
        }

        saveChanges()
    }

    /// Xóa bài tập theo đối tượng cụ thể
    public func removeExercise(_ exercise: WorkoutExercise) {
        guard let session = currentSession else { return }
        if let index = session.exercises.firstIndex(where: { $0.id == exercise.id }) {
            removeExercise(at: IndexSet(integer: index))
        }
    }

    // MARK: - Set Management & Smart Duplication

    /// Thêm Set mới vào bài tập
    /// - Tự động nhân bản thông số tạ (weightKg) và số lần lặp (reps) từ Set liền trước đó
    public func addSet(to exercise: WorkoutExercise) {
        let currentSets = exercise.sets.sorted { $0.setNumber < $1.setNumber }
        let nextSetNumber = (currentSets.last?.setNumber ?? 0) + 1

        let defaultWeight: Double
        let defaultReps: Int
        let defaultRestTime: Int

        if let previousSet = currentSets.last {
            // Tự động nhân bản thông số từ set trước
            defaultWeight = previousSet.weightKg
            defaultReps = previousSet.reps
            defaultRestTime = previousSet.restTimeSeconds
        } else {
            defaultWeight = 20.0
            defaultReps = 10
            defaultRestTime = 90
        }

        let newSet = SetEntry(
            setNumber: nextSetNumber,
            weightKg: defaultWeight,
            reps: defaultReps,
            rpe: nil,
            restTimeSeconds: defaultRestTime,
            isCompleted: false
        )
        newSet.workoutExercise = exercise
        exercise.sets.append(newSet)

        if let context = modelContext {
            context.insert(newSet)
            saveChanges()
        }
    }

    /// Xóa một Set khỏi bài tập
    public func removeSet(_ set: SetEntry, from exercise: WorkoutExercise) {
        if let context = modelContext {
            context.delete(set)
        }
        exercise.sets.removeAll { $0.id == set.id }

        // Đánh lại số thứ tự setNumber
        let sortedSets = exercise.sets.sorted { $0.setNumber < $1.setNumber }
        for (index, item) in sortedSets.enumerated() {
            item.setNumber = index + 1
        }

        saveChanges()
    }

    /// Chuyển đổi trạng thái hoàn thành của Set (`toggleSetCompletion`)
    /// - Khi tích hoàn thành: Lưu thời điểm completedAt và kích hoạt Rest Timer qua RestTimerService & Live Activities
    /// - Khi bỏ tích: Reset thời điểm và dừng timer nếu đang đếm cho set đó
    public func toggleSetCompletion(set: SetEntry, in exercise: WorkoutExercise) {
        set.isCompleted.toggle()

        if set.isCompleted {
            set.completedAt = Date()
            triggerHapticFeedback(.success)

            // Kích hoạt bộ đếm giờ nghỉ liên kết chặt chẽ với Live Activity & Dynamic Island (ActivityKit)
            let nextSetNumber = set.setNumber + 1
            let nextWeight = set.weightKg
            let nextReps = set.reps

            Task {
                await RestTimerActivityManager.shared.startActivity(
                    exerciseName: exercise.exerciseName,
                    nextSet: nextSetNumber,
                    weight: nextWeight,
                    reps: nextReps,
                    duration: TimeInterval(set.restTimeSeconds)
                )
            }
        } else {
            set.completedAt = nil
            // Nếu timer đang chạy cho chính set này thì dừng lại
            if RestTimerActivityManager.shared.currentExerciseName == exercise.exerciseName &&
               RestTimerActivityManager.shared.currentNextSetNumber == (set.setNumber + 1) {
                Task {
                    await RestTimerActivityManager.shared.endActivity()
                }
            }
        }

        saveChanges()
    }

    // MARK: - Rest Timer Delegations
    public func addRestTime(seconds: Int = 15) {
        RestTimerService.shared.adjustTime(by: seconds)
    }

    public func subtractRestTime(seconds: Int = 15) {
        RestTimerService.shared.adjustTime(by: -seconds)
    }

    public func stopRestTimer() {
        RestTimerService.shared.skipRestTimer()
    }

    // MARK: - Helper Methods

    private func saveChanges() {
        guard let context = modelContext, context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("[ActiveWorkoutManager] ⚠️ Lỗi lưu dữ liệu SwiftData: \(error.localizedDescription)")
        }
    }

    private func triggerHapticFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    private func triggerHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}
