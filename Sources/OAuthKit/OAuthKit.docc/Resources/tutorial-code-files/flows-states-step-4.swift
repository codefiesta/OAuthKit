struct ContentView: View {

    @Environment(\.oauth)
    var oauth: OAuth

    @Environment(\.openWindow)
    var openWindow

    @Environment(\.dismissWindow)
    private var dismissWindow

    /// The main view body
    var body: some View {
        VStack {
            // Update the view based on the current oauth state
        }
        .onChange(of: oauth.state) { _, state in
            handle(state: state)
        }
    }

    /// Reacts to oauth state changes by opening or closing authorization windows.
    /// - Parameter state: the published state change
    private func handle(state: OAuth.State) {
        #if canImport(WebKit)
        switch state {
        case .empty, .requestingAccessToken, .requestingDeviceCode:
            break
        case .authorizing, .receivedDeviceCode:
            openWindow(id: "oauth")
        case .authorized(_, _):
            dismissWindow(id: "oauth")
        }
        #endif
    }
}
