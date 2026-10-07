import SwiftUI

/// Màn hình Thư viện bài tập (Exercise Library) với bộ lọc nhóm cơ, dụng cụ và tìm kiếm tiếng Việt
public struct ExerciseListView: View {
    @State private var viewModel = ExerciseFilterViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Thanh bộ lọc cuộn ngang (Nhóm cơ & Dụng cụ)
                filterSection
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .systemBackground))

                Divider()

                // Danh sách bài tập hiển thị dạng Card
                exerciseListContent
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Thư Viện Bài Tập")
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Tìm theo tên bài (Tiếng Việt hoặc English)..."
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.selectedMuscle != .all || viewModel.selectedEquipment != .all || !viewModel.searchText.isEmpty {
                        Button("Đặt lại") {
                            withAnimation {
                                viewModel.resetFilters()
                            }
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
    }

    // MARK: - Filter Section
    private var filterSection: some View {
        VStack(spacing: 8) {
            // 1. Lọc theo Nhóm cơ chính
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MuscleGroup.allCases) { muscle in
                        let isSelected = viewModel.selectedMuscle == muscle
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedMuscle = muscle
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: muscle.systemIcon)
                                    .font(.caption2)
                                Text(muscle.rawValue)
                                    .font(.subheadline.weight(isSelected ? .bold : .medium))

                                // Badge số lượng bài tập
                                Text("\(viewModel.count(for: muscle))")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(isSelected ? Color.white.opacity(0.25) : Color.secondary.opacity(0.15), in: Capsule())
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                isSelected ? Color.blue : Color(uiColor: .secondarySystemGroupedBackground),
                                in: Capsule()
                            )
                            .foregroundStyle(isSelected ? Color.white : Color.primary)
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? Color.clear : Color.primary.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }

            // 2. Lọc theo Dụng cụ (Equipment Chips)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(EquipmentType.allCases) { equipment in
                        let isSelected = viewModel.selectedEquipment == equipment
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedEquipment = equipment
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: equipment.badgeIcon)
                                    .font(.caption2)
                                Text(equipment.shortName)
                                    .font(.caption.weight(isSelected ? .semibold : .regular))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                isSelected ? Color.orange : Color(uiColor: .secondarySystemGroupedBackground),
                                in: Capsule()
                            )
                            .foregroundStyle(isSelected ? Color.white : Color.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Exercise List Content
    private var exerciseListContent: some View {
        Group {
            if viewModel.filteredExercises.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredExercises) { exercise in
                            NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                ExerciseCardView(exercise: exercise)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
        }
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)

            VStack(spacing: 4) {
                Text("Không tìm thấy bài tập phù hợp")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Hãy thử đổi từ khóa tìm kiếm hoặc bỏ bớt các bộ lọc.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button("Đặt lại bộ lọc") {
                withAnimation {
                    viewModel.resetFilters()
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)

            Spacer()
        }
    }
}

#Preview {
    ExerciseListView()
}
