import Foundation
import AppIntents
import ActivityKit

/// App Intent cho phép bấm nút "+30s" trực tiếp trên Lock Screen hoặc Expanded Dynamic Island
public struct AddRestTimeIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Cộng 30 Giây Nghỉ"
    public static var description = IntentDescription("Cộng thêm 30 giây vào đồng hồ đếm ngược giờ nghỉ hiện tại.")

    @Parameter(title: "Thời gian cộng (giây)", default: 30)
    public var secondsToAdd: Double

    public init() {
        self.secondsToAdd = 30
    }

    public init(secondsToAdd: Double) {
        self.secondsToAdd = secondsToAdd
    }

    public func perform() async throws -> some IntentResult {
        // Tìm kiếm Live Activity đang chạy thuộc loại RestTimerActivityAttributes
        for activity in Activity<RestTimerActivityAttributes>.activities {
            var updatedState = activity.content.state
            let newEndTime = updatedState.endTime.addingTimeInterval(secondsToAdd)
            updatedState.endTime = newEndTime
            updatedState.totalRestDuration += secondsToAdd

            let updatedContent = ActivityContent(
                state: updatedState,
                staleDate: newEndTime.addingTimeInterval(5)
            )

            await activity.update(updatedContent)
        }

        // Cập nhật ngầm service trên app chính
        await RestTimerActivityManager.shared.addTime(seconds: secondsToAdd)

        return .result()
    }
}

/// App Intent cho phép bấm nút "Bỏ qua (Skip)" trực tiếp trên Lock Screen hoặc Dynamic Island
public struct SkipRestTimerIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Bỏ Qua Thời Gian Nghỉ"
    public static var description = IntentDescription("Kết thúc thời gian nghỉ ngay lập tức và sẵn sàng cho hiệp tập tiếp theo.")

    public init() {}

    public func perform() async throws -> some IntentResult {
        // Kết thúc toàn bộ Live Activities của Rest Timer
        for activity in Activity<RestTimerActivityAttributes>.activities {
            let finalState = activity.content.state
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }

        // Dừng service và huỷ notification trên app
        await RestTimerActivityManager.shared.endActivity()

        return .result()
    }
}
