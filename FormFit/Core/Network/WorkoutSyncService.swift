import Foundation
import SwiftData
import Observation

/// Trạng thái đồng bộ hóa dữ liệu
public enum SyncStatus: Sendable, Equatable {
    case idle
    case syncing(pendingCount: Int)
    case success(lastSyncedAt: Date)
    case failed(errorDescription: String)
}

/// Service đồng bộ dữ liệu buổi tập từ SwiftData lên Laravel Backend RESTful API (/api/v1/workouts/sync)
/// Vận hành hoàn hảo theo mô hình Offline-First:
/// 1. Tự động lắng nghe kết nối mạng qua `NetworkMonitor` (NWPathMonitor).
/// 2. Truy vấn các `WorkoutSession` chưa đồng bộ (`isSyncedWithBackend == false` và `isCompleted == true`).
/// 3. Map sang JSON DTO chuẩn REST API.
/// 4. Thực thi POST request kèm Exponential Backoff Retry (1s -> 2s -> 4s -> 8s) khi gặp lỗi mạng/server 5xx.
/// 5. Cập nhật `isSyncedWithBackend = true` khi nhận HTTP 200 OK.
@Observable
@MainActor
public final class WorkoutSyncService {
    public static let shared = WorkoutSyncService()

    // MARK: - Observable States
    public private(set) var syncStatus: SyncStatus = .idle
    public private(set) var pendingSyncCount: Int = 0

    // MARK: - Configurations
    public var backendBaseURL: URL = URL(string: "https://api.formfit.app/api/v1")!
    public var authToken: String? = nil

    private var modelContext: ModelContext?
    private var isSyncInProgress: Bool = false
    private let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private init() {
        setupNetworkObserver()
    }

    /// Gán ModelContext của SwiftData
    public func attachModelContext(_ context: ModelContext) {
        self.modelContext = context
        updatePendingCount()
    }

    // MARK: - Network Auto-trigger
    private func setupNetworkObserver() {
        Task { [weak self] in
            // Quan sát trạng thái kết nối mạng, khi có mạng trở lại thì kích hoạt sync ngầm
            for await _ in AsyncStream<Void>(unfolding: {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // Kiểm tra mỗi 3 giây
                return ()
            }) {
                guard let self = self else { break }
                if NetworkMonitor.shared.isConnected && !self.isSyncInProgress && self.pendingSyncCount > 0 {
                    await self.triggerSync()
                }
            }
        }
    }

