import Foundation

/// Nhóm cơ chính
public enum MuscleGroup: String, CaseIterable, Identifiable, Codable, Sendable {
    case all = "Tất cả"
    case chest = "Ngực"
    case back = "Lưng"
    case legs = "Chân"
    case shoulders = "Vai"
    case arms = "Tay"
    case core = "Bụng"

    public var id: String { rawValue }

    public var systemIcon: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .chest: return "figure.cooldown"
        case .back: return "figure.core.training"
        case .legs: return "figure.run"
        case .shoulders: return "figure.boxing"
        case .arms: return "figure.arms.open"
        case .core: return "figure.mind.and.body"
        }
    }
}

/// Loại dụng cụ tập luyện
public enum EquipmentType: String, CaseIterable, Identifiable, Codable, Sendable {
    case all = "Tất cả"
    case dumbbell = "Tạ đơn (Dumbbell)"
    case barbell = "Tạ đòn (Barbell)"
    case cable = "Dây cáp (Cable)"
    case machine = "Máy (Machine)"
    case bodyweight = "Bodyweight"

    public var id: String { rawValue }

    public var shortName: String {
        switch self {
        case .all: return "Tất cả"
        case .dumbbell: return "Dumbbell"
        case .barbell: return "Barbell"
        case .cable: return "Cable"
        case .machine: return "Machine"
        case .bodyweight: return "Bodyweight"
        }
    }

    public var badgeIcon: String {
        switch self {
        case .all: return "slider.horizontal.3"
        case .dumbbell: return "dumbbell.fill"
        case .barbell: return "figure.strengthtraining.traditional"
        case .cable: return "cable.connector"
        case .machine: return "gearshape.fill"
        case .bodyweight: return "figure.walk"
        }
    }
}

/// Độ khó của bài tập
public enum ExerciseDifficulty: String, Codable, Sendable {
    case beginner = "Mới bắt đầu"
    case intermediate = "Trung cấp"
    case advanced = "Nâng cao"
}

/// Model đại diện cho một bài tập trong hệ thống FormFit
public struct ExerciseItem: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let name: String
    public let englishName: String
    public let primaryMuscle: MuscleGroup
    public let secondaryMuscles: [String]
    public let equipment: EquipmentType
    public let difficulty: ExerciseDifficulty
    public let thumbnailImageName: String
    public let model3DRemoteURL: URL
    public let targetMeshNodeNames: [String]
    public let instructions: [String]
    public let commonMistakes: [String]

    public init(
        id: UUID = UUID(),
        name: String,
        englishName: String,
        primaryMuscle: MuscleGroup,
        secondaryMuscles: [String] = [],
        equipment: EquipmentType,
        difficulty: ExerciseDifficulty = .intermediate,
        thumbnailImageName: String,
        model3DRemoteURL: URL,
        targetMeshNodeNames: [String] = [],
        instructions: [String] = [],
        commonMistakes: [String] = []
    ) {
        self.id = id
        self.name = name
        self.englishName = englishName
        self.primaryMuscle = primaryMuscle
        self.secondaryMuscles = secondaryMuscles
        self.equipment = equipment
        self.difficulty = difficulty
        self.thumbnailImageName = thumbnailImageName
        self.model3DRemoteURL = model3DRemoteURL
        self.targetMeshNodeNames = targetMeshNodeNames
        self.instructions = instructions
        self.commonMistakes = commonMistakes
    }
}
