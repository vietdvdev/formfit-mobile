import SwiftUI

/// Component nhỏ hiển thị trạng thái đồng bộ hóa Offline-First trên thanh công cụ hoặc màn hình hồ sơ
public struct SyncStatusIndicatorView: View {
    @State private var syncService = WorkoutSyncService.shared
    @State private var networkMonitor = NetworkMonitor.shared

    public init() {}

    public var body: some View {
        HStack(spacing: 6) {
            if !networkMonitor.isConnected {
                // Biểu tượng Offline
                HStack(spacing: 4) {
                    Image(systemName: "wifi.slash")
                        .font(.caption2)
                    Text("Ngoại tuyến")
                        .font(.caption2.bold())
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.15), in: Capsule())
                .foregroundStyle(.secondary)
            } else {
                switch syncService.syncStatus {
                case .idle:
                    if syncService.pendingSyncCount > 0 {
                        Button {
                            Task {
                                await syncService.triggerSync()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.caption2)
                                Text("Chờ đồng bộ (\(syncService.pendingSyncCount))")
                                    .font(.caption2.bold())
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.15), in: Capsule())
                            .foregroundStyle(.orange)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.icloud.fill")
                                .font(.caption2)
                            Text("Đã đồng bộ")
                                .font(.caption2.bold())
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15), in: Capsule())
                        .foregroundStyle(.green)
                    }

                case .syncing(let count):
                    HStack(spacing: 4) {
                        ProgressView()
                            .controlSize(.mini)
                        Text("Đang đồng bộ \(count) buổi...")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15), in: Capsule())
                    .foregroundStyle(.blue)

                case .success:
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                        Text("Đã tải lên")
                            .font(.caption2.bold())
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.15), in: Capsule())
                    .foregroundStyle(.green)

                case .failed:
                    Button {
                        Task {
                            await syncService.triggerSync()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.icloud.fill")
                                .font(.caption2)
                            Text("Lỗi đồng bộ (Thử lại)")
                                .font(.caption2.bold())
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.15), in: Capsule())
                        .foregroundStyle(.red)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: syncService.syncStatus)
    }
}
