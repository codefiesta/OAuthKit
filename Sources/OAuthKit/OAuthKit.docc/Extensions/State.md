# ``OAuthKit/OAuth/State``
@Metadata {
    @Available(iOS, introduced: "18.0")
    @Available(macOS, introduced: "15.0")
    @Available(tvOS, introduced: "18.0")
    @Available(visionOS, introduced: "2.0")
    @Available(watchOS, introduced: "11.0")
}

## Overview
An example of observing the ``state`` property in SwiftUI:

```swift
struct ContentView: View {

    @Environment(\.oauth)
    var oauth: OAuth

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
            case .error(let provider, let error):
                Text("Error [\(provider.id)]: \(error.localizedDescription)")
            }
        }
        .onChange(of: oauth.state) { oldState, newState in
            handle(state: newState)
        }
    }
}
```
