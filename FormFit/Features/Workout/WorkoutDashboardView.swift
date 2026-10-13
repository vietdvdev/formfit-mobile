import SwiftUI

/// Màn hình chính Tab 1: Workout Dashboard phong cách thể thao cao cấp (Sports Tech Pro)
/// Tích hợp: Today Activity Rings, Quick Start Neon Card, Active Program Progress, và Recent Workouts Cards
public struct WorkoutDashboardView: View {
    @Environment(AppNavigationCoordinator.self) private var coordinator
    @State private var animateRing = false

    public init() {}

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // 1. Activity Ring Summary (Calo, Thời gian, Khối lượng tạ hôm nay)
                dailyActivityRingSection

                // 2. Thẻ Bắt đầu Buổi tập mới (Hero Neon Card)
                heroQuickStartCard

                // 3. Thẻ Giáo án đang theo dõi (Active Program với Progress Bar)
                activeProgramCard

                // 4. Lưới Thống kê nhanh (Weekly Insights Grid)
                weeklyQuickStatsGrid

                // 5. Thẻ Lịch sử tập luyện gần đây
                recentWorkoutsSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Tập Luyện")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SyncStatusIndicatorView()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9)) {
                animateRing = true
            }
        }
    }

    // MARK: - 1. Daily Activity Ring Section
    private var dailyActivityRingSection: some View {
        HStack(spacing: 20) {
            // Rings Graphic
            ZStack {
                // Background Rings
                Circle()
                    .stroke(FFDesign.Colors.sunsetPink.opacity(0.18), lineWidth: 10)
                    .frame(width: 82, height: 82)
                Circle()
                    .stroke(FFDesign.Colors.primaryNeon.opacity(0.18), lineWidth: 10)
                    .frame(width: 58, height: 58)

                // Foreground Progress Rings
                Circle()
                    .trim(from: 0, to: animateRing ? 0.72 : 0)
                    .stroke(
                        AngularGradient(
                            colors: [FFDesign.Colors.sunsetPink, FFDesign.Colors.vibrantOrange],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 82, height: 82)

                Circle()
                    .trim(from: 0, to: animateRing ? 0.60 : 0)
                    .stroke(
                        AngularGradient(
                            colors: [FFDesign.Colors.primaryNeon, FFDesign.Colors.electricBlue],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 58, height: 58)

                Image(systemName: "flame.fill")
                    .font(.caption.bold())
                    .foregroundStyle(FFDesign.Colors.sunsetPink)
            }
            .frame(width: 90, height: 90)

            // Metrics Breakdown
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle().fill(FFDesign.Colors.sunsetPink).frame(width: 8, height: 8)
                    Text("Calo tiêu thụ:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("480 / 650 kcal")
                        .font(.caption.bold())
                }

                HStack {
                    Circle().fill(FFDesign.Colors.primaryNeon).frame(width: 8, height: 8)
                    Text("Thời gian tập:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("36 / 60 phút")
                        .font(.caption.bold())
                }

                HStack {
                    Circle().fill(FFDesign.Colors.electricBlue).frame(width: 8, height: 8)
                    Text("Khối lượng (Volume):")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("4.850 kg")
                        .font(.caption.bold())
                }
            }
        }
        .padding(18)
        .ffGlassCard()
    }

    // MARK: - 2. Hero Quick Start Card
    private var heroQuickStartCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.caption.bold())
                            .foregroundStyle(FFDesign.Colors.energyYellow)
                        Text("SẴN SÀNG TẬP LUYỆN")
                            .font(.caption2.bold())
                            .tracking(1.2)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    
                    Text("Bắt đầu buổi tập mới")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    
                    Text("Ghi nhận số set, mức tạ, RPE và nhịp tim tức thì với Live Activity")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(2)
                }
                Spacer()

                ZStack {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: 48, height: 48)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
            }

            Button {
                let newSession = WorkoutSession(title: "Buổi tập ngày \(Date().formatted(date: .numeric, time: .omitted))")
                let defaultEx = WorkoutExercise(exerciseId: "bench_press", exerciseName: "Đẩy tạ đòn trên ghế phẳng")
                let set1 = SetEntry(setNumber: 1, weightKg: 60, reps: 10)
                set1.workoutExercise = defaultEx
                defaultEx.sets.append(set1)
                defaultEx.workoutSession = newSession
                newSession.exercises.append(defaultEx)

                coordinator.startWorkout(session: newSession)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                    Text("BẮT ĐẦU NGAY")
                        .font(.subheadline.bold())
                        .tracking(0.8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .foregroundStyle(Color(red: 0.08, green: 0.35, blue: 0.95))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .ffPressable()
        }
        .padding(22)
        .background(FFDesign.Gradients.workoutHero)
        .clipShape(RoundedRectangle(cornerRadius: FFDesign.Radius.large, style: .continuous))
        .shadow(color: FFDesign.Colors.electricBlue.opacity(0.35), radius: 16, x: 0, y: 8)
    }

    // MARK: - 3. Active Program Card
    private var activeProgramCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Giáo án hiện tại: Push - Pull - Legs", systemImage: "flame.fill")
                    .font(.headline)
                    .foregroundStyle(FFDesign.Colors.vibrantOrange)
                Spacer()
                Text("Tuần 4/8")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(FFDesign.Colors.vibrantOrange.opacity(0.15), in: Capsule())
                    .foregroundStyle(FFDesign.Colors.vibrantOrange)
            }

            Text("Hôm nay: Buổi Push Day (Ngực • Vai • Tay sau)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Progress bar
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 8)
                        Capsule()
                            .fill(FFDesign.Gradients.energyFlame)
                            .frame(width: geo.size.width * 0.55, height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("Tiến độ chu kỳ: 55%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("3/5 buổi tuần này")
                        .font(.caption2.bold())
                        .foregroundStyle(FFDesign.Colors.vibrantOrange)
                }
            }

            HStack {
                Label("5 bài tập", systemImage: "dumbbell.fill")
                Spacer()
                Label("60 phút", systemImage: "clock.fill")
                Spacer()
                Label("Trung cấp", systemImage: "chart.line.uptrend.xyaxis")
            }
            .font(.caption2.bold())
            .foregroundStyle(.tertiary)
        }
        .padding(18)
        .ffGlassCard()
    }

    // MARK: - 4. Weekly Quick Stats Grid
    private var weeklyQuickStatsGrid: some View {
        HStack(spacing: 12) {
            statMetricTile(
                title: "Tổng buổi tập",
                value: "14",
                unit: "buổi",
                icon: "calendar.badge.checkmark",
                tint: FFDesign.Colors.electricBlue
            )
            statMetricTile(
                title: "Kỷ lục (PR)",
                value: "3",
                unit: "mục mới",
                icon: "trophy.fill",
                tint: FFDesign.Colors.energyYellow
            )
            statMetricTile(
                title: "Chuỗi tập",
                value: "6",
                unit: "ngày liên tiếp",
                icon: "flame.fill",
                tint: FFDesign.Colors.vibrantOrange
            )
        }
    }

    private func statMetricTile(title: String, value: String, unit: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title3.bold())
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: FFDesign.Radius.medium, style: .continuous))
    }

    // MARK: - 5. Recent Workouts Section
    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Lịch sử tập gần nhất")
                    .font(.headline)
                Spacer()
                Button("Xem tất cả") {}
                    .font(.caption.bold())
                    .foregroundStyle(FFDesign.Colors.electricBlue)
            }

            VStack(spacing: 10) {
                historyCard(
                    title: "Legs & Core Power",
                    date: "Hôm qua",
                    duration: "55 phút",
                    volume: "4.820 kg",
                    calories: "490 kcal",
                    iconName: "figure.cross.training"
                )
                historyCard(
                    title: "Pull Day (Lưng & Tay trước)",
                    date: "3 ngày trước",
                    duration: "62 phút",
                    volume: "5.100 kg",
                    calories: "520 kcal",
                    iconName: "figure.strengthtraining.traditional"
                )
                historyCard(
                    title: "Push Day (Ngực & Vai)",
                    date: "5 ngày trước",
                    duration: "50 phút",
                    volume: "4.250 kg",
                    calories: "430 kcal",
                    iconName: "figure.mixed.cardio"
                )
            }
        }
    }

    private func historyCard(title: String, date: String, duration: String, volume: String, calories: String, iconName: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(FFDesign.Colors.electricBlue.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: iconName)
                    .font(.headline)
                    .foregroundStyle(FFDesign.Colors.electricBlue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text("\(date) • \(duration) • \(calories)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(volume)
                    .font(.subheadline.monospacedDigit().bold())
                    .foregroundStyle(FFDesign.Colors.primaryNeon)
                Text("Volume")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: FFDesign.Radius.medium, style: .continuous))
    }
}
