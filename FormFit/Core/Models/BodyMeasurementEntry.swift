import Foundation

/// Bản ghi số đo cơ thể tại một mốc thời gian
public struct BodyMeasurementEntry: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let date: Date
    public let weightKg: Double
    public let chestCm: Double
    public let waistCm: Double
    public let hipsCm: Double
    public let armsCm: Double

    public init(
        id: UUID = UUID(),
        date: Date,
        weightKg: Double,
        chestCm: Double,
        waistCm: Double,
        hipsCm: Double,
        armsCm: Double
    ) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.chestCm = chestCm
        self.waistCm = waistCm
        self.hipsCm = hipsCm
        self.armsCm = armsCm
    }
}

/// Bản ghi ảnh chụp tiến trình cơ thể
public struct ProgressPhotoEntry: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let date: Date
    public let imageLocalURL: URL?
    public let systemPlaceholderName: String
    public let tag: String // "Front", "Side", "Back"

    public init(
        id: UUID = UUID(),
        date: Date,
        imageLocalURL: URL? = nil,
        systemPlaceholderName: String = "figure.walk",
        tag: String = "Front"
    ) {
        self.id = id
        self.date = date
        self.imageLocalURL = imageLocalURL
        self.systemPlaceholderName = systemPlaceholderName
        self.tag = tag
    }
}

/// Dữ liệu mẫu số đo và ảnh tiến trình phục vụ biểu đồ Charts
public struct MockBodyProgressData {
    public static func generateSampleMeasurements() -> [BodyMeasurementEntry] {
        let calendar = Calendar.current
        var entries: [BodyMeasurementEntry] = []
        let today = Date()

        // 8 tuần đo gần nhất
        let samples: [(weeksAgo: Int, weight: Double, chest: Double, waist: Double, hips: Double, arms: Double)] = [
            (8, 76.5, 96.0, 84.0, 99.0, 34.0),
            (7, 76.0, 96.5, 83.5, 98.5, 34.2),
            (6, 75.4, 97.0, 82.5, 98.0, 34.5),
            (5, 74.8, 97.5, 81.8, 97.5, 35.0),
            (4, 74.2, 98.0, 81.0, 97.0, 35.2),
            (3, 73.6, 98.5, 80.2, 96.5, 35.5),
            (2, 73.0, 99.0, 79.5, 96.0, 35.8),
            (1, 72.4, 99.5, 78.8, 95.5, 36.0),
            (0, 72.0, 100.0, 78.0, 95.0, 36.2)
        ]

        for s in samples {
            if let entryDate = calendar.date(byAdding: .weekOfYear, value: -s.weeksAgo, to: today) {
                entries.append(BodyMeasurementEntry(
                    date: entryDate,
                    weightKg: s.weight,
                    chestCm: s.chest,
                    waistCm: s.waist,
                    hipsCm: s.hips,
                    armsCm: s.arms
                ))
            }
        }

        return entries.sorted(by: { $0.date < $1.date })
    }
}