    // MARK: - Query Pending Sessions
    public func updatePendingCount() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.isCompleted == true && session.isSyncedWithBackend == false
            }
        )

        do {
            let count = try context.fetchCount(descriptor)
            self.pendingSyncCount = count
        } catch {
            print("[WorkoutSyncService] ⚠️ Lỗi đếm bản ghi chưa đồng bộ: \(error.localizedDescription)")
        }
    }

    // MARK: - Main Sync Logic with Exponential Backoff

    /// Kích hoạt chu trình đồng bộ hóa
    public func triggerSync() async {
        guard !isSyncInProgress else { return }
        guard NetworkMonitor.shared.isConnected else {
            self.syncStatus = .failed(errorDescription: "Không có kết nối Internet.")
            return
        }
        guard let context = modelContext else {
            self.syncStatus = .failed(errorDescription: "Chưa cấu hình ModelContext.")
            return
        }

        // 1. Lấy danh sách các session cần sync
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.isCompleted == true && session.isSyncedWithBackend == false
            },
            sortBy: [SortDescriptor(\WorkoutSession.startedAt, order: .forward)]
        )

        let pendingSessions: [WorkoutSession]
        do {
            pendingSessions = try context.fetch(descriptor)
        } catch {
            self.syncStatus = .failed(errorDescription: "Lỗi truy vấn SwiftData: \(error.localizedDescription)")
            return
        }

        guard !pendingSessions.isEmpty else {
            self.pendingSyncCount = 0
            self.syncStatus = .idle
            return
        }

        self.isSyncInProgress = true
        self.pendingSyncCount = pendingSessions.count
        self.syncStatus = .syncing(pendingCount: pendingSessions.count)

        // 2. Map dữ liệu sang JSON DTO Payload
        let payload = mapToPayload(sessions: pendingSessions)

        // 3. Gửi HTTP Request kèm cơ chế Exponential Backoff
        do {
            let response = try await uploadPayloadWithRetry(payload: payload, maxRetries: 4)
            
            // 4. Cập nhật isSyncedWithBackend = true cho các session đã sync thành công
            let syncedIdSet = Set(response.syncedSessionIds)
            for session in pendingSessions {
                if syncedIdSet.contains(session.id.uuidString) || response.syncedSessionIds.isEmpty {
                    session.isSyncedWithBackend = true
                }
            }

            try context.save()
            updatePendingCount()
            self.syncStatus = .success(lastSyncedAt: Date())
            print("[WorkoutSyncService] ✅ Đồng bộ thành công \(pendingSessions.count) buổi tập lên server.")
        } catch {
            self.syncStatus = .failed(errorDescription: error.localizedDescription)
            print("[WorkoutSyncService] ❌ Đồng bộ thất bại sau khi thử lại: \(error.localizedDescription)")
        }

        self.isSyncInProgress = false
    }

    // MARK: - Exponential Backoff HTTP Execution
    private func uploadPayloadWithRetry(payload: WorkoutSyncPayload, maxRetries: Int) async throws -> WorkoutSyncResponse {
        let syncEndpoint = backendBaseURL.appendingPathComponent("workouts/sync")

        var request = URLRequest(url: syncEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let jsonData = try JSONEncoder().encode(payload)
        request.httpBody = jsonData

        var currentAttempt = 0
        var backoffDelayNanoseconds: UInt64 = 1_000_000_000 // 1 second

        while true {
            currentAttempt += 1
            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }

                // Nếu thành công (HTTP 200 OK hoặc 201 Created)
                if (200...299).contains(httpResponse.statusCode) {
                    if let decodedResponse = try? JSONDecoder().decode(WorkoutSyncResponse.self, from: data) {
                        return decodedResponse
                    } else {
                        // Fallback response nếu server trả format tóm tắt
                        return WorkoutSyncResponse(
                            success: true,
                            message: "Đồng bộ thành công",
                            syncedSessionIds: payload.sessions.map { $0.localId }
                        )
                    }
                }

                // Nếu lỗi server 5xx (Internal Server Error, Gateway Timeout...) hoặc rate limit 429
                if (httpResponse.statusCode >= 500 || httpResponse.statusCode == 429) && currentAttempt <= maxRetries {
                    print("[WorkoutSyncService] ⚠️ Gặp mã HTTP \(httpResponse.statusCode). Thử lại lần \(currentAttempt)/\(maxRetries) sau \(Double(backoffDelayNanoseconds) / 1_000_000_000.0)s...")
                    try await Task.sleep(nanoseconds: backoffDelayNanoseconds)
                    backoffDelayNanoseconds *= 2 // Nhân đôi thời gian chờ (1s -> 2s -> 4s -> 8s)
                    continue
                }

                throw NSError(
                    domain: "WorkoutSyncService",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "Server phản hồi mã lỗi HTTP \(httpResponse.statusCode)"]
                )
            } catch let error as URLError where isRecoverableNetworkError(error) && currentAttempt <= maxRetries {
                print("[WorkoutSyncService] ⚠️ Lỗi kết nối mạng: \(error.localizedDescription). Thử lại lần \(currentAttempt)/\(maxRetries)...")
                try await Task.sleep(nanoseconds: backoffDelayNanoseconds)
                backoffDelayNanoseconds *= 2
            } catch {
                if currentAttempt > maxRetries {
                    throw error
                }
            }
        }
    }

    private func isRecoverableNetworkError(_ error: URLError) -> Bool {
        switch error.code {
        case .timedOut, .cannotConnectToHost, .networkConnectionLost, .notConnectedToInternet, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }

    // MARK: - Mapping SwiftData -> REST JSON DTO
    private func mapToPayload(sessions: [WorkoutSession]) -> WorkoutSyncPayload {
        let sessionDTOs: [WorkoutSessionDTO] = sessions.map { session in
            let exerciseDTOs: [WorkoutExerciseDTO] = session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }).map { exercise in
                let setDTOs: [WorkoutSetDTO] = exercise.sets.sorted(by: { $0.setNumber < $1.setNumber }).map { set in
                    WorkoutSetDTO(
                        localId: set.id.uuidString,
                        setNumber: set.setNumber,
                        weightKg: set.weightKg,
                        reps: set.reps,
                        rpe: set.rpe,
                        restTimeSeconds: set.restTimeSeconds,
                        isCompleted: set.isCompleted,
                        completedAt: set.completedAt.map { isoDateFormatter.string(from: $0) }
                    )
                }

                return WorkoutExerciseDTO(
                    localId: exercise.id.uuidString,
                    exerciseId: exercise.exerciseId,
                    exerciseName: exercise.exerciseName,
                    orderIndex: exercise.orderIndex,
                    sets: setDTOs
                )
            }

            return WorkoutSessionDTO(
                localId: session.id.uuidString,
                title: session.title,
                startedAt: isoDateFormatter.string(from: session.startedAt),
                endedAt: session.endedAt.map { isoDateFormatter.string(from: $0) },
                note: session.note,
                exercises: exerciseDTOs
            )
        }

        return WorkoutSyncPayload(sessions: sessionDTOs)
    }
}
