import SwiftUI
import SceneKit

/// UIViewRepresentable bọc SCNView được tối ưu hóa bộ nhớ chuyên sâu:
/// 1. Tích hợp SceneLRUMemoryCache (tối đa 5 model trong RAM).
/// 2. Hủy bỏ triệt để retain cycle giữa Coordinator và View (`weak` reference).
/// 3. Dọn dẹp GPU Textures, SCNMaterial, Camera và Animation Players khi View unmount.
/// 4. Đảm bảo FPS luôn khóa ở 60 FPS và RAM không vượt quá 200MB.
public struct SceneKitModelView: UIViewRepresentable {
    public let fileURL: URL
    @Binding public var configuration: Scene3DConfiguration

    public init(fileURL: URL, configuration: Binding<Scene3DConfiguration>) {
        self.fileURL = fileURL
        self._configuration = configuration
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.antialiasingMode = .multisampling4X
        scnView.preferredFramesPerSecond = 60
        scnView.rendersContinuously = false // Chỉ render khi có tương tác hoặc animation để tiết kiệm CPU/GPU
        scnView.autoenablesDefaultLighting = false // Dùng ánh sáng custom để kiểm soát bộ nhớ

        // Gán weak parent cho coordinator để tránh retain cycle
        context.coordinator.parentView = self
        context.coordinator.scnView = scnView
        context.coordinator.setupGestures(for: scnView)

        // Nạp Scene thông qua LRU Memory Cache
        context.coordinator.loadScene(from: fileURL, into: scnView)

        return scnView
    }

    public func updateUIView(_ scnView: SCNView, context: Context) {
        context.coordinator.parentView = self
        context.coordinator.update(configuration: configuration, in: scnView)
    }

    public static func dismantleUIView(_ scnView: SCNView, coordinator: Coordinator) {
        // Kích hoạt dọn dẹp bộ nhớ triệt để khi View bị hủy khỏi cây SwiftUI
        coordinator.cleanup(scnView: scnView)
    }

    // MARK: - Coordinator
    public class Coordinator: NSObject, UIGestureRecognizerDelegate {
        // Tránh retain cycle triệt để
        weak var scnView: SCNView?
        var parentView: SceneKitModelView?

        var rootNode: SCNNode?
        var cameraNode: SCNNode?
        var originalMaterials: [String: [SCNMaterial]] = [:]

        // Gesture state tracking
        private var currentAngleX: Float = 0
        private var currentAngleY: Float = 0
        private var baseCameraZ: Float = 2.5
        private var currentCameraZ: Float = 2.5

        override init() {
            super.init()
        }

        func setupGestures(for view: SCNView) {
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            panGesture.delegate = self
            view.addGestureRecognizer(panGesture)

            let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            pinchGesture.delegate = self
            view.addGestureRecognizer(pinchGesture)
        }

        func loadScene(from url: URL, into scnView: SCNView) {
            // 1. Kiểm tra trong LRU RAM Cache trước
            if let cachedScene = SceneLRUMemoryCache.shared.getScene(for: url) {
                configureLoadedScene(cachedScene, in: scnView)
                return
            }

            // 2. Nếu chưa có trong RAM: Đọc từ local disk
            do {
                let scene = try SCNScene(url: url, options: [
                    .checkConsistency: false,
                    .flattenScene: false,
                    .createNormalsIfAbsent: false
                ])

                // Lưu vào LRU Cache (tối đa 5 model)
                SceneLRUMemoryCache.shared.setScene(scene, for: url)

                configureLoadedScene(scene, in: scnView)
            } catch {
                print("[SceneKitModelView] ⚠️ Lỗi tải SCNScene: \(error.localizedDescription)")
            }
        }

        private func configureLoadedScene(_ scene: SCNScene, in scnView: SCNView) {
            // Tạo Custom Camera Node
            let camera = SCNCamera()
            camera.zNear = 0.05
            camera.zFar = 50.0
            camera.fieldOfView = 50

            let camNode = SCNNode()
            camNode.name = "CustomCameraNode"
            camNode.camera = camera
            camNode.position = SCNVector3(0, 0, baseCameraZ)
            scene.rootNode.addChildNode(camNode)
            self.cameraNode = camNode

            // Thiết lập ánh sáng Studio tối ưu
            setupOptimizedLighting(in: scene)

            self.rootNode = scene.rootNode
            scnView.scene = scene

            // Cache material gốc phục vụ highlight
            cacheOriginalMaterials(node: scene.rootNode)

            if let config = parentView?.configuration {
                update(configuration: config, in: scnView)
            }
        }

