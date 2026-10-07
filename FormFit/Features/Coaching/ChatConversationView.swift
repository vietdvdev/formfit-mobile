import SwiftUI
import AVKit

/// Màn hình Chat trực tiếp giữa Học viên và Huấn luyện viên
/// Hỗ trợ: Bong bóng chat, Video Player inline xem clip sửa form, ScrollViewReader tự động cuộn
public struct ChatConversationView: View {
    public let contractId: Int
    public let partnerName: String
    public let currentUserId: Int

    @State private var messages: [ChatMessageModel] = []
    @State private var inputText: String = ""
    @State private var webSocket = WebSocketChatService.shared
    @State private var selectedVideoURLForFullPlayer: URL?

    public init(
        contractId: Int = 1,
        partnerName: String = "HLV. Hoàng Nam (NASM-CPT)",
        currentUserId: Int = 101
    ) {
        self.contractId = contractId
        self.partnerName = partnerName
        self.currentUserId = currentUserId
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Danh sách tin nhắn cuộn mượt
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(messages) { msg in
                                chatBubble(message: msg)
                                    .id(msg.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let lastId = messages.last?.id {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Thanh soạn tin nhắn dưới cùng
                bottomInputBar
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(partnerName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(webSocket.isConnected ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        Text(webSocket.isConnected ? "Online" : "Connecting...")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear {
                loadInitialMockMessages()
                setupWebSocket()
            }
            .onDisappear {
                webSocket.disconnect()
            }
        }
    }

    // MARK: - Chat Bubble
    private func chatBubble(message: ChatMessageModel) -> some View {
        let isMe = (message.senderId == currentUserId)

        return HStack(alignment: .bottom, spacing: 8) {
            if isMe { Spacer(minLength: 40) }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                switch message.type {
                case .text:
                    if let text = message.message {
                        Text(text)
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                isMe ? Color.blue : Color(uiColor: .secondarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 18)
                            )
                            .foregroundStyle(isMe ? Color.white : Color.primary)
                    }

                case .video:
                    // Inline Video Player Preview cho Clip sửa Form
                    inlineVideoPlayerBubble(message: message, isMe: isMe)

                case .image:
                    // Ảnh đính kèm
                    if let urlStr = message.mediaUrl, let url = URL(string: urlStr) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 220, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }

                // Thời gian gửi
                Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
            }

            if !isMe { Spacer(minLength: 40) }
        }
    }

    // MARK: - Inline Video Bubble
    private func inlineVideoPlayerBubble(message: ChatMessageModel, isMe: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.black.opacity(0.85))
                    .frame(width: 240, height: 160)

                if let videoUrlStr = message.mediaUrl, let videoURL = URL(string: videoUrlStr) {
                    // AVPlayer inline mini preview
                    VideoPlayer(player: AVPlayer(url: videoURL))
                        .frame(width: 240, height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    // Placeholder nếu video demo
                    VStack(spacing: 8) {
                        Image(systemName: "video.badge.waveform.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.cyan)
                        Text("Video phân tích Form (0:15)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                    }
                }
            }

            if let note = message.message {
                Text(note)
                    .font(.footnote)
                    .padding(.horizontal, 6)
                    .foregroundStyle(isMe ? .white : .primary)
            }
        }
        .padding(8)
        .background(
            isMe ? Color.blue : Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 18)
        )
    }

    // MARK: - Bottom Input Bar
    private var bottomInputBar: some View {
        HStack(spacing: 12) {
            // Nút đính kèm Video / Camera sửa form
            Button {
                sendSampleVideoFormFeedback()
            } label: {
                Image(systemName: "video.fill.badge.plus")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }

            // Ô nhập văn bản
            TextField("Nhắn cho PT hoặc gửi video form...", text: $inputText)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(uiColor: .tertiarySystemFill), in: Capsule())

            // Nút gửi
            Button {
                sendTextMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary.opacity(0.4) : .blue)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }

    // MARK: - Actions
    private func sendTextMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        let newMsg = ChatMessageModel(
            id: Int.random(in: 10000...99999),
            contractId: contractId,
            senderId: currentUserId,
            senderName: "Học viên",
            message: text,
            type: .text
        )

        withAnimation {
            messages.append(newMsg)
        }
        inputText = ""
    }

    private func sendSampleVideoFormFeedback() {
        let videoMsg = ChatMessageModel(
            id: Int.random(in: 10000...99999),
            contractId: contractId,
            senderId: currentUserId,
            senderName: "Học viên",
            message: "Em quay clip set cuối Squat 100kg, anh Nam xem giúp em lưng có bị võng không ạ?",
            type: .video,
            mediaUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"
        )
        withAnimation {
            messages.append(videoMsg)
        }
    }

    private func setupWebSocket() {
        webSocket.connect(contractId: contractId)
        webSocket.onMessageReceived = { incomingMessage in
            withAnimation {
                messages.append(incomingMessage)
            }
        }
    }

    private func loadInitialMockMessages() {
        messages = [
            ChatMessageModel(
                id: 1,
                contractId: contractId,
                senderId: 999, // ID của PT
                senderName: partnerName,
                message: "Chào em! Chúc mừng em đã bắt đầu lộ trình cùng anh. Hôm nay em tập theo giáo án Upper Day nhé!",
                type: .text,
                createdAt: Date().addingTimeInterval(-3600)
            ),
            ChatMessageModel(
                id: 2,
                contractId: contractId,
                senderId: 999,
                senderName: partnerName,
                message: "Lưu ý bài Bench Press nhớ giữ góc khuỷu tay 45 độ so với thân người, đừng mở ngang 90 độ sẽ dễ đau vai.",
                type: .text,
                createdAt: Date().addingTimeInterval(-3400)
            )
        ]
    }
}

#Preview {
    ChatConversationView()
}
