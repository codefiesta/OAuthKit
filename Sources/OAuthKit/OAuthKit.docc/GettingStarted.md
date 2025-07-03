# Getting Started with OAuthKit

Create an ``OAuth`` instance and start an authorization flow.

@Metadata {
    @PageKind(article)
}

## Overview

OAuth 2.0 authorization flows are started by calling ``OAuth/authorize(provider:grantType:)`` with an ``OAuth/Provider`` and ``OAuth/GrantType``.

```swift
// Create an observable OAuth object
let oauth: OAuth = .init(.main)

// Start an authorization flow
let grantType: OAuth.GrantType = .pkce(.init())
oauth.authorize(provider: provider, grantType: grantType)
```

## Observing OAuth State

Once an OAuth 2.0 authorization flow has been started in an application, observers of an OAuth object will be notified of next step events in that flow and can react accordingly. For example:

```swift
@main
struct OAuthApp: App {

    @Environment(\.oauth)
    var oauth: OAuth
    
    /// Build the scene body
    var body: some Scene {

        WindowGroup {
            ContentView()
        }
        
        #if canImport(WebKit)
        WindowGroup(id: "oauth") {
            OAWebView(oauth: oauth)
        }
        #endif
    }
} 

struct ContentView: View {
    
    @Environment(\.oauth)
    var oauth: OAuth

    @Environment(\.openWindow)
    var openWindow
    
    @Environment(\.dismissWindow)
    private var dismissWindow

    var body: some View {
        VStack {
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
            handle(state: state)
        }
    }
    
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
        let grantType: OAuth.GrantType = .pkce(.init())
        oauth.authorize(provider: provider, grantType: grantType)
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
```

