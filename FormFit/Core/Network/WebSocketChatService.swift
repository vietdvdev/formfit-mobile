import Foundation
import Observation

/// Service kết nối WebSocket tới Laravel Reverb (Pusher-compatible protocol)
/// Nhận tin nhắn mới thời gian thực trên kênh private-chat.{contract_id}
@Observable
@MainActor
public final class WebSocketChatService {
    public static let shared = WebSocketChatService()

    public private(set) var isConnected: Bool = false
    public var onMessageReceived: ((ChatMessageModel) -> Void)?

    private var webSocketTask: URLSessionWebSocketTask?
    private var currentContractId: Int?
    private let session = URLSession(configuration: .default)

    private init() {}

    /// Kết nối vào Private Channel của hợp đồng
    public func connect(contractId: Int, authToken: String? = nil) {
        disconnect()

        self.currentContractId = contractId
        // Địa chỉ WebSocket endpoint của Laravel Reverb (Cổng mặc định 8080)
        let wsURL = URL(string: "wss://api.formfit.app/app/formfit-app-key?protocol=7&client=js&version=8.4.0-reverb")!

        self.webSocketTask = session.webSocketTask(with: wsURL)
        self.webSocketTask?.resume()
        self.isConnected = true

        listenForMessages()
        subscribeToChannel(contractId: contractId, authToken: authToken)
    }

    public func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        self.isConnected = false
    }

    private func subscribeToChannel(contractId: Int, authToken: String?) {
        // Gửi khung Pusher subscribe cho Laravel Reverb
        let subscribePayload: [String: Any] = [
            "event": "pusher:subscribe",
            "data": [
                "channel": "private-chat.\(contractId)",
                "auth": authToken ?? "mock_auth_token"
            ]
        ]

        if let data = try? JSONSerialization.data(withJSONObject: subscribePayload),
           let text = String(data: data, encoding: .utf8) {
            webSocketTask?.send(.string(text)) { error in
                if let error = error {
                    print("[WebSocketChatService] ⚠️ Lỗi gửi subscribe: \(error.localizedDescription)")
                }
            }
        }
    }

    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                print("[WebSocketChatService] ⚠️ WebSocket receive failed: \(error.localizedDescription)")
                Task { @MainActor in
                    self.isConnected = false
                }
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleIncomingText(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleIncomingText(text)
                    }
                @unknown default:
                    break
                }
                // Tiếp tục lắng nghe message tiếp theo
                self.listenForMessages()
            }
        }
    }

    private func handleIncomingText(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let event = json["event"] as? String else { return }

        // Bắt sự kiện 'message.sent' từ MessageSent Event của Laravel
        if event == "message.sent", let dataDict = json["data"] as? [String: Any] {
            let id = dataDict["id"] as? Int ?? Int.random(in: 1000...9999)
            let contractId = dataDict["contract_id"] as? Int ?? 0
            let senderId = dataDict["sender_id"] as? Int ?? 0
            let senderName = dataDict["sender_name"] as? String ?? "PT"
            let msg = dataDict["message"] as? String
            let typeStr = dataDict["type"] as? String ?? "text"
            let mediaUrl = dataDict["media_url"] as? String
            let thumbUrl = dataDict["thumbnail_url"] as? String

            let newMsg = ChatMessageModel(
                id: id,
                contractId: contractId,
                senderId: senderId,
                senderName: senderName,
                message: msg,
                type: ChatMessageModel.MessageType(rawValue: typeStr) ?? .text,
                mediaUrl: mediaUrl,
                thumbnailUrl: thumbUrl,
                createdAt: Date()
            )

            Task { @MainActor in
                self.onMessageReceived?(newMsg)
            }
        }
    }
}
