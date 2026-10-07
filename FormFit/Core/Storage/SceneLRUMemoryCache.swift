import Foundation
import SceneKit

/// Bộ quản lý bộ nhớ đệm RAM cho SCNScene theo giải thuật LRU (Least Recently Used)
/// Đảm bảo tối đa 5 model 3D nằm trong RAM cùng lúc, các model cũ hơn sẽ bị giải phóng
/// khỏi RAM (nhưng vẫn còn trên bộ nhớ đệm ổ đĩa disk cache).
public final class SceneLRUMemoryCache: @unchecked Sendable {
    public static let shared = SceneLRUMemoryCache(maxCapacity: 5)

    private let maxCapacity: Int
    private let lock = NSLock()
    
    // Lưu trữ Node liên kết đôi cho LRU
    private class CacheNode {
        let key: URL
        var scene: SCNScene
        var prev: CacheNode?
        var next: CacheNode?

        init(key: URL, scene: SCNScene) {
            self.key = key
            self.scene = scene
        }
    }

    private var cacheMap: [URL: CacheNode] = [:]
    private var head: CacheNode? // Mới dùng nhất (Most recently used)
    private var tail: CacheNode? // Lâu nhất chưa dùng (Least recently used)

    public init(maxCapacity: Int = 5) {
        self.maxCapacity = maxCapacity
    }

    /// Lấy Scene từ RAM cache nếu có (và đưa lên đầu danh sách)
    public func getScene(for url: URL) -> SCNScene? {
        lock.lock()
        defer { lock.unlock() }

        guard let node = cacheMap[url] else { return nil }
        moveToHead(node)
        return node.scene
    }

    /// Thêm hoặc cập nhật Scene vào RAM cache
    public func setScene(_ scene: SCNScene, for url: URL) {
        lock.lock()
        defer { lock.unlock() }

        if let existingNode = cacheMap[url] {
            existingNode.scene = scene
            moveToHead(existingNode)
            return
        }

        let newNode = CacheNode(key: url, scene: scene)
        cacheMap[url] = newNode
        addToHead(newNode)

        // Nếu vượt quá giới hạn tối đa (maxCapacity = 5), loại bỏ node ở đuôi (tail)
        if cacheMap.count > maxCapacity {
            if let evictedTail = removeTail() {
                cacheMap.removeValue(forKey: evictedTail.key)
                // Dọn dẹp tài nguyên GPU/CPU của Scene bị loại bỏ
                purgeSceneResources(evictedTail.scene)
            }
        }
    }

    /// Xóa toàn bộ Scene trong RAM
    public func clearRAM() {
        lock.lock()
        defer { lock.unlock() }

        for (_, node) in cacheMap {
            purgeSceneResources(node.scene)
        }
        cacheMap.removeAll()
        head = nil
        tail = nil
    }

    // MARK: - Double-linked List Operations
    private func addToHead(_ node: CacheNode) {
        node.next = head
        node.prev = nil
        head?.prev = node
        head = node
        if tail == nil {
            tail = node
        }
    }

    private func removeNode(_ node: CacheNode) {
        if node.prev != nil {
            node.prev?.next = node.next
        } else {
            head = node.next
        }

        if node.next != nil {
            node.next?.prev = node.prev
        } else {
            tail = node.prev
        }
    }

    private func moveToHead(_ node: CacheNode) {
        removeNode(node)
        addToHead(node)
    }

    private func removeTail() -> CacheNode? {
        guard let oldTail = tail else { return nil }
        removeNode(oldTail)
        return oldTail
    }

    /// Giải phóng triệt để vật liệu, hình học và texture của Scene
    private func purgeSceneResources(_ scene: SCNScene) {
        scene.rootNode.enumerateHierarchy { (child, _) in
            child.removeAllAnimations()
            child.removeAllActions()
            if let geometry = child.geometry {
                for material in geometry.materials {
                    material.diffuse.contents = nil
                    material.emission.contents = nil
                    material.normal.contents = nil
                    material.roughness.contents = nil
                    material.metalness.contents = nil
                }
            }
            child.geometry = nil
        }
    }
}
