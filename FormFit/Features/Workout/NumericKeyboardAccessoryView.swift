import SwiftUI

/// Loại giá trị đang được nhập bằng bàn phím số
public enum ActiveInputField: Hashable, Sendable {
    case weight(exerciseId: UUID, setId: UUID)
    case reps(exerciseId: UUID, setId: UUID)
}

/// Thanh công cụ phụ trợ (Accessory Toolbar) gắn phía trên bàn phím số
/// Hỗ trợ các nút thao tác nhanh (+1.25, +2.5, +5kg hoặc +1, +5 reps) và nút Xong (Done)
public struct NumericKeyboardAccessoryView: View {
    public let activeField: ActiveInputField?
    public let onAddAmount: (Double) -> Void
    public let onDone: () -> Void

    public init(
        activeField: ActiveInputField?,
        onAddAmount: @escaping (Double) -> Void,
        onDone: @escaping () -> Void
    ) {
        self.activeField = activeField
        self.onAddAmount = onAddAmount
        self.onDone = onDone
    }

    public var body: some View {
        HStack(spacing: 8) {
            // Danh sách các phím tăng nhanh phụ thuộc vào trường đang focus
            if let field = activeField {
                switch field {
                case .weight:
                    quickIncrementButton(label: "+1.25 kg", amount: 1.25)
                    quickIncrementButton(label: "+2.5 kg", amount: 2.5)
                    quickIncrementButton(label: "+5 kg", amount: 5.0)
                case .reps:
                    quickIncrementButton(label: "+1 rep", amount: 1.0)
                    quickIncrementButton(label: "+2 reps", amount: 2.0)
                    quickIncrementButton(label: "+5 reps", amount: 5.0)
                }
            }

            Spacer()

            // Nút hoàn tất / ẩn bàn phím
            Button(action: onDone) {
                Text("Xong")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.blue, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(uiColor: .secondarySystemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.primary.opacity(0.08)),
            alignment: .top
        )
    }

    private func quickIncrementButton(label: String, amount: Double) -> some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
            onAddAmount(amount)
        } label: {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(uiColor: .tertiarySystemFill), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.primary)
        }
    }
}
