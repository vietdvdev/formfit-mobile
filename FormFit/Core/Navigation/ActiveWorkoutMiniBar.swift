import SwiftUI

/// Thanh Mini-Player Bar nổi phía trên TabBar hiển thị trạng thái buổi tập đang diễn ra
/// Được nâng cấp giao diện Glassmorphism cao cấp, viền Neon phát sáng nhịp tim và nút mở rộng mượt mà
public struct ActiveWorkoutMiniBar: View {
    public let session: WorkoutSession?
    public let durationSeconds: Int
    public let onTap: () -> Void
    public let onFinish: () -> Void

    public init(
        session: WorkoutSession?,
        durationSeconds: Int,
        onTap: @escaping () -> Void,
        onFinish: @escaping () -> Void
    ) {
        self.session = session
        self.durationSeconds = durationSeconds
        self.onTap = onTap
        self.onFinish = onFinish
    }

    private var formattedTime: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var currentExerciseInfo: (name: String, completedSets: Int, totalSets: Int) {
        guard let s = session, let currentExercise = s.exercises.last else {
            return ("Đang tập luyện", 0, 0)
        }
        let completed = currentExercise.sets.filter { $0.isCompleted }.count
        let total = currentExercise.sets.count
        return (currentExercise.exerciseName, completed, total)
    }

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Biểu tượng tạ với viền Neon Gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [FFDesign.Colors.primaryNeon, FFDesign.Colors.electricBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.body.bold())
                        .foregroundStyle(.white)
                }

                // Thông tin tiến trình buổi tập
                VStack(alignment: .leading, spacing: 3) {
                    Text(currentExerciseInfo.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        // Thời gian tập
                        HStack(spacing: 3) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 9))
                            Text(formattedTime)
                                .font(.caption2.monospacedDigit().bold())
                        }
                        .foregroundStyle(FFDesign.Colors.primaryNeon)

                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        // Số hiệp đã xong
                        Text("Hiệp \(currentExerciseInfo.completedSets)/\(max(1, currentExerciseInfo.totalSets))")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Nút mở rộng fullscreen với animation nhẹ
                ZStack {
                    Circle()
                        .fill(FFDesign.Colors.primaryNeon.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "chevron.up")
                        .font(.caption.bold())
                        .foregroundStyle(FFDesign.Colors.primaryNeon)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [FFDesign.Colors.primaryNeon.opacity(0.4), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
        .ffPressable()
    }
}
