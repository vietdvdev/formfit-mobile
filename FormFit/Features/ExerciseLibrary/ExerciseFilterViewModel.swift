import Foundation
import Observation

/// Tiện ích hỗ trợ tìm kiếm Tiếng Việt không dấu / có dấu
extension String {
    var foldedVietnamese: String {
        self.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN"))
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: "Đ", with: "D")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}

/// ViewModel quản lý trạng thái tìm kiếm và bộ lọc bài tập
@Observable
@MainActor
public final class ExerciseFilterViewModel {
    // MARK: - Filter States
    public var searchText: String = ""
    public var selectedMuscle: MuscleGroup = .all
    public var selectedEquipment: EquipmentType = .all

    // MARK: - Data Source
    private(set) public var allExercises: [ExerciseItem] = []

    public init(exercises: [ExerciseItem] = MockExerciseData.sampleExercises) {
        self.allExercises = exercises
    }

    // MARK: - Filtered Result Computed Property
    public var filteredExercises: [ExerciseItem] {
        allExercises.filter { item in
            // 1. Lọc theo nhóm cơ
            let matchesMuscle = (selectedMuscle == .all) || (item.primaryMuscle == selectedMuscle)

            // 2. Lọc theo thiết bị / dụng cụ
            let matchesEquipment = (selectedEquipment == .all) || (item.equipment == selectedEquipment)

            // 3. Tìm kiếm theo tên (Hỗ trợ Tiếng Việt có dấu & không dấu, tên tiếng Anh)
            let matchesSearch: Bool
            let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedQuery.isEmpty {
                matchesSearch = true
            } else {
                let foldedQuery = trimmedQuery.foldedVietnamese
                let foldedName = item.name.foldedVietnamese
                let foldedEnglishName = item.englishName.foldedVietnamese

                matchesSearch = foldedName.contains(foldedQuery) || foldedEnglishName.contains(foldedQuery)
            }

            return matchesMuscle && matchesEquipment && matchesSearch
        }
    }

    /// Reset bộ lọc về trạng thái ban đầu
    public func resetFilters() {
        self.searchText = ""
        self.selectedMuscle = .all
        self.selectedEquipment = .all
    }

    /// Đếm số lượng bài tập theo nhóm cơ phục vụ hiển thị Badge
    public func count(for muscle: MuscleGroup) -> Int {
        if muscle == .all {
            return allExercises.count
        }
        return allExercises.filter { $0.primaryMuscle == muscle }.count
    }
}
