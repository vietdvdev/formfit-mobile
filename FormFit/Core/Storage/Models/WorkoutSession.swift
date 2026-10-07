import Foundation
import SwiftData

/// Model đại diện cho một buổi tập (Session) hoàn chỉnh
@Model
public final class WorkoutSession {
    public var id: UUID
    public var title: String
    public var startedAt: Date
    public var endedAt: Date?
    public var isCompleted: Bool
    public var isSyncedWithBackend: Bool
    public var note: String?

    // Relationship 1-N tới danh sách các bài tập trong buổi (Cascade delete)
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workoutSession)
    public var exercises: [WorkoutExercise]

    public init(
        id: UUID = UUID(),
        title: String = "Buổi tập mới",
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        isCompleted: Bool = false,
        isSyncedWithBackend: Bool = false,
        note: String? = nil,
        exercises: [WorkoutExercise] = []
    ) {
        self.id = id
        self.title = title
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.isCompleted = isCompleted
        self.isSyncedWithBackend = isSyncedWithBackend
        self.note = note
        self.exercises = exercises
    }
}
