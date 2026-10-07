import Foundation
import CryptoKit

/// Trạng thái tải của một Model 3D Asset
public enum AssetDownloadState: Sendable, Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case ready(localURL: URL)
    case failed(errorDescription: String)
}

/// Metadata kiểm tra tính toàn vẹn của asset trước và sau khi tải
public struct AssetVerificationInfo: Sendable {
    public let expectedByteSize: Int64?
    public let expectedSHA256: String?

    public init(expectedByteSize: Int64? = nil, expectedSHA256: String? = nil) {
        self.expectedByteSize = expectedByteSize
        self.expectedSHA256 = expectedSHA256?.lowercased()
    }
}

/// Actor quản lý việc kiểm tra, tải ngầm và cache các file 3D (.usdz / .glb) theo cơ chế On-Demand Streaming.
/// Đảm bảo thread-safe hoàn toàn với Swift Concurrency, không gây nghẽn Main Thread.
public actor AssetDownloadManager: NSObject {
    
    // MARK: - Singleton
    public static let shared = AssetDownloadManager()

    // MARK: - Properties
    private let fileManager: FileManager
    private let modelsDirectory: URL
    private let sessionConfiguration: URLSessionConfiguration
    
    /// Lưu trữ các Task download đang diễn ra để tránh tải trùng lặp (Deduplication)
    private var activeDownloadTasks: [URL: Task<URL, Error>] = [:]
    
    /// Map URL -> Danh sách các progress handlers đang lắng nghe
    private var progressContinuations: [URL: [AsyncStream<Double>.Continuation]] = [:]

    // MARK: - Initialization
    public init(
        fileManager: FileManager = .default,
        customCacheDirectoryName: String = "models",
        timeoutInterval: TimeInterval = 60.0
    ) {
        self.fileManager = fileManager
        
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        self.modelsDirectory = cachesDirectory.appendingPathComponent(customCacheDirectoryName, isDirectory: true)

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutInterval
        config.timeoutIntervalForResource = timeoutInterval * 2
        config.waitsForConnectivity = true
        self.sessionConfiguration = config

        super.init()

        createModelsDirectoryIfNeeded()
    }

    // MARK: - Directory Management
    private func createModelsDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: modelsDirectory.path) {
            do {
                try fileManager.createDirectory(at: modelsDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("[AssetDownloadManager] ⚠️ Không thể tạo thư mục cache models: \(error.localizedDescription)")
            }
        }
    }

    /// Trả về đường dẫn local file dự kiến dựa trên remote URL
    public func localCachedURL(for remoteURL: URL) -> URL {
        let fileName = remoteURL.lastPathComponent
        return modelsDirectory.appendingPathComponent(fileName)
    }

    /// Kiểm tra file model đã tồn tại trong local disk và hợp lệ chưa
    public func isAssetCached(for remoteURL: URL, verification: AssetVerificationInfo? = nil) -> Bool {
        let destination = localCachedURL(for: remoteURL)
        guard fileManager.fileExists(atPath: destination.path) else {
            return false
        }
        
        // Nếu có yêu cầu verify kích thước file
        if let expectedSize = verification?.expectedByteSize, expectedSize > 0 {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: destination.path)
                if let fileSize = attributes[.size] as? Int64, fileSize != expectedSize {
                    return false
                }
            } catch {
                return false
            }
        }

        // Nếu có yêu cầu checksum SHA-256
        if let expectedSHA = verification?.expectedSHA256, !expectedSHA.isEmpty {
            guard let actualSHA = computeSHA256(for: destination), actualSHA == expectedSHA else {
                return false
            }
        }

        return true
    }

    // MARK: - Main Streaming / Download Logic

    /// Tải hoặc lấy URL file cục bộ cho Model 3D.
    /// - Parameters:
    ///   - remoteURL: Đường dẫn tải file từ remote (CDN / S3).
    ///   - verification: Thông số xác minh kích thước/checksum (tùy chọn).
    ///   - onProgress: Closure thông báo tiến trình tải từ 0.0 -> 1.0 (chạy trên background/caller thread).
    /// - Returns: URL trỏ tới file đã cache trên máy.
    public func getModelURL(
        from remoteURL: URL,
        verification: AssetVerificationInfo? = nil,
        onProgress: (@Sendable (Double) -> Void)? = nil
    ) async throws -> URL {
        createModelsDirectoryIfNeeded()
        let destinationURL = localCachedURL(for: remoteURL)

        // 1. Kiểm tra nếu file đã có sẵn trong cache và còn toàn vẹn
        if isAssetCached(for: remoteURL, verification: verification) {
            onProgress?(1.0)
            return destinationURL
        }

        // 2. Tránh duplicate download nếu đang có task tải URL này
        if let existingTask = activeDownloadTasks[remoteURL] {
            return try await existingTask.value
        }

        // 3. Khởi tạo tác vụ download mới
        let downloadTask = Task<URL, Error> { [weak self] () -> URL in
            guard let self = self else { throw AssetDownloadError.destinationUnavailable }
            return try await self.performDownload(
                from: remoteURL,
                destinationURL: destinationURL,
                verification: verification,
                onProgress: onProgress
            )
        }

        activeDownloadTasks[remoteURL] = downloadTask

        do {
            let resultURL = try await downloadTask.value
            activeDownloadTasks.removeValue(forKey: remoteURL)
            return resultURL
        } catch {
            activeDownloadTasks.removeValue(forKey: remoteURL)
            // Xóa file tạm hoặc file hỏng nếu có
            try? fileManager.removeItem(at: destinationURL)
            throw error
        }
    }

    /// Cung cấp AsyncStream để theo dõi tiến trình tải realtime
    public func progressStream(for remoteURL: URL) -> AsyncStream<Double> {
        AsyncStream { continuation in
            if self.isAssetCached(for: remoteURL) {
                continuation.yield(1.0)
                continuation.finish()
                return
            }
            
            var continuations = self.progressContinuations[remoteURL] ?? []
            continuations.append(continuation)
            self.progressContinuations[remoteURL] = continuations
            
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.removeContinuation(continuation, for: remoteURL)
                }
            }
        }
    }

    private func removeContinuation(_ continuation: AsyncStream<Double>.Continuation, for url: URL) {
        guard var list = progressContinuations[url] else { return }
        list.removeAll { $0 == continuation }
        if list.isEmpty {
            progressContinuations.removeValue(forKey: url)
        } else {
            progressContinuations[url] = list
        }
    }

    private func broadcastProgress(_ progress: Double, for remoteURL: URL) {
        if let continuations = progressContinuations[remoteURL] {
            for cont in continuations {
                cont.yield(progress)
                if progress >= 1.0 {
                    cont.finish()
                }
            }
            if progress >= 1.0 {
                progressContinuations.removeValue(forKey: remoteURL)
            }
        }
    }

    // MARK: - Network Download Implementation

    private func performDownload(
        from remoteURL: URL,
        destinationURL: URL,
        verification: AssetVerificationInfo?,
        onProgress: (@Sendable (Double) -> Void)?
    ) async throws -> URL {
        let session = URLSession(configuration: sessionConfiguration)

        var request = URLRequest(url: remoteURL)
        request.httpMethod = "GET"

        let (asyncBytes, response): (URLSession.AsyncBytes, URLResponse)
        do {
            (asyncBytes, response) = try await session.bytes(for: request)
        } catch let urlError as URLError {
            if urlError.code == .timedOut {
                throw AssetDownloadError.timeout
            }
            throw AssetDownloadError.downloadFailed(underlyingError: urlError)
        } catch {
            throw AssetDownloadError.downloadFailed(underlyingError: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AssetDownloadError.invalidRemoteURL
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AssetDownloadError.invalidHTTPResponse(statusCode: httpResponse.statusCode)
        }

        let expectedContentLength = response.expectedContentLength
        let totalBytes: Int64 = expectedContentLength > 0 ? expectedContentLength : (verification?.expectedByteSize ?? -1)

        // Lưu vào file tạm thời trong quá trình stream bytes để tránh corrupt file chính
        let tempFileURL = modelsDirectory.appendingPathComponent(UUID().uuidString + ".tmp")
        
        guard let outputStream = OutputStream(url: tempFileURL, append: false) else {
            throw AssetDownloadError.diskWriteFailed(
                underlyingError: NSError(domain: "AssetDownloadManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Không mở được OutputStream"])
            )
        }
        outputStream.open()
        defer { outputStream.close() }

        var downloadedBytes: Int64 = 0
        var buffer = [UInt8]()
        let bufferCapacity = 64 * 1024 // 64KB chunk buffer

        for try await byte in asyncBytes {
            buffer.append(byte)
            downloadedBytes += 1

            if buffer.count >= bufferCapacity {
                try writeChunk(buffer, to: outputStream)
                buffer.removeAll(keepingCapacity: true)

                if totalBytes > 0 {
                    let progress = min(1.0, Double(downloadedBytes) / Double(totalBytes))
                    onProgress?(progress)
                    broadcastProgress(progress, for: remoteURL)
                }
            }
        }

        // Ghi phần bytes còn lại trong buffer
        if !buffer.isEmpty {
            try writeChunk(buffer, to: outputStream)
            buffer.removeAll()
        }

        // Hoàn tất tải
        onProgress?(1.0)
        broadcastProgress(1.0, for: remoteURL)

        // Kiểm tra file size
        if let expectedSize = verification?.expectedByteSize, expectedSize > 0, downloadedBytes != expectedSize {
            try? fileManager.removeItem(at: tempFileURL)
            throw AssetDownloadError.fileCorrupted(
                reason: "Kích thước tải về (\(downloadedBytes) bytes) không khớp với mong đợi (\(expectedSize) bytes)."
            )
        }

        // Kiểm tra Checksum SHA256 nếu có
        if let expectedSHA = verification?.expectedSHA256, !expectedSHA.isEmpty {
            guard let actualSHA = computeSHA256(for: tempFileURL), actualSHA == expectedSHA else {
                try? fileManager.removeItem(at: tempFileURL)
                throw AssetDownloadError.fileCorrupted(reason: "Mã băm SHA-256 không trùng khớp.")
            }
        }

        // Chuyển file từ temp sang destination chính thức
        if fileManager.fileExists(atPath: destinationURL.path) {
            try? fileManager.removeItem(at: destinationURL)
        }

        do {
            try fileManager.moveItem(at: tempFileURL, to: destinationURL)
        } catch {
            try? fileManager.removeItem(at: tempFileURL)
            throw AssetDownloadError.diskWriteFailed(underlyingError: error)
        }

        return destinationURL
    }

    private func writeChunk(_ chunk: [UInt8], to stream: OutputStream) throws {
        var bytesWritten = 0
        while bytesWritten < chunk.count {
            let result = chunk.withUnsafeBufferPointer { ptr in
                guard let base = ptr.baseAddress else { return 0 }
                return stream.write(base.advanced(by: bytesWritten), maxLength: chunk.count - bytesWritten)
            }
            if result < 0 {
                throw stream.streamError ?? NSError(domain: "AssetDownloadManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Lỗi ghi byte stream"])
            }
            bytesWritten += result
        }
    }

    // MARK: - SHA256 Checksum Calculation
    private func computeSHA256(for fileURL: URL) -> String? {
        guard let fileHandle = try? FileHandle(forReadingFrom: fileURL) else { return nil }
        defer { try? fileHandle.close() }

        var hasher = SHA256()
        let bufferSize = 64 * 1024

        while autoreleasepool(invoking: {
            let data = fileHandle.readData(ofLength: bufferSize)
            if !data.isEmpty {
                hasher.update(data: data)
                return true
            }
            return false
        }) {}

        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Cache Cleanup & Management

    /// Xóa toàn bộ file cache models 3D
    public func clearAllCache() throws {
        if fileManager.fileExists(atPath: modelsDirectory.path) {
            try fileManager.removeItem(at: modelsDirectory)
            createModelsDirectoryIfNeeded()
        }
    }

    /// Xóa riêng 1 model theo URL
    public func removeCache(for remoteURL: URL) throws {
        let destination = localCachedURL(for: remoteURL)
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
    }

    /// Tính tổng dung lượng (bytes) của các model 3D đang được cache trên máy
    public func calculateTotalCacheSize() -> Int64 {
        guard let files = try? fileManager.contentsOfDirectory(at: modelsDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        var totalSize: Int64 = 0
        for file in files {
            if let resources = try? file.resourceValues(forKeys: [.fileSizeKey]), let size = resources.fileSize {
                totalSize += Int64(size)
            }
        }
        return totalSize
    }
}
