import SwiftUI
import Charts

/// Chế độ xem biểu đồ (Cân nặng hoặc Số đo các vòng)
public enum ProgressChartMode: String, CaseIterable, Identifiable {
    case weight = "Cân nặng (kg)"
    case measurements = "Số đo các vòng (cm)"

    public var id: String { rawValue }
}

/// Màn hình theo dõi số đo cơ thể & Kho ảnh tiến trình Before/After
public struct BodyProgressDashboardView: View {
    @State private var measurements: [BodyMeasurementEntry] = MockBodyProgressData.generateSampleMeasurements()
    @State private var selectedChartMode: ProgressChartMode = .weight
    @State private var showCameraSheet: Bool = false
    @State private var capturedPhotos: [UIImage] = []

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Chế độ so sánh Before / After với thanh trượt mượt mà
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("So sánh tiến trình Before / After")
                                .font(.headline)
                            Spacer()
                            Button {
                                showCameraSheet = true
                            } label: {
                                Label("Chụp mới", systemImage: "camera.fill")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.12), in: Capsule())
                                    .foregroundStyle(.blue)
                            }
                        }

                        BeforeAfterSliderView(
                            beforeImage: nil,
                            afterImage: capturedPhotos.last,
                            beforeDateText: "Tuần 1",
                            afterDateText: "Tuần 8"
                        )
                        .frame(height: 320)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                    }

                    // 2. Bộ chuyển đổi Biểu đồ (Cân nặng vs Số đo vòng)
                    Picker("Chế độ xem", selection: $selectedChartMode) {
                        ForEach(ProgressChartMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    // 3. Biểu đồ đường sử dụng Apple Swift Charts Framework
                    chartCardSection

                    // 4. Bảng chỉ số thay đổi gần nhất
                    recentChangesGrid
                }
                .padding(16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Tiến Trình Cơ Thể")
            .sheet(isPresented: $showCameraSheet) {
                ProgressCameraView(ghostImage: capturedPhotos.last) { newPhoto in
                    capturedPhotos.append(newPhoto)
                }
            }
        }
    }

    // MARK: - Swift Charts Section
    private var chartCardSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedChartMode == .weight ? "Biến thiên Cân Nặng (kg)" : "Biến thiên Số đo (cm)")
                        .font(.headline)
                    Text("Cập nhật theo tuần")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                if let latest = measurements.last, let first = measurements.first {
                    let diff = latest.weightKg - first.weightKg
                    Text(String(format: "%.1f kg", diff))
                        .font(.subheadline.bold())
                        .foregroundStyle(diff <= 0 ? .green : .orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background((diff <= 0 ? Color.green : Color.orange).opacity(0.12), in: Capsule())
                }
            }

            // Apple Swift Charts
            Chart {
                if selectedChartMode == .weight {
                    // Biểu đồ đường cân nặng
                    ForEach(measurements) { entry in
                        LineMark(
                            x: .value("Tuần", entry.date, unit: .weekOfYear),
                            y: .value("Cân nặng (kg)", entry.weightKg)
                        )
                        .foregroundStyle(Color.blue)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Tuần", entry.date, unit: .weekOfYear),
                            y: .value("Cân nặng (kg)", entry.weightKg)
                        )
                        .foregroundStyle(Color.blue)
                        .annotation(position: .top) {
                            Text(String(format: "%.1f", entry.weightKg))
                                .font(.system(size: 8).bold())
                                .foregroundStyle(.secondary)
                        }

                        AreaMark(
                            x: .value("Tuần", entry.date, unit: .weekOfYear),
                            yStart: .value("Min", 65.0),
                            yEnd: .value("Cân nặng (kg)", entry.weightKg)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.2), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                } else {
                    // Biểu đồ số đo các vòng: Ngực, Eo, Mông, Bắp tay
                    ForEach(measurements) { entry in
                        LineMark(
                            x: .value("Tuần", entry.date, unit: .weekOfYear),
                            y: .value("Số đo (cm)", entry.chestCm),
                            series: .value("Vòng", "Ngực")
                        )
                        .foregroundStyle(Color.red)
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Tuần", entry.date, unit: .weekOfYear),
                            y: .value("Số đo (cm)", entry.waistCm),
                            series: .value("Vòng", "Eo")
                        )
                        .foregroundStyle(Color.green)
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Tuần", entry.date, unit: .weekOfYear),
                            y: .value("Số đo (cm)", entry.hipsCm),
                            series: .value("Vòng", "Mông")
                        )
                        .foregroundStyle(Color.purple)
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Tuần", entry.date, unit: .weekOfYear),
                            y: .value("Số đo (cm)", entry.armsCm),
                            series: .value("Vòng", "Bắp tay")
                        )
                        .foregroundStyle(Color.orange)
                        .interpolationMethod(.catmullRom)
                    }
                }
            }
            .chartYScale(domain: selectedChartMode == .weight ? 70...78 : 30...105)
            .frame(height: 220)

            // Chú giải màu sắc cho biểu đồ số đo
            if selectedChartMode == .measurements {
                HStack(spacing: 12) {
                    legendItem(title: "Ngực", color: .red)
                    legendItem(title: "Eo", color: .green)
                    legendItem(title: "Mông", color: .purple)
                    legendItem(title: "Tay", color: .orange)
                }
                .font(.caption2.bold())
                .padding(.top, 4)
            }
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.02), radius: 6, x: 0, y: 2)
    }

    private func legendItem(title: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Recent Changes Grid
    private var recentChangesGrid: some View {
        guard let latest = measurements.last, let first = measurements.first else {
            return AnyView(EmptyView())
        }

        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                Text("Biến đổi hình thể (Tuần 1 -> Tuần 8)")
                    .font(.headline)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    metricChangeCard(title: "Vòng Ngực", start: first.chestCm, current: latest.chestCm, unit: "cm", isPositiveGood: true)
                    metricChangeCard(title: "Vòng Eo", start: first.waistCm, current: latest.waistCm, unit: "cm", isPositiveGood: false)
                    metricChangeCard(title: "Vòng Mông", start: first.hipsCm, current: latest.hipsCm, unit: "cm", isPositiveGood: true)
                    metricChangeCard(title: "Bắp Tay", start: first.armsCm, current: latest.armsCm, unit: "cm", isPositiveGood: true)
                }
            }
        )
    }

    private func metricChangeCard(
        title: String,
        start: Double,
        current: Double,
        unit: String,
        isPositiveGood: Bool
    ) -> some View {
        let diff = current - start
        let isGood = isPositiveGood ? (diff >= 0) : (diff <= 0)

        return VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "%.1f", current))
                    .font(.title3.bold())
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 2) {
                    Image(systemName: diff >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text(String(format: "%+.1f", diff))
                }
                .font(.caption2.bold())
                .foregroundStyle(isGood ? .green : .red)
            }
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    BodyProgressDashboardView()
}
