import SwiftUI
import Observation

/// ViewModel mẫu minh họa cách View / SwiftUI Component quan sát tiến trình tải model 3D
@Observable
@MainActor
public final class Model3DLoaderViewModel {
    public var state: AssetDownloadState = .notDownloaded
    public var progress: Double = 0.0
    public var localFileURL: URL?

    private let remoteURL: URL
    private let verification: AssetVerificationInfo?
    private let manager: AssetDownloadManager

    public init(
        remoteURL: URL,
        verification: AssetVerificationInfo? = nil,
        manager: AssetDownloadManager = .shared
    ) {
        self.remoteURL = remoteURL
        self.verification = verification
        self.manager = manager
    }

    /// Bắt đầu tải model hoặc lấy từ cache
    public func loadModel() async {
        // Kiểm tra nhanh trên disk
        let isCached = await manager.isAssetCached(for: remoteURL, verification: verification)
        if isCached {
            let localURL = await manager.localCachedURL(for: remoteURL)
            self.localFileURL = localURL
            self.progress = 1.0
            self.state = .ready(localURL: localURL)
            return
        }

        self.state = .downloading(progress: 0.0)
        self.progress = 0.0

        do {
            let localURL = try await manager.getModelURL(
                from: remoteURL,
                verification: verification,
                onProgress: { [weak self] progressValue in
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        self.progress = progressValue
                        self.state = .downloading(progress: progressValue)
                    }
                }
            )

            self.localFileURL = localURL
            self.progress = 1.0
            self.state = .ready(localURL: localURL)
        } catch {
            self.state = .failed(errorDescription: error.localizedDescription)
        }
    }
}
