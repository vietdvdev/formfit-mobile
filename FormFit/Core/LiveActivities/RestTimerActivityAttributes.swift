import Foundation
import ActivityKit

/// Thuộc tính ActivityAttributes đại diện cho Live Activity và Dynamic Island đếm ngược thời gian nghỉ
public struct RestTimerActivityAttributes: ActivityAttributes {
    
    // MARK: - Dữ liệu tĩnh (Static Data) - Không thay đổi trong suốt chu kỳ của hiệp nghỉ
    public let exerciseName: String      // Tên bài tập vừa hoàn thành (ví dụ: "Barbell Bench Press")
    public let nextSetNumber: Int        // Set kế tiếp (ví dụ: 2)
    public let targetReps: Int           // Số rep mục tiêu (ví dụ: 10)
    public let targetWeightKg: Double    // Khối lượng tạ set tới (ví dụ: 80.0)

    public init(
        exerciseName: String,
        nextSetNumber: Int,
        targetReps: Int,
        targetWeightKg: Double
    ) {
        self.exerciseName = exerciseName
        self.nextSetNumber = nextSetNumber
        self.targetReps = targetReps
        self.targetWeightKg = targetWeightKg
    }

    // MARK: - Dữ liệu động (Dynamic Content State) - Cập nhật theo thời gian hoặc khi bấm +30s / Pause
    public struct ContentState: Codable, Hashable, Sendable {
        public var endTime: Date                   // Mốc thời gian kết thúc đếm ngược (để SwiftUI Text(style: .timer) tự render)
        public var totalRestDuration: TimeInterval // Tổng thời gian nghỉ ban đầu (ví dụ: 90 giây)
        public var isPaused: Bool

        public init(
            endTime: Date,
            totalRestDuration: TimeInterval,
            isPaused: Bool = false
        ) {
            self.endTime = endTime
            self.totalRestDuration = totalRestDuration
            self.isPaused = isPaused
        }
    }
}
