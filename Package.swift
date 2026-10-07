// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "FormFit",
    defaultLocalization: "vi",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "FormFitCore",
            targets: ["FormFitCore"]
        )
    ],
    dependencies: [
        // 100% Zero Third-Party Dependencies!
        // Toàn bộ chức năng sử dụng Frameworks Native của Apple:
        // - Đồ họa 3D: SceneKit, RealityKit
        // - Cơ sở dữ liệu: SwiftData
        // - Biểu đồ: Charts (Swift Charts)
        // - Mạng & Async: URLSession, Network (NWPathMonitor)
        // - Chỉ số & Widget: HealthKit, ActivityKit, WidgetKit
        // - Thanh toán: StoreKit (StoreKit 2)
        // - Media & Camera: AVFoundation, AVKit
    ],
    targets: [
        .target(
            name: "FormFitCore",
            dependencies: [],
            path: "FormFit"
        ),
        .testTarget(
            name: "FormFitTests",
            dependencies: ["FormFitCore"],
            path: "FormFitTests"
        )
    ]
)
