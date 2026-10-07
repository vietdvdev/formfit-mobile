import Foundation

/// Cấu trúc tin nhắn trong ứng dụng FormFit
public struct ChatMessageModel: Identifiable, Hashable, Sendable, Codable {
    public let id: Int
    public let contractId: Int
    public let senderId: Int
    public let senderName: String
    public let message: String?
    public let type: MessageType
    public let mediaUrl: String?
    public let thumbnailUrl: String?
    public let createdAt: Date

    public enum MessageType: String, Codable, Sendable {
        case text
        case video
        case image
    }

    public init(
        id: Int,
        contractId: Int,
        senderId: Int,
        senderName: String,
        message: String?,
        type: MessageType,
        mediaUrl: String? = nil,
        thumbnailUrl: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.contractId = contractId
        self.senderId = senderId
        self.senderName = senderName
        self.message = message
        self.type = type
        self.mediaUrl = mediaUrl
        self.thumbnailUrl = thumbnailUrl
        self.createdAt = createdAt
    }
}
