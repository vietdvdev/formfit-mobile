import SwiftUI

/// Định nghĩa 5 Tab chính của ứng dụng FormFit
public enum AppTab: String, CaseIterable, Identifiable, Hashable, Sendable {
    case workout = "workout"
    case exercises = "exercises"
    case nutrition = "nutrition"
    case coaching = "coaching"
    case profile = "profile"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .workout: return "Tập Luyện"
        case .exercises: return "Bài Tập"
        case .nutrition: return "Dinh Dưỡng"
        case .coaching: return "HLV (PT)"
        case .profile: return "Hồ Sơ"
        }
    }

    public var iconName: String {
        switch self {
        case .workout: return "figure.strengthtraining.traditional"
        case .exercises: return "dumbbell.fill"
        case .nutrition: return "fork.knife"
        case .coaching: return "person.2.fill"
        case .profile: return "chart.bar.xaxis"
        }
    }
}