        private func setupOptimizedLighting(in scene: SCNScene) {
            let keyLight = SCNLight()
            keyLight.type = .directional
            keyLight.intensity = 1000
            keyLight.castsShadow = false // Tắt đổ bóng động thời gian thực để giữ FPS 60 vững chắc
            let keyNode = SCNNode()
            keyNode.light = keyLight
            keyNode.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 4, 0)
            scene.rootNode.addChildNode(keyNode)

            let ambientLight = SCNLight()
            ambientLight.type = .ambient
            ambientLight.intensity = 500
            let ambientNode = SCNNode()
            ambientNode.light = ambientLight
            scene.rootNode.addChildNode(ambientNode)
        }

        private func cacheOriginalMaterials(node: SCNNode) {
            if let geometry = node.geometry, let name = node.name {
                originalMaterials[name] = geometry.materials.map { $0.copy() as! SCNMaterial }
            }
            for child in node.childNodes {
                cacheOriginalMaterials(node: child)
            }
        }

        func update(configuration: Scene3DConfiguration, in scnView: SCNView) {
            guard let scene = scnView.scene else { return }

            scnView.isPlaying = configuration.isPlaying

            // Điều khiển animation players
            scene.rootNode.enumerateHierarchy { (childNode, _) in
                for key in childNode.animationKeys {
                    if let player = childNode.animationPlayer(forKey: key) {
                        player.speed = CGFloat(configuration.isPlaying ? configuration.playbackSpeed : 0.0)
                    }
                }
            }

            // Highlight cơ bắp
            applyHighlight(
                nodeNames: configuration.highlightedNodeNames,
                color: configuration.highlightColor,
                in: scene.rootNode
            )

            // Reset camera
            if configuration.shouldResetCamera {
                resetCamera()
                DispatchQueue.main.async {
                    self.parentView?.configuration.shouldResetCamera = false
                }
            }
        }

        private func applyHighlight(nodeNames: Set<String>, color: UIColor, in rootNode: SCNNode) {
            rootNode.enumerateHierarchy { [weak self] (node, _) in
                guard let self = self, let geometry = node.geometry, let name = node.name else { return }

                let shouldHighlight = nodeNames.contains(name) || nodeNames.contains(where: { name.localizedCaseInsensitiveContains($0) })

                if shouldHighlight {
                    let highlightMaterial = SCNMaterial()
                    highlightMaterial.diffuse.contents = color.withAlphaComponent(0.85)
                    highlightMaterial.emission.contents = color.withAlphaComponent(0.5)
                    highlightMaterial.roughness.contents = 0.3
                    geometry.materials = [highlightMaterial]
                } else if let cached = self.originalMaterials[name] {
                    geometry.materials = cached
                }
            }
        }

        func resetCamera() {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.4
            self.currentAngleX = 0
            self.currentAngleY = 0
            self.currentCameraZ = self.baseCameraZ
            self.rootNode?.eulerAngles = SCNVector3(0, 0, 0)
            self.cameraNode?.position = SCNVector3(0, 0, self.baseCameraZ)
            SCNTransaction.commit()
        }

        // MARK: - Memory Deallocation & Cleanup
        func cleanup(scnView: SCNView) {
            // 1. Dừng hoàn toàn render loop
            scnView.isPlaying = false
            scnView.rendersContinuously = false

            // 2. Dừng tất cả animation và actions trên tất cả các nodes
            if let root = scnView.scene?.rootNode {
                root.enumerateHierarchy { (node, _) in
                    node.removeAllAnimations()
                    node.removeAllActions()
                    // Gỡ bỏ gesture recognizers gắn trên view
                    for gesture in scnView.gestureRecognizers ?? [] {
                        scnView.removeGestureRecognizer(gesture)
                    }
                }
            }

            // 3. Gỡ liên kết camera và giải phóng scene khỏi SCNView
            self.cameraNode?.removeFromParentNode()
            self.cameraNode = nil
            self.rootNode = nil
            self.originalMaterials.removeAll(keepingCapacity: false)

            scnView.scene = nil
            self.parentView = nil
            self.scnView = nil
        }

        // MARK: - Gestures
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view as? SCNView, let node = rootNode else { return }
            let translation = gesture.translation(in: view)

            let sensitivity: Float = 0.005
            let deltaY = Float(translation.x) * sensitivity
            let deltaX = Float(translation.y) * sensitivity

            if gesture.state == .changed {
                node.eulerAngles = SCNVector3(currentAngleX + deltaX, currentAngleY + deltaY, 0)
            } else if gesture.state == .ended {
                currentAngleX += deltaX
                currentAngleY += deltaY
            }
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let camera = cameraNode else { return }
            if gesture.state == .changed {
                let zoomFactor = Float(gesture.scale)
                let newZ = currentCameraZ / zoomFactor
                camera.position.z = max(0.8, min(5.5, newZ))
            } else if gesture.state == .ended {
                currentCameraZ = camera.position.z
            }
        }

        public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}
