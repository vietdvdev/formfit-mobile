import SwiftUI
import AVFoundation

/// View bọc AVCaptureVideoPreviewLayer cho camera thời gian thực
public struct CameraPreviewView: UIViewRepresentable {
    public let session: AVCaptureSession

    public init(session: AVCaptureSession) {
        self.session = session
    }

    public func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    public func updateUIView(_ uiView: PreviewUIView, context: Context) {}

    public class PreviewUIView: UIView {
        override public class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}

/// Màn hình Custom Camera chụp ảnh vóc dáng với lớp phủ mờ Ghost Overlay đối chiếu góc chụp cũ
public struct ProgressCameraView: View {
    public let ghostImage: UIImage?
    public let onPhotoCaptured: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var ghostOpacity: Double = 0.4
    @State private var isGhostVisible: Bool = true
    @State private var captureSession = AVCaptureSession()
    @State private var photoOutput = AVCapturePhotoOutput()
    @State private var cameraCoordinator: CameraCoordinator?

    public init(ghostImage: UIImage? = nil, onPhotoCaptured: @escaping (UIImage) -> Void) {
        self.ghostImage = ghostImage
        self.onPhotoCaptured = onPhotoCaptured
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 1. Camera Live Preview
            CameraPreviewView(session: captureSession)
                .ignoresSafeArea()

            // 2. Ghost Overlay (Lớp phủ mờ ảnh cũ)
            if let ghost = ghostImage, isGhostVisible {
                Image(uiImage: ghost)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .opacity(ghostOpacity)
                    .allowsHitTesting(false)
            }

            // Đường lưới căn góc chụp (Grid lines)
            gridOverlay
                .allowsHitTesting(false)

            // 3. Thanh điều khiển trên cùng (Top Bar)
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    Spacer()

                    if ghostImage != nil {
                        Button {
                            withAnimation {
                                isGhostVisible.toggle()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isGhostVisible ? "eye.fill" : "eye.slash.fill")
                                Text(isGhostVisible ? "Ghost On" : "Ghost Off")
                            }
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                            .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // 4. Thanh điều khiển dưới cùng (Bottom Controls)
                VStack(spacing: 16) {
                    // Slider chỉnh độ mờ của Ghost Image
                    if ghostImage != nil && isGhostVisible {
                        HStack(spacing: 12) {
                            Image(systemName: "circle.lefthalf.filled")
                                .font(.caption)
                                .foregroundStyle(.white)
                            Slider(value: $ghostOpacity, in: 0.1...0.8)
                                .tint(.white)
                            Text("\(Int(ghostOpacity * 100))%")
                                .font(.caption.monospacedDigit().bold())
                                .foregroundStyle(.white)
                                .frame(width: 36)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.horizontal, 32)
                    }

                    // Nút chụp ảnh (Shutter Button)
                    HStack {
                        Spacer()

                        Button {
                            capturePhoto()
                        } label: {
                            ZStack {
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 76, height: 76)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 64, height: 64)
                            }
                        }

                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            setupCameraSession()
        }
        .onDisappear {
            captureSession.stopRunning()
        }
    }

    private var gridOverlay: some View {
        GeometryReader { geo in
            Path { path in
                let w = geo.size.width
                let h = geo.size.height
                // Đường dọc
                path.move(to: CGPoint(x: w / 3, y: 0))
                path.addLine(to: CGPoint(x: w / 3, y: h))
                path.move(to: CGPoint(x: 2 * w / 3, y: 0))
                path.addLine(to: CGPoint(x: 2 * w / 3, y: h))
                // Đường ngang
                path.move(to: CGPoint(x: 0, y: h / 3))
                path.addLine(to: CGPoint(x: w, y: h / 3))
                path.move(to: CGPoint(x: 0, y: 2 * h / 3))
                path.addLine(to: CGPoint(x: w, y: 2 * h / 3))
            }
            .stroke(Color.white.opacity(0.15), lineWidth: 1)
        }
        .ignoresSafeArea()
    }

    private func setupCameraSession() {
        let coordinator = CameraCoordinator(onCapture: { image in
            onPhotoCaptured(image)
            dismiss()
        })
        self.cameraCoordinator = coordinator

        Task.detached(priority: .userInitiated) {
            captureSession.beginConfiguration()
            captureSession.sessionPreset = .photo

            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
               let input = try? AVCaptureDeviceInput(device: device),
               captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }

            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }

            captureSession.commitConfiguration()
            captureSession.startRunning()
        }
    }

    private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        guard let coordinator = cameraCoordinator else { return }
        photoOutput.capturePhoto(with: settings, delegate: coordinator)
    }

    private class CameraCoordinator: NSObject, AVCapturePhotoCaptureDelegate {
        let onCapture: (UIImage) -> Void

        init(onCapture: @escaping (UIImage) -> Void) {
            self.onCapture = onCapture
        }

        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard error == nil,
                  let data = photo.fileDataRepresentation(),
                  let image = UIImage(data: data) else { return }

            DispatchQueue.main.async {
                self.onCapture(image)
            }
        }
    }
}
