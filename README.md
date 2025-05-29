![Build](https://github.com/codefiesta/OAuthKit/actions/workflows/swift.yml/badge.svg)
![Xcode 16.3+](https://img.shields.io/badge/Xcode-16.3%2B-gold.svg)
![Swift 6.0+](https://img.shields.io/badge/Swift-6.0%2B-tomato.svg)
![iOS 18.0+](https://img.shields.io/badge/iOS-18.0%2B-crimson.svg)
![macOS 15.0+](https://img.shields.io/badge/macOS-15.0%2B-skyblue.svg)
![visionOS 2.0+](https://img.shields.io/badge/visionOS-2.0%2B-magenta.svg)
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

    /// Build the scene body
    var body: some Scene {

        WindowGroup {
            ContentView()
        }
        
        WindowGroup(id: "oauth") {
            OAWebView()
        }
    }
} 

struct ContentView: View {
    
    @Environment(\.openWindow)
    var openWindow
    
    @Environment(\.dismissWindow)
    private var dismissWindow
    
    @Environment(\.oauth)
    var oauth: OAuth

    var body: some View {
        VStack {
            switch oauth.state {
            case .empty:
                providerList
            case .authorizing(let provider, _):
                Text("Authorizing [\(provider.id)]")
            case .requestingAccessToken(let provider):
                Text("Requesting Access Token [\(provider.id)]")
            case .requestingDeviceCode(let provider):
                Text("Requesting Device Code [\(provider.id)]")
            case .authorized(let auth):
                Button("Authorized [\(auth.provider.id)]") {
                    oauth.clear()
                }
            case .receivedDeviceCode(_, let deviceCode):
                Text("To login, visit")
                Text(deviceCode.verificationUri).foregroundStyle(.blue)
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
                // Start the authorization flow (use .deviceCode for tvOS)
                oauth.authorize(provider: provider, grantType: .authorizationCode)
            }
        }
    }
    
    /// Reacts to oauth state changes by opening or closing authorization windows.
    /// - Parameter state: the published state change
    private func handle(state: OAuth.State) {
        switch state {
        case .empty, .requestingAccessToken, .requestingDeviceCode:
            break
        case .authorizing, .receivedDeviceCode:
            openWindow(id: "oauth")
        case .authorized(_):
            dismissWindow(id: "oauth")
        }
    }
}
```
## tvOS (Device Authorization Grant)
OAuthKit supports the [OAuth 2.0 Device Authorization Grant](https://alexbilbie.github.io/2016/04/oauth-2-device-flow-grant/), which is used by apps that don't have access to a web browser (like tvOS). To leverage OAuthKit in tvOS apps, simply add the `deviceCodeURL` to your [OAuth.Provider](https://github.com/codefiesta/OAuthKit/blob/main/Sources/OAuthKit/OAuth.swift#L64) and initialize the device authorization grant workflow by calling ```oauth.authorize(provider: provider, grantType: .deviceCode)```

![tvOS-screenshot](https://github.com/user-attachments/assets/14997164-f86a-4ee0-b6b7-8c0d9732c83e)


## OAuthKit Configuration
By default, the easiest way to configure OAuthKit is to simply drop an `oauth.json` file into your main bundle and it will get automatically loaded into your swift application and available as an [EnvironmentObject](https://developer.apple.com/documentation/swiftui/environmentobject). You can find an example `oauth.json` file [here](https://github.com/codefiesta/OAuthKit/blob/main/Tests/OAuthKitTests/Resources/oauth.json).

```swift
    @Environment(\.oauth)
    var oauth: OAuth
```

If you want to customize your OAuth environment or are using modules in your application, you can also specify which bundle to load configure files from:


```swift
    let oauth: OAuth = await .init(.module)
```

If you are building your OAuth Providers programatically (recommended for production applications via a CI build pipeline for security purposes), you can pass providers and options as well.

```swift
    let providers: [OAuth.Provider] = ...
    let options: [OAuth.Option: Sendable] = [.applicationTag: "com.bundle.identifier"]
    let oauth: OAuth = await .init(providers: providers, options: options)
```


## Security Best Practices
Although OAuthKit will automatically try to load the `oauth.json` file found inside your main bundle (or bundle passed to the initializer) for convenience purposes, it is good policy to **NEVER** check in **clientID** or **clientSecret** values into source control. Also, it is possible for someone to [inspect and reverse engineer](https://www.nowsecure.com/blog/2021/09/08/basics-of-reverse-engineering-ios-mobile-apps/) the contents of your app and look at any files inside your app bundle which means you could potentially expose these secrets in the `oauth.json` file. The most secure way to protect OAuth secrets is to build your Providers programatically and bake [secret values](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions) into your code via your CI pipeline.

## OAuth Providers
* [Github](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps)
* [Google](https://developers.google.com/identity/protocols/oauth2)
* [Instagram](https://developers.facebook.com/docs/instagram-basic-display-api/guides/getting-access-tokens-and-permissions)
* [Microsoft](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-auth-code-flow)
* [Slack](https://api.slack.com/authentication/oauth-v2)
* [Twitter](https://developer.x.com/en/docs/authentication/oauth-2-0)

