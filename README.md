![Build](https://github.com/codefiesta/OAuthKit/actions/workflows/swift.yml/badge.svg)
![Xcode 15.3+](https://img.shields.io/badge/Xcode-15.3%2B-gold.svg)
![Swift 5.10+](https://img.shields.io/badge/Swift-5.10%2B-tomato.svg)
![iOS 17.0+](https://img.shields.io/badge/iOS-17.0%2B-crimson.svg)
![macOS 14.0+](https://img.shields.io/badge/macOS-14.0%2B-skyblue.svg)
![visionOS 1.0+](https://img.shields.io/badge/visionOS-1.0%2B-magenta.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-indigo.svg)](https://opensource.org/licenses/MIT)

# OAuthKit

OAuthKit is a modern, event-driven Swift Package that leverages the [Combine](https://developer.apple.com/documentation/combine) Framework to publish [OAuth 2.0](https://oauth.net/2/) events which allows application developers to easily configure OAuth Providers and focus on making great applications instead of focusing on the details of authorization flows.

## OAuthKit Usage

The following is an example of the simplest usage of using OAuthKit in macOS:

```swift
import OAuthKit
import SwiftUI

@main
struct OAuthApp: App {

    @Environment(\.oauth)
    var oauth: OAuth

    /// Build the scene body
    var body: some Scene {

        WindowGroup {
            ContentView()
        }.environmentObject(oauth)
        
        WindowGroup(id: "oauth") {
            OAWebView()
        }.environmentObject(oauth)
    }
} 

struct ContentView: View {
    
    @Environment(\.openWindow)
    var openWindow
    
    @Environment(\.dismissWindow)
    private var dismissWindow
    
    @EnvironmentObject
    var oauth: OAuth

    var body: some View {
        VStack {
            switch oauth.state {
            case .empty:
                providerList
            case .authorizing(let provider):
                Text("Authorizing [\(provider.id)]")
            case .requestingAccessToken(let provider):
                Text("Requesting Access Token [\(provider.id)]")
            case .authorized(let auth):
                Button("Authorized [\(auth.provider.id)]") {
                    oauth.clear()
                }
            }
        }
        .onReceive(oauth.$state) { state in
            handle(state: state)
        }
    }
    
    /// Displays a list of oauth providers.
    var providerList: some View {
        List(oauth.providers) { provider in
            Button(provider.id) {
                // Start the authorization flow
                oauth.authorize(provider: provider)
            }
        }
    }
    
    /// Reacts to oauth state changes by opening or closing authorization windows.
    /// - Parameter state: the published state change
    private func handle(state: OAuth.State) {
        switch state {
        case .empty, .requestingAccessToken:
            break
        case .authorizing(let provider):
            openWindow(id: "oauth")
        case .authorized(_):
            dismissWindow(id: "oauth")
        }
    }
}
```
## OAuthKit Configuration
By default, the easiest way to configure OAuthKit is to simply drop an `oauth.json` file into your main bundle and it will get automatically loaded into your swift application and available as an [EnvironmentObject](https://developer.apple.com/documentation/swiftui/environmentobject). You can find an example `oauth.json` file [here](https://github.com/codefiesta/OAuthKit/blob/main/Tests/OAuthKitTests/Resources/oauth.json).

```swift
    @EnvironmentObject
    var oauth: OAuth
```

If you want to customize your OAuth environment or are using modules in your application, you can also specify which bundle to look for your configure file in like so:


```swift
    let oauth: OAuth = .init(.module)
```

If you are building your OAuth Providers programatically (recommended for production applications via a CI build pipeline for security purposes), you can pass providers and options as well.

```swift
    let providers: [OAuth.Provider] = ...
    let options: [OAuth.Option: Any] = [.applicationTag: "com.bundle.identifier"]
    let oauth: OAuth = .init(providers: providers, options: options)
```


## Security Best Practices
Although OAuthKit will automatically try to load the `oauth.json` file found inside your main bundle (or bundle passed to the initializer) for convenience purposes, it is good policy to **never** check in **clientID** or **clientSecret** values into source control. Also, it is possible for someone to inspect the contents of your app and look at any files inside your app bundle. The most secure way is to build Providers programatically and bake any these values into your code via your CI pipeline.

