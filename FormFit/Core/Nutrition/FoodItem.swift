import Foundation

/// Phân loại 4 bữa ăn chính trong ngày
public enum MealType: String, CaseIterable, Identifiable, Codable, Sendable {
    case breakfast = "Bữa sáng"
    case lunch = "Bữa trưa"
    case dinner = "Bữa tối"
    case snack = "Bữa phụ"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .breakfast: return "sun.horizon.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "cup.and.saucer.fill"
        }
    }
}

/// Món ăn ghi nhận trong nhật ký dinh dưỡng
public struct FoodItem: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var servingSize: String // ví dụ: "200g", "1 quả", "1 muỗng"
    public var calories: Double
    public var protein: Double // gam
    public var carbs: Double   // gam
    public var fat: Double     // gam
    public var mealType: MealType

    public init(
        id: UUID = UUID(),
        name: String,
        servingSize: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        mealType: MealType
    ) {
        self.id = id
        self.name = name
        self.servingSize = servingSize
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.mealType = mealType
    }
}

/// Nhật ký ăn uống của một ngày
public struct DailyNutritionLog: Sendable {
    public var date: Date
    public var foodEntries: [FoodItem]

    public var totalCalories: Double {
        foodEntries.reduce(0) { $0 + $1.calories }
    }

    public var totalProtein: Double {
        foodEntries.reduce(0) { $0 + $1.protein }
    }

    public var totalCarbs: Double {
        foodEntries.reduce(0) { $0 + $1.carbs }
    }

    public var totalFat: Double {
        foodEntries.reduce(0) { $0 + $1.fat }
    }

    public func items(for meal: MealType) -> [FoodItem] {
        foodEntries.filter { $0.mealType == meal }
    }

    public func calories(for meal: MealType) -> Double {
        items(for: meal).reduce(0) { $0 + $1.calories }
    }
}
