import Foundation
import SwiftData

/// Factory tạo môi trường SwiftData In-Memory cô lập cho Unit & Integration Test
@MainActor
public final class TestModelContainerFactory {
    
    /// Khởi tạo ModelContainer hoàn toàn trên RAM (isStoredInMemoryOnly: true)
    public static func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            WorkoutSession.self,
            WorkoutExercise.self,
            SetEntry.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// Tiện ích dọn dẹp sạch toàn bộ dữ liệu trong context
    public static func resetContainer(context: ModelContext) throws {
        try context.delete(model: SetEntry.self)
        try context.delete(model: WorkoutExercise.self)
        try context.delete(model: WorkoutSession.self)
        try context.save()
    }

    /// Seed sẵn một WorkoutSession mẫu có 1 bài Bench Press với 3 set mẫu
    @discardableResult
    public static func seedSampleSession(
        context: ModelContext,
        isCompleted: Bool = false,
        isSynced: Bool = false
    ) throws -> WorkoutSession {
        let session = WorkoutSession(
            title: "Buổi tập Push Day Mẫu",
            startedAt: Date().addingTimeInterval(-3600),
            endedAt: isCompleted ? Date() : nil,
            isCompleted: isCompleted,
            isSyncedWithBackend: isSynced
        )
        context.insert(session)

        let exercise = WorkoutExercise(
            exerciseId: "bench_press",
            exerciseName: "Đẩy tạ đòn trên ghế phẳng",
            orderIndex: 0
        )
        exercise.workoutSession = session
        session.exercises.append(exercise)
        context.insert(exercise)

        let set1 = SetEntry(setNumber: 1, weightKg: 60.0, reps: 10, restTimeSeconds: 90, isCompleted: true, completedAt: Date().addingTimeInterval(-3000))
        let set2 = SetEntry(setNumber: 2, weightKg: 70.0, reps: 8, restTimeSeconds: 90, isCompleted: true, completedAt: Date().addingTimeInterval(-2400))
        let set3 = SetEntry(setNumber: 3, weightKg: 80.0, reps: 6, restTimeSeconds: 120, isCompleted: false)

        for s in [set1, set2, set3] {
            s.workoutExercise = exercise
            exercise.sets.append(s)
            context.insert(s)
        }

        try context.save()
        return session
    }
}
