# Getting Started with OAuthKit

Learn how to create an observable OAuth instance and start an authorization flow.

@Metadata {
    @PageKind(article)
    @PageImage(
        purpose: card, 
        source: "gettingStarted-card", 
        alt: "Getting Started with OAuthKit")
    @PageColor(yellow)
    @Available(iOS, introduced: "18.0")
    @Available(macOS, introduced: "15.0")
    @Available(tvOS, introduced: "18.0")
    @Available(visionOS, introduced: "2.0")
    @Available(watchOS, introduced: "11.0")
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

## Presenting Authorization Windows
When a ``OAuth/state`` has reached an ``OAuth/State/authorizing(_:_:)`` state, your application should present
a browser window that allows the user to authenticate with an ``OAuth/Provider``. 
OAuthKit provides an out of the box SwiftUI view ``OAWebView`` that will automatically handle the rest of the steps in the OAuth authorization flow for you.

```swift
/// Handle `.authorizing` or `.authorized` oauth state changes by opening or closing authorization windows.
/// - Parameter state: the published state change
func handle(state: OAuth.State) {
    switch state {
    case .empty, .requestingAccessToken, .requestingDeviceCode, .receivedDeviceCode:
        break
    case .authorizing:
        openWindow(id: "oauth")
    case .authorized:
        dismissWindow(id: "oauth")
    }
}
```
Once the user has successfully authorized with the ``OAuth/Provider``, the ``OAuth/state`` will move to an ``OAuth/State/authorized(_:_:)`` state. You can then automaticaly close the ``OAWebView`` window in your SwiftUI application.

> Tip: Once authorized, a ``OAuth/Authorization/token`` will be inserted into the user's Keychain that can be used in subsequent API requests by inserting the `Authorization` header into an `URLRequest` via ``OAuthKit/Foundation/URLRequest/addAuthorization(auth:)`` .

## Presenting Device Codes (tvOS and watchOS)
OAuthKit also supports the [OAuth 2.0 Device Code Flow Grant](https://alexbilbie.github.io/2016/04/oauth-2-device-flow-grant/), which is used by apps that don't have access to a web browser (like tvOS or watchOS). To leverage OAuthKit in tvOS or watchOS apps, simply add the `deviceCodeURL` to your ``OAuth/Provider`` and start an ``OAuth/authorize(provider:grantType:)`` flow with the ``OAuth/GrantType/deviceCode`` grantType.

```swift
let grantType: OAuth.GrantType = .deviceCode
oauth.authorize(provider: provider, grantType: grantType)

struct ContentView: View {
    ...
    var body: some View {
        VStack {
            switch oauth.state {
            case .empty, .authorizing, .requestingAccessToken, .requestingDeviceCode:
                EmptyView()
            case .authorized:
                Text("Authorized [\(provider.id)]")
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
    }
}
```

The observable ``OAuth`` instance will proceed to poll the ``OAuth/Provider`` access token endpoint until the device code has expired or has successfully received an ``OAuth/Token`` and moved to an ``OAuth/State/authorized(_:_:)`` state. 

> Tip: Click  [here](https://oauth.net/2/grant-types/device-code/) to see details of how the OAuth 2.0 Device Code Grant Type works.


