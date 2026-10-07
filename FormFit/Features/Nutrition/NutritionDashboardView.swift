import SwiftUI

/// Màn hình Dashboard Quản lý Dinh dưỡng & Nhật ký ăn uống trong ngày
public struct NutritionDashboardView: View {
    @State private var viewModel = NutritionViewModel()
    @State private var showGoalSettingsSheet: Bool = false
    @State private var showAddFoodSheet: Bool = false
    @State private var selectedMealForAdd: MealType = .breakfast

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Thẻ Tóm tắt Calo & 3 Thanh Macro
                    calorieMacroSummaryCard

                    // 2. Thẻ hiển thị Mục tiêu & TDEE hiện tại
                    goalOverviewCard

                    // 3. Danh sách món ăn chia theo 4 bữa
                    mealsSection
                }
                .padding(16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Dinh Dưỡng Hôm Nay")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showGoalSettingsSheet = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showGoalSettingsSheet) {
                goalSettingsSheet
            }
        }
    }

    // MARK: - 1. Calorie Ring & Macro Bars Card
    private var calorieMacroSummaryCard: some View {
        VStack(spacing: 20) {
            HStack(spacing: 24) {
                // Vòng tròn Calo Tiến độ (Calorie Progress Ring)
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.18), lineWidth: 12)
                        .frame(width: 124, height: 124)

                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.calorieProgressRatio))
                        .stroke(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 124, height: 124)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.calorieProgressRatio)

                    VStack(spacing: 2) {
                        Text("\(Int(viewModel.remainingCalories))")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("Còn lại")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text("Mục tiêu: \(Int(viewModel.macroTarget.targetCalories))")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }

                // Chi tiết nạp vào / mục tiêu
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Đã nạp vào")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(Int(viewModel.consumedCalories)) kcal")
                            .font(.title3.bold())
                            .foregroundStyle(.orange)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tiến độ đạt")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(Int(viewModel.calorieProgressRatio * 100))%")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            // 3 Thanh Bar Macro: Protein, Carbs, Fat
            VStack(spacing: 12) {
                macroProgressBar(
                    title: "Protein (Đạm)",
                    current: viewModel.dailyLog.totalProtein,
                    target: viewModel.macroTarget.proteinGrams,
                    color: .red,
                    ratio: viewModel.proteinProgressRatio
                )

                macroProgressBar(
                    title: "Carbs (Tinh bột)",
                    current: viewModel.dailyLog.totalCarbs,
                    target: viewModel.macroTarget.carbsGrams,
                    color: .blue,
                    ratio: viewModel.carbsProgressRatio
                )

                macroProgressBar(
                    title: "Fat (Chất béo)",
                    current: viewModel.dailyLog.totalFat,
                    target: viewModel.macroTarget.fatGrams,
                    color: .yellow,
                    ratio: viewModel.fatProgressRatio
                )
            }
        }
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 3)
    }

    private func macroProgressBar(
        title: String,
        current: Double,
        target: Double,
        color: Color,
        ratio: Double
    ) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(Int(current))g / \(Int(target))g")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 8)

                    Capsule()
                        .fill(color)
                        .frame(width: max(8, geo.size.width * CGFloat(ratio)), height: 8)
                        .animation(.easeInOut(duration: 0.25), value: ratio)
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - 2. Goal Overview Card
    private var goalOverviewCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "flame.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Mục tiêu: \(viewModel.goal.rawValue)")
                    .font(.subheadline.bold())
                Text("BMR: \(Int(NutritionCalculator.calculateBMR(weightKg: viewModel.weightKg, heightCm: viewModel.heightCm, age: viewModel.age, gender: viewModel.gender))) kcal • TDEE: \(Int(NutritionCalculator.calculateTDEE(bmr: NutritionCalculator.calculateBMR(weightKg: viewModel.weightKg, heightCm: viewModel.heightCm, age: viewModel.age, gender: viewModel.gender), activityLevel: viewModel.activityLevel))) kcal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Đổi") {
                showGoalSettingsSheet = true
            }
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.15), in: Capsule())
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 3. Meals Section (4 Bữa)
    private var mealsSection: some View {
        VStack(spacing: 16) {
            ForEach(MealType.allCases) { meal in
                mealCardView(meal: meal)
            }
        }
    }

    private func mealCardView(meal: MealType) -> some View {
        let items = viewModel.dailyLog.items(for: meal)
        let mealCalories = viewModel.dailyLog.calories(for: meal)

        return VStack(alignment: .leading, spacing: 12) {
            // Header bữa ăn
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: meal.iconName)
                        .foregroundStyle(.orange)
                    Text(meal.rawValue)
                        .font(.headline)
                }

                Spacer()

                Text("\(Int(mealCalories)) kcal")
                    .font(.subheadline.monospacedDigit().bold())
                    .foregroundStyle(.secondary)

                Button {
                    // Mở sheet thêm món
                    addQuickSampleFood(to: meal)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }

            // Danh sách món ăn trong bữa
            if items.isEmpty {
                Text("Chưa có món ăn nào")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 8) {
                    ForEach(items) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.subheadline.weight(.medium))
                                Text(item.servingSize)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(Int(item.calories)) kcal")
                                    .font(.caption.bold())
                                Text("P: \(Int(item.protein))g • C: \(Int(item.carbs))g • F: \(Int(item.fat))g")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        if item.id != items.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private func addQuickSampleFood(to meal: MealType) {
        let sample = FoodItem(
            name: "Món ăn mới",
            servingSize: "1 phần tiêu chuẩn",
            calories: 150,
            protein: 15,
            carbs: 15,
            fat: 3,
            mealType: meal
        )
        withAnimation {
            viewModel.addFoodItem(sample)
        }
    }

    // MARK: - Goal Settings Sheet
    private var goalSettingsSheet: some View {
        NavigationStack {
            Form {
                Section("Thông số thể hình") {
                    Picker("Giới tính", selection: $viewModel.gender) {
                        ForEach(Gender.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Stepper("Tuổi: \(viewModel.age)", value: $viewModel.age, in: 15...80)
                    HStack {
                        Text("Chiều cao")
                        Spacer()
                        TextField("cm", value: $viewModel.heightCm, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Cân nặng")
                        Spacer()
                        TextField("kg", value: $viewModel.weightKg, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Cường độ vận động") {
                    Picker("Hệ số vận động", selection: $viewModel.activityLevel) {
                        ForEach(ActivityLevel.allCases) { level in
                            Text(level.title).tag(level)
                        }
                    }
                }

                Section("Mục tiêu thể hình") {
                    Picker("Mục tiêu", selection: $viewModel.goal) {
                        ForEach(FitnessGoal.allCases) { goal in
                            Text(goal.rawValue).tag(goal)
                        }
                    }
                }
            }
            .navigationTitle("Cài đặt Dinh Dưỡng")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Xong") {
                        showGoalSettingsSheet = false
                    }
                    .font(.headline)
                }
            }
        }
    }
}

#Preview {
    NutritionDashboardView()
}
