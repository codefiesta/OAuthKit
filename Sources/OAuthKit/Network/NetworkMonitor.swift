//
//  NetworkMonitor.swift
//
//
//  Created by Kevin McKee on 5/30/24.
//

import Combine
import Network

private let queueLabel = "oauthkit.NetworkMonitor"

/// A type that broadcasts network reachability via Combine event publishing.
final class NetworkMonitor {

    /// The private pass through publisher.
    private var publisher = PassthroughSubject<Bool, Never>()

    /// Provides a pass through subject used to broadcast events to downstream subscribers.
    /// The subject will automatically drop events if there are no subscribers, or its current demand is zero.
    public lazy var networkStatus = publisher.eraseToAnyPublisher()

    private let pathMonitor = NWPathMonitor()
    private let queue = DispatchQueue(label: queueLabel)

    /// Returns true if the network has an available wifi interface.
    var onWifi = false
    /// Returns true if the network has an available cellular interface.
    var onCellular = false

    /// Initializer that starts the network monitor and begins publishing updates.
    init() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            onWifi = path.usesInterfaceType(.wifi)
            onCellular = path.usesInterfaceType(.cellular)
            publisher.send(path.status == .satisfied)
        }
        pathMonitor.start(queue: queue)
    }
}
