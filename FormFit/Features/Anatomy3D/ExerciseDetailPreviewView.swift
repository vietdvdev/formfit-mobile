import SwiftUI

/// Màn hình mẫu hiển thị chi tiết bài tập có tích hợp Exercise3DViewer
public struct ExerciseDetailPreviewView: View {
    @State private var selectedMuscles: [String] = ["pectoralis_major", "deltoid_anterior"]

    private let sampleModelURL = URL(string: "https://developer.apple.com/augmented-reality/quick-look/models/retrotv/tv_retro.usdz")!

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Khung hiển thị 3D chính
                Exercise3DViewer(
                    remoteModelURL: sampleModelURL,
                    targetMuscleGroups: selectedMuscles,
                    customHighlightColor: .red
                )
                .frame(height: 380)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding()

                // Thông tin bài tập chi tiết bên dưới
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Barbell Bench Press")
                                .font(.title2.bold())
                            Text("Đẩy tạ đòn trên ghế phẳng • Ngực chính")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nhóm cơ tác động")
                                .font(.headline)

                            HStack {
                                MuscleChip(title: "Ngực lớn (Pectoralis Major)", isPrimary: true)
                                MuscleChip(title: "Cơ vai trước (Anterior Deltoid)", isPrimary: false)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hướng dẫn kỹ thuật")
                                .font(.headline)
                            Text("1. Nằm vững chãi trên ghế phẳng, mắt nhìn thẳng dưới thanh đòn.\n2. Hít sâu, siết bả vai và hạ tạ có kiểm soát chạm nhẹ ngực dưới (Pha Eccentric).\n3. Thở ra, dồn lực ngực đẩy thanh tạ dứt khoát về vị trí ban đầu (Pha Concentric).")
                                .font(.footnote)
                                .lineSpacing(4)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Chi tiết bài tập")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct MuscleChip: View {
    let title: String
    let isPrimary: Bool

    var body: some View {
        Text(title)
            .font(.caption2.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isPrimary ? Color.red.opacity(0.15) : Color.blue.opacity(0.15), in: Capsule())
            .foregroundStyle(isPrimary ? Color.red : Color.blue)
    }
}

#Preview {
    ExerciseDetailPreviewView()
}
