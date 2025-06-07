![Build](https://github.com/codefiesta/OAuthKit/actions/workflows/swift.yml/badge.svg)
![Xcode 16.3+](https://img.shields.io/badge/Xcode-16.3%2B-gold.svg)
![Swift 6.0+](https://img.shields.io/badge/Swift-6.0%2B-tomato.svg)
![iOS 18.0+](https://img.shields.io/badge/iOS-18.0%2B-crimson.svg)
![macOS 15.0+](https://img.shields.io/badge/macOS-15.0%2B-skyblue.svg)
![tvOS 18.0+](https://img.shields.io/badge/tvOS-18.0%2B-blue.svg)
![visionOS 2.0+](https://img.shields.io/badge/visionOS-2.0%2B-magenta.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-indigo.svg)](https://opensource.org/licenses/MIT)
![Code Coverage](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/codefiesta/87655b6e3c89b9198287b2fefbfa641f/raw/oauthkit-coverage.json)

# OAuthKit
<img src="https://github.com/user-attachments/assets/039ee445-42af-433d-9793-56fc36330952" height="100" align="left"/>

OAuthKit is a modern, event-driven Swift Package that leverages the [Combine](https://developer.apple.com/documentation/combine) Framework to publish [OAuth 2.0](https://oauth.net/2/) events which allows application developers to easily configure OAuth Providers and focus on making great applications instead of focusing on the details of authorization flows.
<br clear="left"/>

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
                // Start the default authorization flow (.authorizationCode)
                oauth.authorize(provider: provider)
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

## OAuthKit Configuration
By default, the easiest way to configure OAuthKit is to simply drop an `oauth.json` file into your main bundle and it will get automatically loaded into your swift application and available as an [Environment](https://developer.apple.com/documentation/swiftui/environment). You can find an example `oauth.json` file [here](https://github.com/codefiesta/OAuthKit/blob/main/Tests/OAuthKitTests/Resources/oauth.json).

```swift
@Environment(\.oauth)
var oauth: OAuth
```

If you want to customize your OAuth environment or are using modules in your application, you can also specify which bundle to load configure files from:

```swift
let oauth = OAuth(.module)
```

If you are building your OAuth Providers programatically (recommended for production applications via a CI build pipeline for security purposes), you can pass providers and options as well.

```swift
let providers: [OAuth.Provider] = ...
let options: [OAuth.Option: Sendable] = [.applicationTag: "com.bundle.identifier"]
let oauth: OAuth = OAuth(providers: providers, options: options)
```

## OAuthKit Authorization Flows
OAuth 2.0 workflows are started by calling the following:

```swift
oauth.authorize(provider: provider, grantType: grantType)
``` 

A good resource to help understand the detailed steps involved in OAuth 2.0 workflows can be found on the [OAuth 2.0 Playground](https://www.oauth.com/playground/index.html).

### OAuth 2.0 Authorization Code Flow

```swift
/// Authorization Code is the default workflow with an auto generated state
oauth.authorize(provider: provider)
	
/// Or you can manually configure the Authorization Code state
let state: String = "ABC-XYZ"
let grantType: OAuth.GrantType = .authorizationCode(state)
oauth.authorize(provider: provider, grantType: grantType)
```

### OAuth 2.0 PKCE Flow
PKCE ([RFC 7636](https://www.rfc-editor.org/rfc/rfc7636)) is an extension to the [Authorization Code](https://oauth.net/2/grant-types/authorization-code/) flow to prevent CSRF and authorization code injection attacks.

Proof Key for Code Exchange (PKCE) is the recommended flow to use in OAuthKit as this technique involves the client first creating a secret on each authorization request, and then using that secret again when exchanging the authorization code for an access token. This way if the code is intercepted, it will not be useful since the token request relies on the initial secret.

```swift
let grantType: OAuth.GrantType = .pkce(.init())
oauth.authorize(provider: provider, grantType: grantType)
```

### OAuth 2.0 Device Code Flow
OAuthKit supports the [OAuth 2.0 Device Code Flow Grant](https://alexbilbie.github.io/2016/04/oauth-2-device-flow-grant/), which is used by apps that don't have access to a web browser (like tvOS). To leverage OAuthKit in tvOS apps, simply add the `deviceCodeURL` to your [OAuth.Provider](https://github.com/codefiesta/OAuthKit/blob/main/Sources/OAuthKit/OAuth+Provider.swift).

```swift
let grantType: OAuth.GrantType = .deviceCode
oauth.authorize(provider: provider, grantType: grantType)
```

![tvOS-screenshot](https://github.com/user-attachments/assets/14997164-f86a-4ee0-b6b7-8c0d9732c83e)


### OAuth 2.0 Client Credentials Flow

The OAuth 2.0 Client Credentials flow is a mechanism where a client application authenticates itself to an authorization server using its own credentials rather than a user's credentials. This flow is primarily used in server-to-server communication, where a service or application needs to access a protected resource without involving a user.

```swift
let grantType: OAuth.GrantType = .clientCredentials
oauth.authorize(provider: provider, grantType: grantType)
```

## OAuth 2.0 Provider Debugging
Standard `debugPrint` to the standard output is disabled by default. If you need to inspect response data received from [providers](https://github.com/codefiesta/OAuthKit/blob/main/Sources/OAuthKit/OAuth+Provider.swift), you can toggle the `debug` value to true. You can see an [example here](https://github.com/codefiesta/OAuthKit/blob/main/Tests/OAuthKitTests/Resources/oauth.json).

## OAuthKit Sample Application
You can find a sample application integrated with OAuthKit [here](https://github.com/codefiesta/OAuthSample).

## Security Best Practices
Although OAuthKit will automatically try to load the `oauth.json` file found inside your main bundle (or bundle passed to the initializer) for convenience purposes, it is good policy to **NEVER** check in **clientID** or **clientSecret** values into source control. Also, it is possible for someone to [inspect and reverse engineer](https://www.nowsecure.com/blog/2021/09/08/basics-of-reverse-engineering-ios-mobile-apps/) the contents of your app and look at any files inside your app bundle which means you could potentially expose these secrets in the `oauth.json` file. The most secure way to protect OAuth secrets is to build your Providers programatically and bake [secret values](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions) into your code via your CI pipeline.

## OAuth 2.0 Providers
* [Github](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps)
* [Google](https://developers.google.com/identity/protocols/oauth2)
	* **Important**: When creating a Google OAuth2 application from the [Google API Console](https://console.developers.google.com/) create an OAuth 2.0 Client type of Web Application (not iOS).
* [LinkedIn](https://developer.linkedin.com/)
	* **Important**: When creating a LinkedIn OAuth2 provider, you will need to explicitly set the `encodeHttpBody` property to false otherwise the /token request will fail. Unfortunately, OAuth providers vary in the way they decode the parameters of that request (either encoded into the httpBody or as query parameters). See sample [oauth.json](https://github.com/codefiesta/OAuthKit/blob/main/Tests/OAuthKitTests/Resources/oauth.json).
	* LinkedIn currently doesn't support **PKCE**.
* [Instagram](https://developers.facebook.com/docs/instagram-basic-display-api/guides/getting-access-tokens-and-permissions)
* [Microsoft](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-auth-code-flow)
    * **Important**: When registering an application inside the [Microsoft Azure Portal](https://portal.azure.com/) it's important to choose a **Redirect URI** as **Web** otherwise the `/token` endpoint will return an error when sending the `client_secret` in the body payload.
* [Slack](https://api.slack.com/authentication/oauth-v2)
    * **Important**: Slack will block unknown browsers from initiating OAuth workflows. See sample [oauth.json](https://github.com/codefiesta/OAuthKit/blob/main/Tests/OAuthKitTests/Resources/oauth.json) for setting the `customUserAgent` as a workaround.
* [Twitter](https://developer.x.com/en/docs/authentication/oauth-2-0)
	* **Unsupported**: Although OAuthKit *should* work with Twitter/X OAuth2 APIs without any modification, **@codefiesta** has chosen not to support any [Elon Musk](https://www.natesilver.net/p/elon-musk-polls-popularity-nate-silver-bulletin) backed ventures due to his facist, racist, and divisive behavior that epitomizes out-of-touch wealth and greed. **@codefiesta** will not raise objections to other developers who wish to contribute to OAuthKit in order to support Twitter OAuth2.
