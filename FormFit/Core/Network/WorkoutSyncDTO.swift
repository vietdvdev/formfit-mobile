import Foundation

// MARK: - Request DTOs
public struct WorkoutSyncPayload: Codable, Sendable {
    public let sessions: [WorkoutSessionDTO]

    public init(sessions: [WorkoutSessionDTO]) {
        self.sessions = sessions
    }
}

public struct WorkoutSessionDTO: Codable, Sendable {
    public let localId: String
    public let title: String
    public let startedAt: String
    public let endedAt: String?
    public let note: String?
    public let exercises: [WorkoutExerciseDTO]

    public init(
        localId: String,
        title: String,
        startedAt: String,
        endedAt: String?,
        note: String?,
        exercises: [WorkoutExerciseDTO]
    ) {
        self.localId = localId
        self.title = title
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.note = note
        self.exercises = exercises
    }
}

public struct WorkoutExerciseDTO: Codable, Sendable {
    public let localId: String
    public let exerciseId: String
    public let exerciseName: String
    public let orderIndex: Int
    public let sets: [WorkoutSetDTO]

    public init(
        localId: String,
        exerciseId: String,
        exerciseName: String,
        orderIndex: Int,
        sets: [WorkoutSetDTO]
    ) {
        self.localId = localId
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.orderIndex = orderIndex
        self.sets = sets
    }
}

public struct WorkoutSetDTO: Codable, Sendable {
    public let localId: String
    public let setNumber: Int
    public let weightKg: Double
    public let reps: Int
    public let rpe: Double?
    public let restTimeSeconds: Int
    public let isCompleted: Bool
    public let completedAt: String?

    public init(
        localId: String,
        setNumber: Int,
        weightKg: Double,
        reps: Int,
        rpe: Double?,
        restTimeSeconds: Int,
        isCompleted: Bool,
        completedAt: String?
    ) {
        self.localId = localId
        self.setNumber = setNumber
        self.weightKg = weightKg
        self.reps = reps
        self.rpe = rpe
        self.restTimeSeconds = restTimeSeconds
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
}

// MARK: - Response DTOs
public struct WorkoutSyncResponse: Codable, Sendable {
    public let success: Bool
    public let message: String
    public let syncedSessionIds: [String]
}
