//
//  NetworkMonitor.swift
//
//
//  Created by Kevin McKee on 5/30/24.
//

import Network
import Observation

/// An  `Observable` type that publishes network reachability information.
@MainActor
@Observable
public final class NetworkMonitor: Sendable {

    // The shared singleton network monitor.
    public static let shared: NetworkMonitor = .init()

    @ObservationIgnored
    private let pathMonitor = NWPathMonitor()

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
        for await path in pathMonitor {
            handle(path: path)
        }
    }

    /// Handles the snapshot view of the network path state.
    /// - Parameter path: the snapshot view of the network path state
    private func handle(path: NWPath) {
        onWifi = path.usesInterfaceType(.wifi)
        onCellular = path.usesInterfaceType(.cellular)
        onWiredEthernet = path.usesInterfaceType(.wiredEthernet)
    }
}
