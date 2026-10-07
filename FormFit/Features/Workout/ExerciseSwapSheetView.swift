import SwiftUI

/// Màn hình Sheet hiển thị các bài tập tương đương (Exercise Swap)
/// Lọc tự động các bài tập có cùng nhóm cơ chính và dụng cụ tương đương
public struct ExerciseSwapSheetView: View {
    public let currentExercise: WorkoutExercise
    public let allExercises: [ExerciseItem]
    public let onSelectSwap: (ExerciseItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchQuery: String = ""

    public init(
        currentExercise: WorkoutExercise,
        allExercises: [ExerciseItem] = MockExerciseData.sampleExercises,
        onSelectSwap: @escaping (ExerciseItem) -> Void
    ) {
        self.currentExercise = currentExercise
        self.allExercises = allExercises
        self.onSelectSwap = onSelectSwap
    }

    /// Tìm thông tin chi tiết của bài tập hiện tại trong catalog
    private var matchedCurrentItem: ExerciseItem? {
        allExercises.first { $0.name == currentExercise.exerciseName || $0.englishName == currentExercise.exerciseName }
    }

    /// Danh sách bài tập tương đương (Cùng nhóm cơ chính, ưu tiên dụng cụ khả dụng)
    private var substituteExercises: [ExerciseItem] {
        guard let current = matchedCurrentItem else {
            return allExercises.filter { $0.name != currentExercise.exerciseName }
        }

        return allExercises.filter { item in
            // Không hiển thị lại chính bài tập hiện tại
            guard item.name != current.name else { return false }

            // Lọc theo từ khóa tìm kiếm nếu có
            if !searchQuery.isEmpty {
                let query = searchQuery.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                let name = item.name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                if !name.contains(query) { return false }
            }

            // Tiêu chí 1: Cùng nhóm cơ chính
            let isSameMuscle = (item.primaryMuscle == current.primaryMuscle)
            return isSameMuscle
        }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header tóm tắt bài tập hiện tại cần đổi
                currentExerciseHeader
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))

                Divider()

                // Danh sách bài tập thay thế
                if substituteExercises.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)
                        Text("Không tìm thấy bài tập thay thế phù hợp")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                } else {
                    List {
                        Section {
                            ForEach(substituteExercises) { item in
                                substituteExerciseRow(item: item)
                            }
                        } header: {
                            Text("Gợi ý cùng nhóm cơ (\(matchedCurrentItem?.primaryMuscle.rawValue ?? "Tương đương"))")
                                .font(.caption.bold())
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Đổi bài tập (Swap)")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchQuery, prompt: "Tìm bài tập thay thế...")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var currentExerciseHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.headline)
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Đang đổi cho bài:")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(currentExercise.exerciseName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                if let muscle = matchedCurrentItem?.primaryMuscle.rawValue {
                    Text("Nhóm cơ: \(muscle)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()
        }
    }

    private func substituteExerciseRow(item: ExerciseItem) -> some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
            onSelectSwap(item)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.thumbnailImageName)
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 38, height: 38)
                    .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)

                    HStack(spacing: 6) {
                        Text(item.equipment.shortName)
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.12), in: Capsule())
                            .foregroundStyle(.secondary)

                        if let current = matchedCurrentItem, item.equipment == current.equipment {
                            Text("Cùng dụng cụ")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.15), in: Capsule())
                                .foregroundStyle(.green)
                        }
                    }
                }

                Spacer()

                Image(systemName: "checkmark.circle")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
