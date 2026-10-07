import XCTest
import SwiftData
@testable import FormFit

@MainActor
final class WorkoutSyncServiceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var sut: WorkoutSyncService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        container = try TestModelContainerFactory.makeInMemoryContainer()
        context = container.mainContext

        sut = WorkoutSyncService.shared
        sut.attachModelContext(context)
        sut.backendBaseURL = URL(string: "https://api.formfit.app/api/v1")!

        // Đăng ký Mock URLProtocol cho URLSession mặc định
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    override func tearDownWithError() throws {
        MockURLProtocol.requestHandler = nil
        URLProtocol.unregisterClass(MockURLProtocol.self)
        sut = nil
        context = nil
        container = nil
        try super.tearDownWithError()
    }

    // MARK: - Test Case 1: Sync thành công - Online 200 OK
    func test_triggerSync_whenServerReturns200OK_marksSessionAsSynced() async throws {
        // Given: Seed 1 session đã hoàn thành nhưng chưa sync
        let session = try TestModelContainerFactory.seedSampleSession(
            context: context,
            isCompleted: true,
            isSynced: false
        )
        sut.updatePendingCount()
        XCTAssertEqual(sut.pendingSyncCount, 1)

        // Mock Server Response 200 OK
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/workouts/sync")
            XCTAssertEqual(request.httpMethod, "POST")

            let responseJSON = """
            {
                "success": true,
                "message": "Đồng bộ thành công",
                "syncedSessionIds": ["\(session.id.uuidString)"]
            }
            """
            let data = responseJSON.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, data)
        }

        // When
        await sut.triggerSync()

        // Then
        XCTAssertTrue(session.isSyncedWithBackend, "Bản ghi phải được chuyển sang isSyncedWithBackend = true")
        XCTAssertEqual(sut.pendingSyncCount, 0)
        if case .success = sut.syncStatus {
            // Success state đúng mong đợi
        } else {
            XCTFail("Trạng thái syncStatus phải là .success")
        }
    }

    // MARK: - Test Case 2: Mất kết nối - Offline / Network Failure
    func test_triggerSync_whenNetworkDisconnected_retainsLocalDataWithoutCrash() async throws {
        // Given: Seed 1 session chưa sync
        let session = try TestModelContainerFactory.seedSampleSession(
            context: context,
            isCompleted: true,
            isSynced: false
        )
        sut.updatePendingCount()

        // Mock Network Failure: mất kết nối internet
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        // When
        await sut.triggerSync()

        // Then
        XCTAssertFalse(session.isSyncedWithBackend, "Dữ liệu SwiftData phải giữ nguyên isSyncedWithBackend = false")
        XCTAssertEqual(session.exercises.count, 1, "Dữ liệu bài tập không bị mất mát")
        if case .failed = sut.syncStatus {
            // Failed state đúng mong đợi
        } else {
            XCTFail("Trạng thái syncStatus phải phản ánh .failed để retry ngầm sau")
        }
    }

    // MARK: - Test Case 3: Lỗi Server 500 hoặc Dữ liệu không hợp lệ 422
    func test_triggerSync_whenServerReturns500InternalError_handlesGracefullyAndRetainsPendingState() async throws {
        // Given
        let session = try TestModelContainerFactory.seedSampleSession(
            context: context,
            isCompleted: true,
            isSynced: false
        )
        sut.updatePendingCount()

        // Mock Server 500 Error
        MockURLProtocol.requestHandler = { request in
            let errorJSON = """
            {
                "success": false,
                "message": "Internal Server Error"
            }
            """
            let data = errorJSON.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, data)
        }

        // When
        await sut.triggerSync()

        // Then
        XCTAssertFalse(session.isSyncedWithBackend, "Không được đánh dấu hoàn thành sync khi gặp lỗi 500")
        XCTAssertEqual(sut.pendingSyncCount, 1, "Vẫn giữ nguyên 1 bản ghi chờ đồng bộ")
        if case .failed = sut.syncStatus {
            // Pass
        } else {
            XCTFail("Trạng thái syncStatus phải là .failed")
        }
    }
}
