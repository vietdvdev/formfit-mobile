import Foundation

/// Giới tính sinh học
public enum Gender: String, CaseIterable, Identifiable, Codable, Sendable {
    case male = "Nam"
    case female = "Nữ"

    public var id: String { rawValue }
}

/// Hệ số vận động hàng ngày (Physical Activity Level)
public enum ActivityLevel: Double, CaseIterable, Identifiable, Codable, Sendable {
    case sedentary = 1.2          // Ít vận động, công việc văn phòng
    case lightlyActive = 1.375    // Vận động nhẹ (tập 1-3 ngày/tuần)
    case moderatelyActive = 1.55  // Vận động vừa phải (tập 3-5 ngày/tuần)
    case veryActive = 1.725       // Vận động nhiều (tập 6-7 ngày/tuần)
    case extremelyActive = 1.9    // Rất năng động (vận động viên, lao động nặng)

    public var id: Double { rawValue }

    public var title: String {
        switch self {
        case .sedentary: return "Ít vận động (1.2)"
        case .lightlyActive: return "Nhẹ nhàng (1.375)"
        case .moderatelyActive: return "Vừa phải (1.55)"
        case .veryActive: return "Nhiều (1.725)"
        case .extremelyActive: return "Cực kỳ nhiều (1.9)"
        }
    }

    public var subtitle: String {
        switch self {
        case .sedentary: return "Chủ yếu ngồi, ít thể dục"
        case .lightlyActive: return "Tập nhẹ 1-3 buổi/tuần"
        case .moderatelyActive: return "Tập chăm chỉ 3-5 buổi/tuần"
        case .veryActive: return "Tập nặng 6-7 buổi/tuần"
        case .extremelyActive: return "Cường độ cao 2 lần/ngày"
        }
    }
}

/// Mục tiêu thể hình
public enum FitnessGoal: String, CaseIterable, Identifiable, Codable, Sendable {
    case bulking = "Tăng cơ (Bulking)"
    case cutting = "Giảm mỡ (Cutting)"
    case maintenance = "Duy trì cân nặng"

    public var id: String { rawValue }

    /// Điều chỉnh lượng calo so với TDEE
    public var calorieAdjustmentPercent: Double {
        switch self {
        case .bulking: return 1.15     // Thặng dư calo +15%
        case .cutting: return 0.80     // Thâm hụt calo -20%
        case .maintenance: return 1.0  // Giữ nguyên calo TDEE
        }
    }
}

/// Kết quả phân bổ Macro dinh dưỡng (gam và calo)
public struct MacroBreakdown: Codable, Sendable, Equatable {
    public let targetCalories: Double
    public let proteinGrams: Double
    public let carbsGrams: Double
    public let fatGrams: Double

    public init(targetCalories: Double, proteinGrams: Double, carbsGrams: Double, fatGrams: Double) {
        self.targetCalories = targetCalories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
    }
}

/// Thuật toán tính toán TDEE, BMR và Macro tiêu chuẩn
public struct NutritionCalculator {
    
    /// Tính BMR (Tỷ lệ trao đổi chất cơ bản) theo công thức Mifflin-St Jeor
    /// Nam: BMR = (10 × W) + (6.25 × H) - (5 × A) + 5
    /// Nữ:  BMR = (10 × W) + (6.25 × H) - (5 × A) - 161
    /// (W: Cân nặng kg, H: Chiều cao cm, A: Tuổi)
    public static func calculateBMR(
        weightKg: Double,
        heightCm: Double,
        age: Int,
        gender: Gender
    ) -> Double {
        let base = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * Double(age))
        switch gender {
        case .male:
            return base + 5.0
        case .female:
            return base - 161.0
        }
    }

    /// Tính TDEE = BMR × Activity Level
    public static func calculateTDEE(
        bmr: Double,
        activityLevel: ActivityLevel
    ) -> Double {
        return bmr * activityLevel.rawValue
    }

    /// Tính Macro chuẩn dựa trên mục tiêu thể hình:
    /// 1. Tăng cơ (Bulking): 40% Carbs, 30% Protein, 30% Fat
    /// 2. Giảm mỡ (Cutting): 40% Protein, 35% Carbs, 25% Fat (ưu tiên đạm cao giữ cơ)
    /// 3. Duy trì (Maintenance): 45% Carbs, 25% Protein, 30% Fat
    /// (1g Protein = 4 kcal, 1g Carbs = 4 kcal, 1g Fat = 9 kcal)
    public static func calculateMacros(
        weightKg: Double,
        heightCm: Double,
        age: Int,
        gender: Gender,
        activityLevel: ActivityLevel,
        goal: FitnessGoal
    ) -> MacroBreakdown {
        let bmr = calculateBMR(weightKg: weightKg, heightCm: heightCm, age: age, gender: gender)
        let tdee = calculateTDEE(bmr: bmr, activityLevel: activityLevel)
        let targetCal = tdee * goal.calorieAdjustmentPercent

        let proteinRatio: Double
        let carbsRatio: Double
        let fatRatio: Double

        switch goal {
        case .bulking:
            proteinRatio = 0.30
            carbsRatio = 0.40
            fatRatio = 0.30
        case .cutting:
            proteinRatio = 0.40
            carbsRatio = 0.35
            fatRatio = 0.25
        case .maintenance:
            proteinRatio = 0.25
            carbsRatio = 0.45
            fatRatio = 0.30
        }

        let proteinGrams = (targetCal * proteinRatio) / 4.0
        let carbsGrams = (targetCal * carbsRatio) / 4.0
        let fatGrams = (targetCal * fatRatio) / 9.0

        return MacroBreakdown(
            targetCalories: targetCal.rounded(),
            proteinGrams: proteinGrams.rounded(),
            carbsGrams: carbsGrams.rounded(),
            fatGrams: fatGrams.rounded()
        )
    }
}
