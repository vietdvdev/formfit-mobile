import SwiftUI

/// Thanh Mini-Player Bar nổi phía trên TabBar hiển thị trạng thái buổi tập đang diễn ra
/// Cho phép người dùng chạm để mở lại toàn màn hình `ActiveWorkoutView`
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
            HStack(spacing: 12) {
                // Biểu tượng nhịp tập & vòng tròn loading nhịp nhàng
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)

                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.body.bold())
                        .foregroundStyle(.white)
                }

                // Thông tin tiến trình buổi tập
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentExerciseInfo.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        // Thời gian tập
                        HStack(spacing: 3) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 9))
                            Text(formattedTime)
                                .font(.caption2.monospacedDigit().bold())
                        }
                        .foregroundStyle(.blue)

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

                // Nút mở rộng fullscreen indicator
                Image(systemName: "chevron.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }
}
