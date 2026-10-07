import SwiftUI
import WidgetKit
import ActivityKit

/// Widget Live Activity hiển thị trên Dynamic Island và Màn hình khóa (Lock Screen)
public struct RestTimerActivityWidget: Widget {
    public init() {}

    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestTimerActivityAttributes.self) { context in
            // MARK: - Lock Screen & Banner View
            lockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            // MARK: - Dynamic Island Presentations
            DynamicIsland {
                // 1. Expanded View (Khi chạm giữ Dynamic Island)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "dumbbell.fill")
                            .foregroundStyle(.cyan)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.state.exerciseName)
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text("Vừa xong: Hiệp \(context.state.currentSetNumber)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.leading, 8)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                            .font(.system(.title3, design: .monospaced).bold())
                            .foregroundStyle(.cyan)

                        Text("Tiếp: Hiệp \(context.state.nextSetNumber)")
                            .font(.caption2.bold())
                            .foregroundStyle(.orange)
                    }
                    .padding(.trailing, 8)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        // Thanh Progress thời gian nghỉ
                        ProgressView(
                            timerInterval: Date()...context.state.endTime,
                            countsDown: true
                        )
                        .tint(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                        HStack {
                            Text("Nghỉ ngơi lấy lại năng lượng")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Label("FormFit", systemImage: "figure.strengthtraining.traditional")
                                .font(.caption2.bold())
                                .foregroundStyle(.cyan)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
                }
            } compactLeading: {
                // 2. Compact Leading (Phía trái Dynamic Island nhỏ)
                Image(systemName: "dumbbell.fill")
                    .font(.caption2)
                    .foregroundStyle(.cyan)
            } compactTrailing: {
                // 3. Compact Trailing (Phía phải Dynamic Island nhỏ: đếm ngược số giây)
                Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                    .font(.caption2.monospacedDigit().bold())
                    .foregroundStyle(.cyan)
                    .frame(width: 44)
            } minimal: {
                // 4. Minimal (Khi có nhiều Live Activities cùng chạy)
                Image(systemName: "dumbbell.fill")
                    .font(.caption2)
                    .foregroundStyle(.cyan)
            }
        }
    }

    // MARK: - Lock Screen Presentation View
    private func lockScreenLiveActivityView(context: ActivityViewContext<RestTimerActivityAttributes>) -> some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                // Icon tạ tròn
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "dumbbell.fill")
                        .font(.title3)
                        .foregroundStyle(.cyan)
                }

                // Chi tiết bài tập và hiệp
                VStack(alignment: .leading, spacing: 3) {
                    Text(context.state.exerciseName)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text("Vừa xong Hiệp \(context.state.currentSetNumber)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Hiệp kế: \(context.state.nextSetNumber)")
                            .font(.caption.bold())
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()

                // Bộ đếm ngược thời gian lớn
                VStack(alignment: .trailing, spacing: 2) {
                    Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                        .font(.system(.title2, design: .monospaced).bold())
                        .foregroundStyle(.cyan)

                    Text("NGHỈ GIỮA HIỆP")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }

            // Thanh Progress đếm ngược tự động theo thời gian thực của iOS
            ProgressView(
                timerInterval: Date()...context.state.endTime,
                countsDown: true
            )
            .tint(
                LinearGradient(
                    colors: [.cyan, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .padding(16)
        .background(Color(uiColor: .systemBackground).opacity(0.85))
    }
}
