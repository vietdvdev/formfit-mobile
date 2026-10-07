import Foundation

/// Các lỗi phát sinh trong quá trình tương tác với HealthKit
public enum HealthKitError: LocalizedError, Sendable {
    case notAvailableOnDevice
    case permissionDenied
    case queryFailed(reason: String)
    case saveWorkoutFailed(reason: String)

    public var errorDescription: String? {
        switch self {
        case .notAvailableOnDevice:
            return "Apple Health không khả dụng trên thiết bị này."
        case .permissionDenied:
            return "Người dùng đã từ chối hoặc chưa cấp quyền truy cập Apple Health."
        case .queryFailed(let reason):
            return "Lỗi truy vấn dữ liệu sức khỏe: \(reason)"
        case .saveWorkoutFailed(let reason):
            return "Không thể lưu buổi tập vào Apple Health: \(reason)"
        }
    }
}
