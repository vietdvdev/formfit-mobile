import SwiftUI
import SwiftData

/// Màn hình Active Workout Mode tối ưu thao tác nhanh trong phòng gym
/// Tích hợp: Bảng Set/Previous/Kg/Reps/Checkmark, Custom Number Pad Accessory Toolbar, Exercise Swap
public struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var workoutManager = ActiveWorkoutManager()
    @State private var showDiscardAlert: Bool = false
    @State private var swappingExercise: WorkoutExercise? = nil
    
    // Quản lý bàn phím và trường nhập liệu đang focus
    @FocusState private var focusedField: ActiveInputField?

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Banner Rest Timer
                if RestTimerService.shared.isRunning {
                    restTimerBanner
                } else if HealthKitManager.shared.currentHeartRate > 0 {
                    heartRateStatusBar
                }

                if let session = workoutManager.currentSession {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })) { exercise in
                                    exerciseBlockView(exercise: exercise)
                                        .id(exercise.id)
                                }

                                // Nút thêm bài tập mới
                                Button {
                                    addNewExerciseAction()
                                } label: {
                                    Label("Thêm bài tập", systemImage: "plus.circle.fill")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                                        .foregroundStyle(.blue)
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 8)
                            }
                            .padding(16)
                        }
                    }
                } else {
                    emptyWorkoutPlaceholder
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(workoutManager.currentSession?.title ?? "Buổi tập trực tiếp")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Hủy") {
                        showDiscardAlert = true
                    }
                    .foregroundStyle(.red)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Hoàn thành") {
                        workoutManager.finishWorkout()
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .disabled(workoutManager.currentSession?.exercises.isEmpty ?? true)
                }
            }
            .alert("Hủy buổi tập?", isPresented: $showDiscardAlert) {
                Button("Hủy và xóa dữ liệu", role: .destructive) {
                    workoutManager.discardWorkout()
                    dismiss()
                }
                Button("Tiếp tục tập", role: .cancel) {}
            } message: {
                Text("Toàn bộ dữ liệu của buổi tập này sẽ không được lưu lại.")
            }
            .sheet(item: $swappingExercise) { exerciseToSwap in
                ExerciseSwapSheetView(currentExercise: exerciseToSwap) { selectedNewItem in
                    // Cập nhật lại exerciseId và exerciseName mà vẫn giữ nguyên các set và buổi tập
                    exerciseToSwap.exerciseId = selectedNewItem.id.uuidString
                    exerciseToSwap.exerciseName = selectedNewItem.name
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Custom Number Pad Accessory Toolbar hiển thị khi focus vào ô Kg hoặc Reps
                if focusedField != nil {
                    NumericKeyboardAccessoryView(
                        activeField: focusedField,
                        onAddAmount: { amount in
                            applyIncrement(amount: amount)
                        },
                        onDone: {
                            focusedField = nil
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .task {
                workoutManager.attachModelContext(modelContext)
                if workoutManager.currentSession == nil {
                    workoutManager.startWorkout()
                    // Khởi tạo 2 bài tập mẫu
                    workoutManager.addExercise(id: "bench_press", name: "Đẩy tạ đòn trên ghế phẳng")
                    workoutManager.addExercise(id: "cable_row", name: "Kéo xô cáp ngồi")
                }
            }
        }
    }

    // MARK: - Exercise Block View
    private func exerciseBlockView(exercise: WorkoutExercise) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header bài tập: Tên bài + Nút Swap + Menu
            HStack(alignment: .center, spacing: 8) {
                Text(exercise.exerciseName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                // Nút Đổi bài tập (Exercise Swap)
                Button {
                    swappingExercise = exercise
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption2.bold())
                        Text("Đổi bài")
                            .font(.caption2.bold())
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.orange.opacity(0.12), in: Capsule())
                    .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)

                // Menu tùy chọn khác
                Menu {
                    Button(role: .destructive) {
                        workoutManager.removeExercise(exercise)
                    } label: {
                        Label("Xóa bài tập này", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .padding(6)
                        .foregroundStyle(.secondary)
                }
            }

            // Bảng các hiệp tập: Header Columns
            HStack(spacing: 6) {
                Text("SET")
                    .frame(width: 38, alignment: .leading)
                Text("PREVIOUS")
                    .frame(width: 76, alignment: .center)
                Text("KG")
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("REPS")
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("XONG")
                    .frame(width: 44, alignment: .trailing)
            }
            .font(.caption2.bold())
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)

            Divider()

            // Danh sách các dòng hiệp tập (Sets)
            ForEach(exercise.sets.sorted(by: { $0.setNumber < $1.setNumber })) { set in
                setRowView(set: set, in: exercise)
            }

            // Nút thêm Set
            Button {
                withAnimation {
                    workoutManager.addSet(to: exercise)
                }
            } label: {
                Label("Thêm hiệp", systemImage: "plus")
                    .font(.footnote.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.02), radius: 6, x: 0, y: 2)
    }

    // MARK: - Set Row View (Bảng chi tiết từng hiệp)
    private func setRowView(set: SetEntry, in exercise: WorkoutExercise) -> some View {
        let previousPerformance = PreviousWorkoutRecord.getPreviousPerformance(
            exerciseId: exercise.exerciseId,
            setNumber: set.setNumber
        )

        return HStack(spacing: 6) {
            // Cột 1: Set Number
            Text("\(set.setNumber)")
                .font(.subheadline.bold())
                .frame(width: 38, alignment: .leading)
                .foregroundStyle(set.isCompleted ? .secondary : .primary)

            // Cột 2: Previous (Thành tích buổi trước)
            Text(previousPerformance)
                .font(.caption2.monospacedDigit())
                .frame(width: 76, alignment: .center)
                .foregroundStyle(.secondary)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))

            // Cột 3: Trọng lượng tạ (KG TextField)
            TextField("0", value: Bindable(set).weightKg, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.subheadline.monospacedDigit().bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    set.isCompleted ? Color.clear : Color(uiColor: .tertiarySystemFill),
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .focused($focusedField, equals: .weight(exerciseId: exercise.id, setId: set.id))

            // Cột 4: Số lần lặp (Reps TextField)
            TextField("0", value: Bindable(set).reps, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.subheadline.monospacedDigit().bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    set.isCompleted ? Color.clear : Color(uiColor: .tertiarySystemFill),
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .focused($focusedField, equals: .reps(exerciseId: exercise.id, setId: set.id))

            // Cột 5: Nút Checkmark tròn to cực kỳ dễ bấm
            Button {
                focusedField = nil // Ẩn bàn phím khi tích xong hiệp
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    workoutManager.toggleSetCompletion(set: set, in: exercise)
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(set.isCompleted ? Color.green : Color.secondary.opacity(0.18))
                        .frame(width: 34, height: 34)

                    Image(systemName: set.isCompleted ? "checkmark" : "circle")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(set.isCompleted ? .white : .secondary.opacity(0.4))
                }
                .frame(width: 44, alignment: .trailing)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            set.isCompleted ? Color.green.opacity(0.08) : Color.clear,
            in: RoundedRectangle(cornerRadius: 10)
        )
    }

    // MARK: - Quick Increment Logic
    private func applyIncrement(amount: Double) {
        guard let field = focusedField,
              let session = workoutManager.currentSession else { return }

        switch field {
        case .weight(let exerciseId, let setId):
            if let exercise = session.exercises.first(where: { $0.id == exerciseId }),
               let set = exercise.sets.first(where: { $0.id == setId }) {
                set.weightKg = max(0, set.weightKg + amount)
            }
        case .reps(let exerciseId, let setId):
            if let exercise = session.exercises.first(where: { $0.id == exerciseId }),
               let set = exercise.sets.first(where: { $0.id == setId }) {
                set.reps = max(0, set.reps + Int(amount))
            }
        }
    }

    private func addNewExerciseAction() {
        let sampleOptions = [
            ("squat", "Gánh tạ đòn"),
            ("shoulder_press", "Đẩy tạ đơn qua đầu"),
            ("bicep_curl", "Cuốn tay trước với tạ đơn"),
            ("push_up", "Hít đất"),
            ("leg_press", "Đạp đùi trên máy")
        ]
        if let random = sampleOptions.randomElement() {
            workoutManager.addExercise(id: random.0, name: random.1)
        }
    }

    // MARK: - Rest Timer Banner (Kết nối RestTimerService & Live Activities)
    private var restTimerBanner: some View {
        let timerService = RestTimerService.shared
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 3)
                    .frame(width: 32, height: 32)
                Image(systemName: "timer")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("NGHỈ GIỮA HIỆP:")
                        .font(.caption2.bold())
                        .foregroundStyle(.white.opacity(0.8))
                    Text("\(timerService.remainingSeconds)s")
                        .font(.subheadline.monospacedDigit().bold())
                        .foregroundStyle(.white)
                }

                if !timerService.currentExerciseName.isEmpty {
                    Text("\(timerService.currentExerciseName) • Tiếp: Hiệp \(timerService.nextSetNumber)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                }
            }

            Spacer()

            // Nút -15s
            Button("-15s") {
                timerService.adjustTime(by: -15)
            }
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.18), in: Capsule())
            .foregroundStyle(.white)

            // Nút +15s
            Button("+15s") {
                timerService.adjustTime(by: 15)
            }
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.25), in: Capsule())
            .foregroundStyle(.white)

            // Nút Skip (Bỏ qua)
            Button("Bỏ qua") {
                timerService.skipRestTimer()
            }
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.35), in: Capsule())
            .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [.cyan, .blue, .indigo],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    // MARK: - Heart Rate Status Bar
    private var heartRateStatusBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .foregroundStyle(.red)
                .symbolEffect(.pulse)

            Text("Nhịp tim hiện tại:")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(Int(HealthKitManager.shared.currentHeartRate)) BPM")
                .font(.caption.monospacedDigit().bold())
                .foregroundStyle(.red)

            Spacer()

            Label("Apple Health", systemImage: "apple.logo")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private var emptyWorkoutPlaceholder: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)
            Text("Chưa có bài tập nào")
                .font(.headline)
            Button("Bắt đầu bài tập đầu tiên") {
                workoutManager.addExercise(id: "bench_press", name: "Đẩy tạ đòn trên ghế phẳng")
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }
}

#Preview {
    ActiveWorkoutView()
}
