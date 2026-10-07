import Foundation
import SwiftData

/// Model đại diện cho một bài tập nằm trong buổi tập
@Model
public final class WorkoutExercise {
    public var id: UUID
    public var exerciseId: String
    public var exerciseName: String
    public var orderIndex: Int

    // Relationship 1-N tới các hiệp tập (Cascade delete khi xóa bài tập)
    @Relationship(deleteRule: .cascade, inverse: \SetEntry.workoutExercise)
    public var sets: [SetEntry]

    // Mối quan hệ ngược về buổi tập cha
    public var workoutSession: WorkoutSession?

    public init(
        id: UUID = UUID(),
        exerciseId: String,
        exerciseName: String,
        orderIndex: Int = 0,
        sets: [SetEntry] = []
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.orderIndex = orderIndex
        self.sets = sets
    }
}
