import SwiftUI

/// Màn hình chính Tab 1: Workout Dashboard quản lý bắt đầu buổi tập và lịch sử
public struct WorkoutDashboardView: View {
    @Environment(AppNavigationCoordinator.self) private var coordinator

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Thẻ Bắt đầu Buổi tập mới (Quick Start Card)
                quickStartWorkoutCard

                // Thẻ Giáo án đang theo dõi (Active Program)
                activeProgramCard

                // Thẻ Lịch sử tập luyện gần đây
                recentWorkoutsCard
            }
            .padding(16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Tập Luyện")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SyncStatusIndicatorView()
            }
        }
    }

    private var quickStartWorkoutCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bắt đầu buổi tập mới")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text("Ghi nhận số set, mức tạ, RPE và nhịp tim")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "bolt.fill")
                    .font(.title)
                    .foregroundStyle(.yellow)
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
                HStack {
                    Image(systemName: "play.fill")
                    Text("Bắt Đầu Ngay")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [.blue, .indigo],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22)
        )
        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
    }

    private var activeProgramCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Giáo án hiện tại: Push - Pull - Legs", systemImage: "flame.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            Text("Hôm nay: Buổi Push Day (Ngực • Vai • Tay sau)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Label("5 bài tập", systemImage: "dumbbell")
                Spacer()
                Label("60 phút", systemImage: "clock")
                Spacer()
                Label("Trung cấp", systemImage: "chart.line.uptrend.xyaxis")
            }
            .font(.caption2.bold())
            .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private var recentWorkoutsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lịch sử tập gần nhất")
                .font(.headline)

            VStack(spacing: 8) {
                historyRow(title: "Legs & Core Day", date: "Hôm qua", duration: "55 phút", volume: "4.820 kg")
                Divider()
                historyRow(title: "Pull Day (Lưng & Tay trước)", date: "3 ngày trước", duration: "62 phút", volume: "5.100 kg")
                Divider()
                historyRow(title: "Push Day (Ngực & Vai)", date: "5 ngày trước", duration: "50 phút", volume: "4.250 kg")
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private func historyRow(title: String, date: String, duration: String, volume: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())
                Text("\(date) • \(duration)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(volume)
                .font(.caption.monospacedDigit().bold())
                .foregroundStyle(.blue)
        }
        .padding(.vertical, 2)
    }
}
