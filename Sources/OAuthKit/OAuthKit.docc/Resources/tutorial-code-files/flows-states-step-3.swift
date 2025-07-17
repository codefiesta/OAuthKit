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
                authorize(provider: provider)
            }
        }
    }

    /// Starts the authorization process for the specified provider.
    /// - Parameter provider: the provider to begin authorization for
    private func authorize(provider: OAuth.Provider) {
        #if canImport(WebKit)
        // Use the PKCE grantType for iOS, macOS, visionOS
        let grantType: OAuth.GrantType = .pkce(.init())
        #else
        // Use the Device Code grantType for tvOS, watchOS
        let grantType: OAuth.GrantType = .deviceCode
        #endif
        // Start the authorization flow
        oauth.authorize(provider: provider, grantType: grantType)
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
            case .error(let provider, let error):
                Text("Error [\(provider.id)]: \(error.localizedDescription)")
            }
        }
        .onChange(of: oauth.state) { _, state in
            // Handle state change
        }
    }
}
