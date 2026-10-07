import Foundation

/// Định nghĩa các lỗi có thể xảy ra trong quá trình quản lý và tải mô hình 3D
public enum AssetDownloadError: LocalizedError, Sendable {
    case invalidRemoteURL
    case destinationUnavailable
    case downloadFailed(underlyingError: Error)
    case invalidHTTPResponse(statusCode: Int)
    case fileCorrupted(reason: String)
    case timeout
    case fileNotFound
    case diskWriteFailed(underlyingError: Error)

    public var errorDescription: String? {
        switch self {
        case .invalidRemoteURL:
            return "URL tải mô hình không hợp lệ."
        case .destinationUnavailable:
            return "Không thể khởi tạo hoặc truy cập thư mục lưu trữ cache trên thiết bị."
        case .downloadFailed(let error):
            return "Tải file thất bại: \(error.localizedDescription)"
        case .invalidHTTPResponse(let code):
            return "Phản hồi máy chủ không hợp lệ (HTTP \(code))."
        case .fileCorrupted(let reason):
            return "File mô hình bị lỗi hoặc không toàn vẹn: \(reason)"
        case .timeout:
            return "Quá thời gian kết nối (Timeout) khi tải file."
        case .fileNotFound:
            return "Không tìm thấy file mô hình tại đường dẫn yêu cầu."
        case .diskWriteFailed(let error):
            return "Ghi dữ liệu vào ổ đĩa thất bại: \(error.localizedDescription)"
        }
    }
}
