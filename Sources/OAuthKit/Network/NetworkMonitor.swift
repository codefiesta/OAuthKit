//
//  NetworkMonitor.swift
//
//
//  Created by Kevin McKee on 5/30/24.
//

import Network
import Observation

/// A type that broadcasts network reachability via Combine event publishing.
@MainActor
@Observable
final class NetworkMonitor {

    @ObservationIgnored
    private let pathMonitor = NWPathMonitor()

    /// Returns true if the network has an available wifi interface.
    var onWifi = false
    /// Returns true if the network has an available cellular interface.
    var onCellular = false
    /// Returns true if the network has an wired ethernet interface.
    var onWiredEthernet = false

    /// Returns true if the network is online with any available interface.
    var isOnline: Bool {
        onWifi || onCellular || onWiredEthernet
    }

    /// Initializer.
    init() { }

    /// Starts the network monitor (conforms to AsyncSequence).
    func start() async {
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
