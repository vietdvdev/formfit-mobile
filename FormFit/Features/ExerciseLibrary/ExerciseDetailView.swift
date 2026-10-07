import SwiftUI

/// Màn hình chi tiết bài tập tích hợp trình chiếu 3D (Exercise3DViewer) và hướng dẫn kỹ thuật từng bước
public struct ExerciseDetailView: View {
    public let exercise: ExerciseItem

    public init(exercise: ExerciseItem) {
        self.exercise = exercise
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. Trình mô phỏng 3D Anatomy & tương tác cử chỉ
                Exercise3DViewer(
                    remoteModelURL: exercise.model3DRemoteURL,
                    targetMuscleGroups: exercise.targetMeshNodeNames,
                    customHighlightColor: .red
                )
                .frame(height: 360)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 24) {
                    // 2. Tiêu đề bài tập & Thông tin tổng quan
                    exerciseHeaderSection

                    Divider()

                    // 3. Phân bổ các nhóm cơ tác động
                    musclesTargetSection

                    Divider()

                    // 4. Hướng dẫn kỹ thuật từng bước (Step-by-step)
                    stepByStepInstructionsSection

                    // 5. Lỗi sai phổ biến cần tránh (Common Mistakes)
                    if !exercise.commonMistakes.isEmpty {
                        Divider()
                        commonMistakesSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    private var exerciseHeaderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.name)
                .font(.title2.bold())
                .foregroundStyle(.primary)

            Text(exercise.englishName)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                // Badge Dụng cụ
                HStack(spacing: 4) {
                    Image(systemName: exercise.equipment.badgeIcon)
                    Text(exercise.equipment.rawValue)
                }
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.blue.opacity(0.12), in: Capsule())
                .foregroundStyle(.blue)

                // Badge Độ khó
                Text(exercise.difficulty.rawValue)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.12), in: Capsule())
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
    }

    private var musclesTargetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Nhóm cơ tác động", systemImage: "figure.walk")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Cơ mục tiêu chính:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(exercise.primaryMuscle.rawValue)
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                }

                if !exercise.secondaryMuscles.isEmpty {
                    HStack(alignment: .top) {
                        Text("Cơ phụ hỗ trợ:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(exercise.secondaryMuscles.joined(separator: ", "))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var stepByStepInstructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Hướng dẫn kỹ thuật chuẩn", systemImage: "list.number")
                .font(.headline)

            VStack(spacing: 12) {
                ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(Color.blue))

                        Text(step)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private var commonMistakesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Lỗi sai phổ biến cần tránh", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            VStack(spacing: 10) {
                ForEach(exercise.commonMistakes, id: \.self) { mistake in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .padding(.top, 2)

                        Text(mistake)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }
}
