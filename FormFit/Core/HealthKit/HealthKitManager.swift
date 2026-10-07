import Foundation
import HealthKit
import Observation

/// Quản lý toàn bộ tích hợp giữa FormFit và Apple Health (HealthKit)
/// Đảm bảo tương thích hoàn toàn, không crash khi bị từ chối quyền hoặc chạy trên iPad/Simulator không hỗ trợ
@Observable
@MainActor
public final class HealthKitManager {
    // MARK: - Singleton
    public static let shared = HealthKitManager()

    // MARK: - Observable States
    public private(set) var isHealthKitAvailable: Bool = false
    public private(set) var isAuthorized: Bool = false
    public private(set) var currentHeartRate: Double = 0.0 // BPM
    public private(set) var currentActiveEnergyBurned: Double = 0.0 // kCal

    // MARK: - Internal Properties
    private let healthStore: HKHealthStore?
    private var heartRateQuery: HKAnchoredObjectQuery?

    // MARK: - Health Types
    private let workoutType = HKObjectType.workoutType()
    
    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    private let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!

    private init() {
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
            self.isHealthKitAvailable = true
        } else {
            self.healthStore = nil
            self.isHealthKitAvailable = false
        }
    }

    // MARK: - 1. Request Authorization (Xin cấp quyền)

    /// Xin quyền truy cập Apple Health cho Workout, Nhịp tim và Active Energy
    /// Trả về true nếu quá trình xin quyền hoàn tất mà không gặp lỗi hệ thống
    @discardableResult
    public func requestAuthorization() async -> Bool {
        guard let healthStore = healthStore, isHealthKitAvailable else {
            print("[HealthKitManager] ⚠️ Apple Health không khả dụng trên thiết bị này.")
            return false
        }

        let typesToShare: Set<HKSampleType> = [
            workoutType,
            activeEnergyType
        ]

        let typesToRead: Set<HKObjectType> = [
            workoutType,
            heartRateType,
            activeEnergyType
        ]

        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            self.isAuthorized = true
            return true
        } catch {
            print("[HealthKitManager] ⚠️ Người dùng từ chối hoặc lỗi xin quyền HealthKit: \(error.localizedDescription)")
            self.isAuthorized = false
            return false
        }
    }

    // MARK: - 2. Realtime Heart Rate Query (HKAnchoredObjectQuery)

    /// Bắt đầu đọc nhịp tim thời gian thực từ Apple Watch / cảm biến nhịp tim
    public func startHeartRateMonitoring() {
        guard let healthStore = healthStore, isHealthKitAvailable else { return }

        // Dừng query cũ nếu có
        stopHeartRateMonitoring()

        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)

        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, error in
            if let error = error {
                print("[HealthKitManager] ⚠️ Lỗi Anchored Query ban đầu: \(error.localizedDescription)")
                return
            }
            self?.processHeartRateSamples(samples)
        }

        // Cập nhật liên tục khi có mẫu nhịp tim mới từ Apple Watch
        query.updateHandler = { [weak self] _, samples, _, _, error in
            if let error = error {
                print("[HealthKitManager] ⚠️ Lỗi cập nhật nhịp tim realtime: \(error.localizedDescription)")
                return
            }
            self?.processHeartRateSamples(samples)
        }

        self.heartRateQuery = query
        healthStore.execute(query)
    }

    /// Dừng theo dõi nhịp tim khi kết thúc buổi tập
    public func stopHeartRateMonitoring() {
        guard let healthStore = healthStore, let query = heartRateQuery else { return }
        healthStore.stop(query)
        self.heartRateQuery = nil
        self.currentHeartRate = 0.0
    }

    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let quantitySamples = samples as? [HKQuantitySample], let lastSample = quantitySamples.last else { return }

        let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        let bpm = lastSample.quantity.doubleValue(for: heartRateUnit)

        Task { @MainActor [weak self] in
            self?.currentHeartRate = bpm
        }
    }

    // MARK: - 3. Save Workout to Apple Health (HKWorkout)

    /// Lưu bản ghi buổi tập kháng lực vào Apple Health
    /// - Parameters:
    ///   - startDate: Thời gian bắt đầu buổi tập
    ///   - endDate: Thời gian hoàn thành buổi tập
    ///   - activeCalories: Năng lượng đốt cháy ước tính hoặc thực tế (kCal)
    /// - Returns: Đối tượng HKWorkout đã lưu thành công
    @discardableResult
    public func saveStrengthWorkout(
        startDate: Date,
        endDate: Date,
        activeCalories: Double
    ) async throws -> HKWorkout? {
        guard let healthStore = healthStore, isHealthKitAvailable else {
            throw HealthKitError.notAvailableOnDevice
        }

        // 1. Khởi tạo lượng Active Energy Burned
        let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: max(0, activeCalories))

        // 2. Tạo đối tượng HKWorkout với Activity Type là .traditionalStrengthTraining
        let workout = HKWorkout(
            activityType: .traditionalStrengthTraining,
            start: startDate,
            end: endDate,
            duration: endDate.timeIntervalSince(startDate),
            totalEnergyBurned: energyQuantity,
            totalDistance: nil,
            metadata: [
                HKMetadataKeyWorkoutBrandName: "FormFit",
                HKMetadataKeyIndoorWorkout: true
            ]
        )

        // 3. Thực hiện lưu vào Health Store bất đồng bộ
        do {
            try await healthStore.save(workout)

            // Lưu kèm mẫu định lượng Active Energy Sample gắn liền với buổi tập
            let energySample = HKQuantitySample(
                type: activeEnergyType,
                quantity: energyQuantity,
                start: startDate,
                end: endDate
            )
            try await healthStore.addSamples([energySample], to: workout)

            return workout
        } catch {
            print("[HealthKitManager] ⚠️ Lỗi khi lưu HKWorkout: \(error.localizedDescription)")
            throw HealthKitError.saveWorkoutFailed(reason: error.localizedDescription)
        }
    }

    /// Tính toán calo đốt cháy ước tính dựa trên thời gian tập nếu người dùng không đeo Apple Watch
    public func estimateCaloriesBurned(durationSeconds: TimeInterval, userWeightKg: Double = 70.0) -> Double {
        // MET (Metabolic Equivalent of Task) cho tập gym kháng lực trung bình ~ 5.0 METs
        // Calo = MET * Cân nặng (kg) * Thời gian (giờ)
        let hours = durationSeconds / 3600.0
        let met = 5.0
        return max(10.0, met * userWeightKg * hours)
    }
}
