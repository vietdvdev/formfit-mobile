import SwiftUI

/// Component giao diện người dùng chính hiển thị mô hình bài tập 3D
/// Tích hợp đầy đủ: On-Demand Loading, Cử chỉ xoay 360/Zoom, Reset Camera, Điều khiển Play/Pause/Tốc độ và Highlight cơ bắp
public struct Exercise3DViewer: View {
    // MARK: - Inputs
    public let remoteModelURL: URL
    public let targetMuscleGroups: [String]
    public var customHighlightColor: Color

    // MARK: - State Management
    @State private var loaderViewModel: Model3DLoaderViewModel
    @State private var sceneConfig: Scene3DConfiguration

    public init(
        remoteModelURL: URL,
        targetMuscleGroups: [String] = ["pectoralis_major", "deltoid_anterior"],
        customHighlightColor: Color = .red,
        verification: AssetVerificationInfo? = nil
    ) {
        self.remoteModelURL = remoteModelURL
        self.targetMuscleGroups = targetMuscleGroups
        self.customHighlightColor = customHighlightColor

        _loaderViewModel = State(initialValue: Model3DLoaderViewModel(
            remoteURL: remoteModelURL,
            verification: verification
        ))
        
        _sceneConfig = State(initialValue: Scene3DConfiguration(
            isPlaying: true,
            playbackSpeed: 1.0,
            highlightedNodeNames: Set(targetMuscleGroups),
            highlightColor: UIColor(customHighlightColor)
        ))
    }

    public var body: some View {
        ZStack {
            // Background tinh tế chuẩn Dark/Light mode
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            switch loaderViewModel.state {
            case .notDownloaded, .downloading:
                loadingView

            case .ready(let localFileURL):
                VStack(spacing: 0) {
                    // 3D Canvas
                    ZStack(alignment: .topTrailing) {
                        SceneKitModelView(fileURL: localFileURL, configuration: $sceneConfig)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        // Nút Reset góc nhìn Camera & Chế độ xem nhanh
                        topOverlayControls
                    }

                    // Thanh điều khiển dưới cùng (Controls Bar)
                    bottomAnimationControlBar
                }

            case .failed(let errorDescription):
                errorView(description: errorDescription)
            }
        }
        .task {
            await loaderViewModel.loadModel()
        }
        .onDisappear {
            // Giải phóng ngay animation và highlight khi View biến mất khỏi màn hình
            sceneConfig.isPlaying = false
            sceneConfig.highlightedNodeNames.removeAll()
        }
        .onChange(of: targetMuscleGroups) { _, newMuscles in
            sceneConfig.highlightedNodeNames = Set(newMuscles)
        }
    }

    // MARK: - Subviews

    /// Giao diện đang tải dữ liệu với thanh Progress mượt mà
    private var loadingView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 6)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: CGFloat(loaderViewModel.progress))
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.2), value: loaderViewModel.progress)

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }

            VStack(spacing: 6) {
                Text("Đang nạp mô hình giải phẫu 3D...")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("\(Int(loaderViewModel.progress * 100))%")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
    }

    /// Nút tiện ích góc trên (Reset Camera & Thông tin cơ mục tiêu)
    private var topOverlayControls: some View {
        HStack {
            // Tag các nhóm cơ được tô sáng
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(targetMuscleGroups, id: \.self) { muscle in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(customHighlightColor)
                                .frame(width: 8, height: 8)
                            Text(muscle.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.caption2.bold())
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial, in: Capsule())
                    }
                }
                .padding(.leading, 16)
            }

            Spacer()

            // Nút Reset Camera
            Button {
                withAnimation {
                    sceneConfig.shouldResetCamera = true
                }
            } label: {
                Image(systemName: "camera.metering.center.weighted")
                    .font(.callout)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 16)
            .accessibilityLabel("Đặt lại góc nhìn")
        }
        .padding(.top, 16)
    }

    /// Thanh công cụ điều khiển chuyển động (Play/Pause, Tốc độ 0.5x, 1.0x)
    private var bottomAnimationControlBar: some View {
        HStack(spacing: 24) {
            // Nút Chuyển đổi tốc độ Playback (0.5x <-> 1.0x)
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    sceneConfig.playbackSpeed = (sceneConfig.playbackSpeed == 1.0) ? 0.5 : 1.0
                }
            } label: {
                HStack(spacing: 2) {
                    Image(systemName: "gauge.with.needle")
                    Text(String(format: "%.1fx", sceneConfig.playbackSpeed))
                        .fontWeight(.semibold)
                }
                .font(.footnote)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)

            // Nút Play / Pause
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    sceneConfig.isPlaying.toggle()
                }
            } label: {
                Image(systemName: sceneConfig.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(
                        Circle().fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    )
                    .shadow(color: .blue.opacity(0.35), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)

            // Nút Bật / Tắt Highlight Cơ bắp
            Button {
                withAnimation {
                    if sceneConfig.highlightedNodeNames.isEmpty {
                        sceneConfig.highlightedNodeNames = Set(targetMuscleGroups)
                    } else {
                        sceneConfig.highlightedNodeNames.removeAll()
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: sceneConfig.highlightedNodeNames.isEmpty ? "sparkles" : "sparkles.rectangle.stack.fill")
                    Text(sceneConfig.highlightedNodeNames.isEmpty ? "Tô cơ" : "Tắt tô")
                        .fontWeight(.semibold)
                }
                .font(.footnote)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    sceneConfig.highlightedNodeNames.isEmpty
                    ? Color.secondary.opacity(0.15)
                    : customHighlightColor.opacity(0.2),
                    in: Capsule()
                )
                .foregroundStyle(sceneConfig.highlightedNodeNames.isEmpty ? .primary : customHighlightColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    /// Giao diện báo lỗi trực quan kèm nút thử lại
    private func errorView(description: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "cube.transparent.fill")
                .font(.system(size: 54))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text("Không thể hiển thị mô hình 3D")
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Button {
                Task {
                    await loaderViewModel.loadModel()
                }
            } label: {
                Label("Tải lại", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    }
}
