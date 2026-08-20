//
//  NetworkMonitor.swift
//
//
//  Created by Kevin McKee
//

#if canImport(Network)
import Network
#endif
import Observation

/// An  `Observable` type that publishes network reachability information.
@MainActor
@Observable
public final class NetworkMonitor: Sendable {

    // The shared singleton network monitor.
    public static let shared: NetworkMonitor = .init()

    #if canImport(Network)
    @ObservationIgnored
    private let pathMonitor = NWPathMonitor()
    #endif

    /// Flag indicating if monitoring is currently active or not.
    public private(set) var isMonitoring = false

    /// Returns true if the network has an available wifi interface.
    public var onWifi = false
    /// Returns true if the network has an available cellular interface.
    public var onCellular = false
    /// Returns true if the network has an wired ethernet interface.
    public var onWiredEthernet = false

    /// Returns true if the network is online with any available interface.
    public var isOnline: Bool {
        onWifi || onCellular || onWiredEthernet
    }

    /// Initializer.
    private init() { }

    /// Starts the network monitor (conforms to AsyncSequence).
    public func start() async {
        #if canImport(Network)
        guard !isMonitoring else { return }
        isMonitoring.toggle()
        for await path in pathMonitor {
            handle(path: path)
        }
        #endif
    }

    #if canImport(Network)

    /// Handles the snapshot view of the network path state.
    /// - Parameter path: the snapshot view of the network path state
    private func handle(path: NWPath) {
        onWifi = path.usesInterfaceType(.wifi)
        onCellular = path.usesInterfaceType(.cellular)
        onWiredEthernet = path.usesInterfaceType(.wiredEthernet)
    }

    #endif
}
