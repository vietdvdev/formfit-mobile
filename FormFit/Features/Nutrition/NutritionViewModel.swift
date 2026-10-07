import Foundation
import Observation

/// ViewModel quản lý dữ liệu người dùng, tính toán TDEE/Macro và nhật ký ăn uống
@Observable
@MainActor
public final class NutritionViewModel {
    // MARK: - User Body Profile
    public var gender: Gender = .male
    public var age: Int = 24
    public var weightKg: Double = 72.0
    public var heightCm: Double = 175.0
    public var activityLevel: ActivityLevel = .moderatelyActive
    public var goal: FitnessGoal = .bulking

    // MARK: - Calculated Targets
    public var macroTarget: MacroBreakdown {
        NutritionCalculator.calculateMacros(
            weightKg: weightKg,
            heightCm: heightCm,
            age: age,
            gender: gender,
            activityLevel: activityLevel,
            goal: goal
        )
    }

    // MARK: - Today's Food Log
    public var dailyLog: DailyNutritionLog = DailyNutritionLog(
        date: Date(),
        foodEntries: [
            // Bữa sáng
            FoodItem(name: "Yến mạch nấu sữa tươi", servingSize: "80g yến mạch + 200ml sữa", calories: 380, protein: 18, carbs: 58, fat: 8, mealType: .breakfast),
            FoodItem(name: "Trứng gà luộc", servingSize: "2 quả", calories: 144, protein: 13, carbs: 1, fat: 10, mealType: .breakfast),

            // Bữa trưa
            FoodItem(name: "Ức gà áp chảo", servingSize: "200g", calories: 330, protein: 62, carbs: 0, fat: 7, mealType: .lunch),
            FoodItem(name: "Cơm gạo lứt", servingSize: "1 bát (150g)", calories: 215, protein: 5, carbs: 45, fat: 2, mealType: .lunch),
            FoodItem(name: "Bông cải xanh luộc", servingSize: "100g", calories: 35, protein: 3, carbs: 7, fat: 0.5, mealType: .lunch),

            // Bữa tối
            FoodItem(name: "Thịt bò xào ớt chuông", servingSize: "180g", calories: 360, protein: 42, carbs: 8, fat: 18, mealType: .dinner),
            FoodItem(name: "Khoai lang luộc", servingSize: "200g", calories: 172, protein: 3, carbs: 40, fat: 0.2, mealType: .dinner),

            // Bữa phụ
            FoodItem(name: "Whey Protein Isolate", servingSize: "1 muỗng (30g)", calories: 120, protein: 25, carbs: 2, fat: 1, mealType: .snack),
            FoodItem(name: "Chuối tiêu", servingSize: "1 quả", calories: 105, protein: 1.3, carbs: 27, fat: 0.3, mealType: .snack)
        ]
    )

    public init() {}

    // MARK: - Progress Calculations
    public var consumedCalories: Double { dailyLog.totalCalories }
    public var remainingCalories: Double { max(0, macroTarget.targetCalories - consumedCalories) }
    public var calorieProgressRatio: Double {
        guard macroTarget.targetCalories > 0 else { return 0 }
        return min(1.0, consumedCalories / macroTarget.targetCalories)
    }

    public var proteinProgressRatio: Double {
        guard macroTarget.proteinGrams > 0 else { return 0 }
        return min(1.0, dailyLog.totalProtein / macroTarget.proteinGrams)
    }

    public var carbsProgressRatio: Double {
        guard macroTarget.carbsGrams > 0 else { return 0 }
        return min(1.0, dailyLog.totalCarbs / macroTarget.carbsGrams)
    }

    public var fatProgressRatio: Double {
        guard macroTarget.fatGrams > 0 else { return 0 }
        return min(1.0, dailyLog.totalFat / macroTarget.fatGrams)
    }

    // MARK: - Actions
    public func addFoodItem(_ item: FoodItem) {
        dailyLog.foodEntries.append(item)
    }

    public func removeFoodItem(id: UUID) {
        dailyLog.foodEntries.removeAll { $0.id == id }
    }
}
