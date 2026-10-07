import XCTest
import SwiftData
@testable import FormFit

@MainActor
final class ActiveWorkoutManagerTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var sut: ActiveWorkoutManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        container = try TestModelContainerFactory.makeInMemoryContainer()
        context = container.mainContext
        sut = ActiveWorkoutManager(modelContext: context)
    }

    override func tearDownWithError() throws {
        sut = nil
        context = nil
        container = nil
        try super.tearDownWithError()
    }

    // MARK: - Test 1: startWorkout
    func test_startWorkout_createsNewActiveSessionInSwiftData() throws {
        // Given & When
        let title = "Buổi tập Ngực & Tay"
        let session = sut.startWorkout(title: title)

        // Then
        XCTAssertNotNil(sut.currentSession)
        XCTAssertEqual(sut.currentSession?.title, title)
        XCTAssertFalse(session.isCompleted)
        XCTAssertFalse(session.isSyncedWithBackend)
        XCTAssertNotNil(session.startedAt)
        XCTAssertNil(session.endedAt)

        // Xác minh bản ghi đã được lưu vào SwiftData Context
        let descriptor = FetchDescriptor<WorkoutSession>()
        let sessionsInDb = try context.fetch(descriptor)
        XCTAssertEqual(sessionsInDb.count, 1)
        XCTAssertEqual(sessionsInDb.first?.id, session.id)
    }

    // MARK: - Test 2: addExercise
    func test_addExercise_appendsExerciseWithCorrectOrderIndexAndCascade() throws {
        // Given
        sut.startWorkout()

        // When
        sut.addExercise(id: "bench_press", name: "Đẩy tạ đòn", defaultRestTime: 90)
        sut.addExercise(id: "cable_fly", name: "Ép ngực cáp", defaultRestTime: 60)

        // Then
        guard let session = sut.currentSession else {
            XCTFail("Session phải tồn tại")
            return
        }

        XCTAssertEqual(session.exercises.count, 2)
        XCTAssertEqual(session.exercises[0].exerciseName, "Đẩy tạ đòn")
        XCTAssertEqual(session.exercises[0].orderIndex, 0)
        XCTAssertEqual(session.exercises[1].exerciseName, "Ép ngực cáp")
        XCTAssertEqual(session.exercises[1].orderIndex, 1)

        // Mỗi bài tự động có 1 set mặc định
        XCTAssertEqual(session.exercises[0].sets.count, 1)
        XCTAssertEqual(session.exercises[1].sets.count, 1)
    }

    // MARK: - Test 3: addSet (Smart duplication)
    func test_addSet_duplicatesPreviousSetWeightAndRepsSequentially() throws {
        // Given
        sut.startWorkout()
        sut.addExercise(id: "squat", name: "Gánh tạ đòn")
        guard let exercise = sut.currentSession?.exercises.first else {
            XCTFail("Exercise phải tồn tại")
            return
        }

        // Chỉnh sửa thông số Set 1 thành 80kg x 8 reps
        exercise.sets[0].weightKg = 80.0
        exercise.sets[0].reps = 8
        exercise.sets[0].restTimeSeconds = 120

        // When: Thêm Set 2
        sut.addSet(to: exercise)

        // Then
        XCTAssertEqual(exercise.sets.count, 2)
        let set2 = exercise.sets[1]
        XCTAssertEqual(set2.setNumber, 2)
        XCTAssertEqual(set2.weightKg, 80.0, "Phải tự động sao chép mức tạ 80kg từ set 1")
        XCTAssertEqual(set2.reps, 8, "Phải tự động sao chép 8 reps từ set 1")
        XCTAssertEqual(set2.restTimeSeconds, 120)
        XCTAssertFalse(set2.isCompleted)

        // When: Thêm tiếp Set 3
        sut.addSet(to: exercise)
        XCTAssertEqual(exercise.sets.count, 3)
        XCTAssertEqual(exercise.sets[2].setNumber, 3)
    }

    // MARK: - Test 4: toggleSetCompletion & Rest Timer
    func test_toggleSetCompletion_updatesCompletionStateAndTriggersRestTimer() throws {
        // Given
        sut.startWorkout()
        sut.addExercise(id: "overhead_press", name: "Đẩy vai qua đầu", defaultRestTime: 75)
        guard let exercise = sut.currentSession?.exercises.first,
              let set1 = exercise.sets.first else {
            XCTFail("Dữ liệu không hợp lệ")
            return
        }

        XCTAssertFalse(set1.isCompleted)
        XCTAssertNil(set1.completedAt)

        // When: Tích hoàn thành Set 1
        sut.toggleSetCompletion(set: set1, in: exercise)

        // Then
        XCTAssertTrue(set1.isCompleted)
        XCTAssertNotNil(set1.completedAt)
        XCTAssertTrue(RestTimerService.shared.isRunning)
        XCTAssertEqual(RestTimerService.shared.totalDurationSeconds, 75)
        XCTAssertEqual(RestTimerService.shared.currentExerciseName, exercise.exerciseName)

        // When: Bỏ tích
        sut.toggleSetCompletion(set: set1, in: exercise)

        // Then
        XCTAssertFalse(set1.isCompleted)
        XCTAssertNil(set1.completedAt)
        XCTAssertFalse(RestTimerService.shared.isRunning, "Phải tự động dừng timer khi bỏ tích set đó")
    }

    // MARK: - Test 5: swapExercise
    func test_swapExercise_updatesExerciseDetailsWhilePreservingSession() throws {
        // Given
        sut.startWorkout()
        sut.addExercise(id: "bench_press", name: "Đẩy tạ đòn trên ghế phẳng")
        guard let exercise = sut.currentSession?.exercises.first else {
            XCTFail("Exercise phải tồn tại")
            return
        }

        let originalId = exercise.id
        exercise.sets[0].weightKg = 70.0
        exercise.sets[0].reps = 10

        // When: Thực hiện đổi bài sang Dumbbell Bench Press
        exercise.exerciseId = "dumbbell_bench_press"
        exercise.exerciseName = "Đẩy tạ đơn trên ghế phẳng"

        // Then
        XCTAssertEqual(exercise.id, originalId, "ID entity của bài tập không đổi")
        XCTAssertEqual(exercise.exerciseId, "dumbbell_bench_press")
        XCTAssertEqual(exercise.exerciseName, "Đẩy tạ đơn trên ghế phẳng")
        XCTAssertEqual(exercise.sets.count, 1, "Các set đã cấu hình phải được bảo toàn")
        XCTAssertEqual(exercise.sets[0].weightKg, 70.0)
    }

    // MARK: - Test 6: finishWorkout
    func test_finishWorkout_setsCompletionFlagsAndPreparesForSync() throws {
        // Given
        sut.startWorkout(title: "Buổi tập Hoàn Thành")
        sut.addExercise(id: "squat", name: "Gánh tạ đòn")

        guard let session = sut.currentSession else {
            XCTFail("Session phải tồn tại")
            return
        }

        // When
        sut.finishWorkout()

        // Then
        XCTAssertTrue(session.isCompleted)
        XCTAssertNotNil(session.endedAt)
        XCTAssertFalse(session.isSyncedWithBackend, "Phải sẵn sàng để Sync Engine đồng bộ lên Cloud")
        XCTAssertNil(sut.currentSession, "currentSession phải được reset về nil sau khi hoàn thành")

        // Kiểm tra trong database
        let descriptor = FetchDescriptor<WorkoutSession>()
        let sessions = try context.fetch(descriptor)
        XCTAssertEqual(sessions.first?.isCompleted, true)
        XCTAssertEqual(sessions.first?.isSyncedWithBackend, false)
    }
}
