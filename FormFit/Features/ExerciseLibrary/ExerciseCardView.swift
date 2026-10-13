import SwiftUI

/// Component Card hiển thị thông tin bài tập chuẩn thể thao công nghệ cao
/// Hỗ trợ: Gradient icon thumbnail, 3D Badge phát sáng, Tag nhóm cơ màu sắc và tương tác Pressable
public struct ExerciseCardView: View {
    public let exercise: ExerciseItem

    public init(exercise: ExerciseItem) {
        self.exercise = exercise
    }

    public var body: some View {
        HStack(spacing: 14) {
            // 1. Thumbnail / Icon bài tập với hiệu ứng gradient nổi bật
            ZStack {
                RoundedRectangle(cornerRadius: FFDesign.Radius.medium, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                FFDesign.Colors.electricBlue.opacity(0.18),
                                FFDesign.Colors.cyberPurple.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 74, height: 74)

                Image(systemName: exercise.thumbnailImageName)
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [FFDesign.Colors.electricBlue, FFDesign.Colors.cyberPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // 2. Thông tin chi tiết
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

                // 3. Badges: Nhóm cơ chính & Dụng cụ & 3D Tag
                HStack(spacing: 6) {
                    // Badge Nhóm cơ
                    HStack(spacing: 4) {
                        Circle()
                            .fill(FFDesign.Colors.vibrantOrange)
                            .frame(width: 6, height: 6)
                        Text(exercise.primaryMuscle.rawValue)
                            .font(.caption2.bold())
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(FFDesign.Colors.vibrantOrange.opacity(0.14), in: Capsule())
                    .foregroundStyle(FFDesign.Colors.vibrantOrange)

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

                    // Icon 3D Indicator phát sáng
                    HStack(spacing: 3) {
                        Image(systemName: "cube.transparent.fill")
                            .font(.system(size: 10))
                        Text("3D")
                            .font(.system(size: 9, weight: .black))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(FFDesign.Colors.electricBlue.opacity(0.12), in: Capsule())
                    .foregroundStyle(FFDesign.Colors.electricBlue)
                }
            }

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: FFDesign.Radius.medium, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        .ffPressable()
    }
}
