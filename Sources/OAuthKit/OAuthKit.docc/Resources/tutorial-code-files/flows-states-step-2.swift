struct ContentView: View {
    
    @Environment(\.oauth)
    var oauth: OAuth

    @Environment(\.openWindow)
    var openWindow

    @Environment(\.dismissWindow)
    private var dismissWindow
    
    /// Displays a list of oauth providers.
    var providerList: some View {
        List(oauth.providers) { provider in
            Button(provider.id) {
                // Start an authorization flow
            }
        }
    }

    /// The main view body
    var body: some View {
        VStack {
            // Update the view based on the current oauth state
            switch oauth.state {
            case .empty:
                providerList
            case .authorizing(let provider, let grantType):
                Text("Authorizing [\(provider.id)] with [\(grantType.rawValue)]")
            case .requestingAccessToken(let provider):
                Text("Requesting Access Token [\(provider.id)]")
            case .requestingDeviceCode(let provider):
                Text("Requesting Device Code [\(provider.id)]")
            case .authorized(let provider, _):
                Button("Authorized [\(provider.id)]") {
                    oauth.clear()
                }
            case .receivedDeviceCode(_, let deviceCode):
                Text("To login, visit")
                Text(.init("[\(deviceCode.verificationUri)](\(deviceCode.verificationUri))"))
                    .foregroundStyle(.blue)
                Text("and enter the following code:")
                Text(deviceCode.userCode)
                    .padding()
                    .border(Color.primary)
                    .font(.title)
            }
        }
        .onChange(of: oauth.state) { _, state in
            // Handle state change
        }
    }
}
