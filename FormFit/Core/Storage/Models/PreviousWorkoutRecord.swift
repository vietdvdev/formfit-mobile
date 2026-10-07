import Foundation

/// Dữ liệu giả lập thành tích buổi tập liền trước (Previous Performance)
public struct PreviousWorkoutRecord {
    public static func getPreviousPerformance(exerciseId: String, setNumber: Int) -> String {
        switch exerciseId {
        case "bench_press", "barbell_bench_press":
            switch setNumber {
            case 1: return "60kg × 12"
            case 2: return "70kg × 10"
            case 3: return "80kg × 8"
            case 4: return "85kg × 6"
            default: return "70kg × 8"
            }
        case "squat", "barbell_back_squat":
            switch setNumber {
            case 1: return "80kg × 10"
            case 2: return "90kg × 8"
            case 3: return "100kg × 6"
            default: return "90kg × 8"
            }
        default:
            return "\(15 + setNumber * 5)kg × 10"
        }
    }
}
