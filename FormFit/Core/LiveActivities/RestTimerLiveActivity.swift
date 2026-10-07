import SwiftUI
import WidgetKit
import ActivityKit
import AppIntents

/// Widget Live Activity hiển thị giao diện đếm ngược thời gian nghỉ trên Dynamic Island & Lock Screen
public struct RestTimerLiveActivity: Widget {
    public init() {}

    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestTimerActivityAttributes.self) { context in
            // MARK: - Lock Screen & StandBy Banner UI
            lockScreenBannerView(context: context)
        } dynamicIsland: { context in
            // MARK: - Dynamic Island Presentations
            DynamicIsland {
                // 1. Expanded Leading (Góc trên bên trái khi mở rộng)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.cyan.opacity(0.2))
                                .frame(width: 38, height: 38)
                            Image(systemName: "dumbbell.fill")
                                .font(.body.bold())
                                .foregroundStyle(.cyan)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("REST TIMER")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.cyan)
                            Text(context.attributes.exerciseName)
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        }
                    }
                    .padding(.leading, 6)
                }

                // 2. Expanded Trailing (Đồng hồ đếm lùi lớn bên phải)
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                            .font(.system(.title2, design: .monospaced).bold())
                            .foregroundStyle(.cyan)

                        Text("Thời gian nghỉ")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.trailing, 6)
                }

                // 3. Expanded Bottom (Thông tin set kế tiếp + Progress + Nút bấm Interactive App Intents)
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 10) {
                        // Thông tin hiệp kế tiếp
                        HStack {
                            Text("Next: Set \(context.attributes.nextSetNumber) • \(String(format: "%.1f", context.attributes.targetWeightKg))kg × \(context.attributes.targetReps) reps")
                                .font(.caption.bold())
                                .foregroundStyle(.orange)

                            Spacer()

                            Label("FormFit", systemImage: "bolt.fill")
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                        }

                        // Thanh ProgressView tự động chạy tiến trình theo mốc thời gian của iOS
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

                        // Nút tương tác nhanh (Interactive App Intents)
                        HStack(spacing: 12) {
                            // Nút +30s
                            Button(intent: AddRestTimeIntent(secondsToAdd: 30)) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("+30s")
                                }
                                .font(.caption.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                                .background(Color.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)

                            // Nút Skip Rest
                            Button(intent: SkipRestTimerIntent()) {
                                HStack(spacing: 4) {
                                    Image(systemName: "forward.fill")
                                    Text("Skip Rest")
                                }
                                .font(.caption.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                                .background(Color.cyan.opacity(0.25), in: RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(.cyan)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 4)
                }
            } compactLeading: {
                // 4. Compact Leading (Bên trái viên thuốc Dynamic Island)
                HStack(spacing: 3) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.cyan)

                    Text("S\(context.attributes.nextSetNumber)")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.white)
                }
                .padding(.leading, 4)
            } compactTrailing: {
                // 5. Compact Trailing (Bên phải viên thuốc: Text style .timer tự động đếm lùi)
                Text(context.state.endTime, style: .timer)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.cyan)
                    .frame(width: 42, alignment: .trailing)
                    .padding(.trailing, 4)
            } minimal: {
                // 6. Minimal (Khi có nhiều ứng dụng cùng hiển thị trên Dynamic Island)
                ZStack {
                    Image(systemName: "hourglass")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.cyan)
                }
            }
        }
    }

    // MARK: - Lock Screen & StandBy Banner UI
    private func lockScreenBannerView(context: ActivityViewContext<RestTimerActivityAttributes>) -> some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                // Biểu tượng tạ nổi bật
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.18))
                        .frame(width: 48, height: 48)
                    Image(systemName: "dumbbell.fill")
                        .font(.title3.bold())
                        .foregroundStyle(.cyan)
                }

                // Cột trái: Tên bài và preview set kế tiếp
                VStack(alignment: .leading, spacing: 3) {
                    Text(context.attributes.exerciseName)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text("Kế tiếp:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Set \(context.attributes.nextSetNumber) • \(String(format: "%.1f", context.attributes.targetWeightKg))kg × \(context.attributes.targetReps) reps")
                            .font(.caption.bold())
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()

                // Cột phải: Bộ đếm ngược thời gian
                VStack(alignment: .trailing, spacing: 2) {
                    Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                        .font(.system(.title2, design: .monospaced).bold())
                        .foregroundStyle(.cyan)

                    Text("NGHỈ GIỮA HIỆP")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }

            // Thanh Progress tự động đếm ngược
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

            // Nút bấm nhanh trên Màn hình khóa
            HStack(spacing: 12) {
                // Nút +30s
                Button(intent: AddRestTimeIntent(secondsToAdd: 30)) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("+30s")
                    }
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)

                // Nút Skip
                Button(intent: SkipRestTimerIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "forward.fill")
                        Text("Bỏ qua (Vào set)")
                    }
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.cyan.opacity(0.22), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.cyan)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.black.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
