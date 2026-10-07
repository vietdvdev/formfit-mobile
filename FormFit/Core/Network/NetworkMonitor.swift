import Foundation
import Network
import Observation

/// Theo dõi trạng thái kết nối mạng thời gian thực sử dụng Network.framework (NWPathMonitor)
@Observable
@MainActor
public final class NetworkMonitor {
    public static let shared = NetworkMonitor()

    public private(set) var isConnected: Bool = true
    public private(set) var isExpensive: Bool = false // Mạng 4G/5G hoặc Personal Hotspot
    public private(set) var connectionType: ConnectionType = .wifi

    public enum ConnectionType: Sendable {
        case wifi
        case cellular
        case ethernet
        case unknown
    }

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.formfit.network.monitor")

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isConnected = (path.status == .satisfied)
                self.isExpensive = path.isExpensive

                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .ethernet
                } else {
                    self.connectionType = .unknown
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }

    deinit {
        monitor.cancel()
    }
}
