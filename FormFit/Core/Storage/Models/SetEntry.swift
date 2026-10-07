import Foundation
import SwiftData

/// Model đại diện cho một hiệp tập (Set) đơn lẻ
@Model
public final class SetEntry {
    public var id: UUID
    public var setNumber: Int
    public var weightKg: Double
    public var reps: Int
    public var rpe: Double? // Rating of Perceived Exertion (1.0 -> 10.0)
    public var restTimeSeconds: Int
    public var isCompleted: Bool
    public var completedAt: Date?

    // Mối quan hệ ngược về bài tập cha
    public var workoutExercise: WorkoutExercise?

    public init(
        id: UUID = UUID(),
        setNumber: Int = 1,
        weightKg: Double = 20.0,
        reps: Int = 10,
        rpe: Double? = nil,
        restTimeSeconds: Int = 90,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.setNumber = setNumber
        self.weightKg = weightKg
        self.reps = reps
        self.rpe = rpe
        self.restTimeSeconds = restTimeSeconds
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
}
