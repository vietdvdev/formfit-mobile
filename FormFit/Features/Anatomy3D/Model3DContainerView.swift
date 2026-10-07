import SwiftUI
import SceneKit
import RealityKit

/// Giao diện mẫu tải và hiển thị mô hình 3D (.usdz / .glb) với trạng thái On-Demand
public struct Model3DContainerView: View {
    @State private var viewModel: Model3DLoaderViewModel

    public init(remoteURL: URL, verification: AssetVerificationInfo? = nil) {
        _viewModel = State(initialValue: Model3DLoaderViewModel(remoteURL: remoteURL, verification: verification))
    }

    public var body: some View {
        ZStack {
            Color(.systemBackground)

            switch viewModel.state {
            case .notDownloaded:
                VStack(spacing: 12) {
                    Image(systemName: "cube.transparent")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Mô hình 3D chưa được tải")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Tải mô hình") {
                        Task {
                            await viewModel.loadModel()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

            case .downloading(let progress):
                VStack(spacing: 16) {
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(.linear)
                        .tint(.blue)
                        .frame(width: 200)

                    Text("Đang tải dữ liệu 3D... \(Int(progress * 100))%")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

            case .ready(let localURL):
                VStack {
                    // Preview hoặc render Model 3D từ file local
                    Label("Mô hình 3D sẵn sàng", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .padding(.top, 8)

                    Text("Đường dẫn file: \(localURL.lastPathComponent)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    Spacer()
                }

            case .failed(let errorDescription):
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    Text("Không thể tải mô hình 3D")
                        .font(.headline)
                    Text(errorDescription)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    Button("Thử lại") {
                        Task {
                            await viewModel.loadModel()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }
        .task {
            // Tự động kích hoạt tải khi View xuất hiện
            await viewModel.loadModel()
        }
    }
}
