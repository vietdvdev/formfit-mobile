import SwiftUI

/// Component Card hiển thị thông tin tóm tắt của 1 bài tập trong thư viện
public struct ExerciseCardView: View {
    public let exercise: ExerciseItem

    public init(exercise: ExerciseItem) {
        self.exercise = exercise
    }

    public var body: some View {
        HStack(spacing: 14) {
            // Thumbnail / Icon mô phỏng bài tập
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.12), Color.purple.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 74, height: 74)

                Image(systemName: exercise.thumbnailImageName)
                    .font(.system(size: 30))
                    .foregroundStyle(.blue)
            }

            // Thông tin chi tiết
            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(exercise.englishName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // Badges: Nhóm cơ chính & Dụng cụ tập
                HStack(spacing: 6) {
                    // Badge Nhóm cơ
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 6, height: 6)
                        Text(exercise.primaryMuscle.rawValue)
                            .font(.caption2.bold())
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.12), in: Capsule())
                    .foregroundStyle(.orange)

                    // Badge Dụng cụ
                    HStack(spacing: 4) {
                        Image(systemName: exercise.equipment.badgeIcon)
                            .font(.system(size: 9))
                        Text(exercise.equipment.shortName)
                            .font(.caption2.weight(.medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.12), in: Capsule())
                    .foregroundStyle(.secondary)

                    Spacer()

                    // Icon 3D Indicator
                    Image(systemName: "cube.transparent")
                        .font(.caption)
                        .foregroundStyle(.blue.opacity(0.8))
                }
            }

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 3)
    }
}
