![Build](https://github.com/codefiesta/OAuthKit/actions/workflows/swift.yml/badge.svg)
![Swift 6.2+](https://img.shields.io/badge/Swift-6.2%2B-gold.svg)
![Xcode 26.0+](https://img.shields.io/badge/Xcode-26.0%2B-tomato.svg)
![iOS 26.0+](https://img.shields.io/badge/iOS-26.0%2B-crimson.svg)
![macOS 26.0+](https://img.shields.io/badge/macOS-26.0%2B-skyblue.svg)
![tvOS 26.0+](https://img.shields.io/badge/tvOS-26.0%2B-blue.svg)
![visionOS 26.0+](https://img.shields.io/badge/visionOS-26.0%2B-violet.svg)
![watchOS 26.0+](https://img.shields.io/badge/watchOS-26.0%2B-magenta.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-indigo.svg)](https://opensource.org/licenses/MIT)
![Code Coverage](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/codefiesta/87655b6e3c89b9198287b2fefbfa641f/raw/oauthkit-coverage.json)

# OAuthKit
<img src="https://github.com/user-attachments/assets/039ee445-42af-433d-9793-56fc36330952" height="100" align="left"/>

OAuthKit is a contemporary, event-driven Swift Package that utilizes the [Observation](https://developer.apple.com/documentation/observation) Framework to implement the observer design pattern and publish [OAuth 2.0](https://oauth.net/2/) events. This enables application developers to effortlessly configure OAuth Providers and concentrate on developing exceptional applications rather than being preoccupied with the intricacies of authorization flows.
<br clear="left"/>

## OAuthKit Features

OAuthKit is a small, lightweight package that provides out of the box [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/) safety support and [Observable](https://codefiesta.github.io/OAuthKit/documentation/oauthkit/oauth/state-swift.enum) OAuth 2.0 state events that allow fine grained control over when and how to start authorization flows. 

Key features include:

- [Simple Configuration](#oauthkit-configuration)
- [Keychain protection with biometrics or companion device](https://codefiesta.github.io/OAuthKit/documentation/oauthkit/configuration#Keychain-Protection)
- [Private Browsing with non-persistent WebKit Datastores](https://codefiesta.github.io/OAuthKit/documentation/oauthkit/configuration#Private-Browsing)
- [Custom URLSession](https://codefiesta.github.io/OAuthKit/documentation/oauthkit/configuration#URL-Session) configuration for complete control custom protocol specific data
- [Observable State](https://codefiesta.github.io/OAuthKit/documentation/oauthkit/gettingstarted#Observing-OAuth-State) driven events to allow full control over when and if users are prompted to authenticate with an OAuth provider
- Supports all Apple Platforms (iOS, macOS, tvOS, visionOS, watchOS)
- [Support for every OAuth 2.0 Flow](#oauthkit-authorization-flows)
	- [Authorization Code](#oauth-20-authorization-code-flow)
	- [PKCE](#oauth-20-pkce-flow)
	- [Device Code](#oauth-20-device-code-flow)
	- [Client Credentials](#oauth-20-client-credentials-flow)
	- [OpenID Connect](https://www.oauth.com/playground/oidc.html)

## OAuthKit Installation

OAuthKit can be installed using [Swift Package Manager](https://www.swift.org/documentation/package-manager/). If you need to build with Swift Tools `6.1` and Apple APIs > `26.0` use version [1.5.1](https://github.com/codefiesta/OAuthKit/releases/tag/1.5.1).

```swift
dependencies: [
    .package(url: "https://github.com/codefiesta/OAuthKit", from: "2.0.0")
]
```

## OAuthKit Usage

The following is an example of the simplest usage of using OAuthKit across multiple platforms (iOS, macOS, visionOS, tvOS, watchOS):

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

    #if canImport(WebKit)
    @Environment(\.openWindow)
    var openWindow
    
    @Environment(\.dismissWindow)
    private var dismissWindow
    #endif

    /// The view body that reacts to oauth state changes
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
            case .error(let provider, let error):
                Text("Error [\(provider.id)]: \(error.localizedDescription)")
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
    
    /// Reacts to oauth state changes by opening or closing authorization windows.
    /// - Parameter state: the published state change
    private func handle(state: OAuth.State) {
        #if canImport(WebKit)
        switch state {
        case .empty, .error, .requestingAccessToken, .requestingDeviceCode:
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

## OAuthKit Configuration
By default, the easiest way to configure OAuthKit is to simply drop an `oauth.json` file into your main bundle and it will get automatically loaded into your swift application and available as an [Environment](https://developer.apple.com/documentation/swiftui/environment) property wrapper. You can find an example `oauth.json` file [here](https://github.com/codefiesta/OAuthKit/blob/main/Tests/OAuthKitTests/Resources/oauth.json). OAuthKit provides flexible constructor options that allows developers to customize  how their oauth client is initialized and what features they want to implement. See the [oauth.init(\_:bundle:options)](https://codefiesta.github.io/OAuthKit/documentation/oauthkit/oauth) method for details.

### OAuth initialized from main bundle (default)
```swift
@Environment(\.oauth)
var oauth: OAuth
```
### OAuth initialized from specified bundle
If you want to customize your OAuth environment or are using modules in your application, you can also specify which bundle to load configure files from:

```swift
let oauth: OAuth = .init(.module)
```

### OAuth initialized with providers
If you are building your OAuth Providers programatically (recommended for production applications via a CI build pipeline for security purposes), you can pass providers and options as well.

```swift
let providers: [OAuth.Provider] = ...
let options: [OAuth.Option: Any] = [
    .applicationTag: "com.bundle.identifier",
    .autoRefresh: true,
    .useNonPersistentWebDataStore: true
]
let oauth: OAuth = .init(providers: providers, options: options)
```

### OAuth initialized with custom URLSession
To support custom protocols or URL schemes that your app supports, developers can pass a custom **.urlSession** option that will allow the configuration of custom [URLProtocol](https://developer.apple.com/documentation/foundation/urlprotocol) classes that can handle the loading of protocol-specific URL data.

```swift
// Custom URLSession
let configuration: URLSessionConfiguration = .ephemeral
configuration.protocolClasses = [CustomURLProtocol.self]
let urlSession: URLSession = .init(configuration: configuration)

let options: [OAuth.Option: Any] = [.urlSession: urlSession]
let oauth: OAuth = .init(.main, options: options)
```

### OAuth initialized with Keychain protection and Private Browsing
OAuthKit allows you to protect access to your keychain items with biometrics until successful local authentication. If the **.requireAuthenticationWithBiometricsOrCompanion** option is set to true, the device owner will need to be authenticated by biometry or a companion device before keychain items (tokens) can be accessed. OAuthKit uses a default [LAContext](https://developer.apple.com/documentation/localauthentication/lacontext), but if you need fine-grained control while evaluating a user’s identity, pass your own custom [LAContext](https://developer.apple.com/documentation/localauthentication/lacontext) to the options.

Developers can also implement private browsing by setting the **.useNonPersistentWebDataStore** option to true. This forces the [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview) used during authorization flows to use a non-persistent data store, preventing data from being written to the file system.


```swift
// Custom LAContext
let localAuthentication: LAContext = .init()
localAuthentication.localizedReason = "read tokens from keychain"
localAuthentication.localizedFallbackTitle = "Use password"
localAuthentication.touchIDAuthenticationAllowableReuseDuration = 10

let options: [OAuth.Option: Any] = [
    .localAuthentication: localAuthentication,
    .requireAuthenticationWithBiometricsOrCompanion: true,
    .useNonPersistentWebDataStore: true,
]
let oauth: OAuth = .init(.main, options: options)
```

## OAuthKit Authorization Flows
OAuth 2.0 authorization flows are started by calling the [oauth.authorize(provider:grantType:)](https://codefiesta.github.io/OAuthKit/documentation/oauthkit/oauth#Starting-an-authorization-flow) method.

A good resource to help understand the detailed steps involved in OAuth 2.0 authorization flows can be found on the [OAuth 2.0 Playground](https://www.oauth.com/playground/index.html).

```swift
oauth.authorize(provider: provider, grantType: grantType)
``` 


### OAuth 2.0 Authorization Code Flow
The [Authorization Code](https://oauth.net/2/grant-types/authorization-code/) grant type is used by confidential and public clients to exchange an authorization code for an access token. It is recommended that all clients use the [PKCE](#oauth-20-pkce-flow) extension with this flow as well to provide better security.

```swift	
// Generate a state and set the GrantType
let state: String = .secureRandom(32) // See String+Extensions
let grantType: OAuth.GrantType = .authorizationCode(state)
oauth.authorize(provider: provider, grantType: grantType)
```

### OAuth 2.0 PKCE Flow
PKCE ([RFC 7636](https://www.rfc-editor.org/rfc/rfc7636)) is an extension to the [Authorization Code](https://oauth.net/2/grant-types/authorization-code/) flow to prevent CSRF and authorization code injection attacks.

Proof Key for Code Exchange ([PKCE](https://oauth.net/2/pkce/)) is the default and recommended flow to use in OAuthKit as this technique involves the client first creating a secret on each authorization request, and then using that secret again when exchanging the authorization code for an access token. This way if the code is intercepted, it will not be useful since the token request relies on the initial secret.

```swift
// PKCE is the default workflow with an auto generated pkce object
oauth.authorize(provider: provider)

// Or you can specify the workflow to use PKCE and inject your own values
let grantType: OAuth.GrantType = .pkce(.init())
oauth.authorize(provider: provider, grantType: grantType)
```

### OAuth 2.0 Device Code Flow
OAuthKit supports the [OAuth 2.0 Device Code Flow Grant](https://alexbilbie.github.io/2016/04/oauth-2-device-flow-grant/), which is used by apps that don't have access to a web browser (like tvOS or watchOS). To leverage OAuthKit in tvOS or watchOS apps, simply add the `deviceCodeURL` to your [OAuth.Provider](https://github.com/codefiesta/OAuthKit/blob/main/Sources/OAuthKit/OAuth+Provider.swift).

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
Debugging output with [debugPrint(\_:separator:terminator:)](https://developer.apple.com/documentation/swift/debugprint(_:separator:terminator:)) into the standard output is disabled by default. If you need to inspect response data received from [providers](https://github.com/codefiesta/OAuthKit/blob/main/Sources/OAuthKit/OAuth+Provider.swift), you can toggle the `debug` value to true. You can see an [example here](https://github.com/codefiesta/OAuthKit/blob/main/Tests/OAuthKitTests/Resources/oauth.json).

## OAuthKit Sample Application
You can find a sample application integrated with OAuthKit [here](https://github.com/codefiesta/OAuthSample).

## Security Best Practices
1. Use the [PKCE](https://github.com/codefiesta/OAuthKit?tab=readme-ov-file#oauth-20-pkce-flow) workflow if possible in your public applications.
2. Never check in **clientID** or **clientSecret** values into source control. Although the **clientID** is public and the **clientSecret** is sensitive and private it is still widely regarded that *both* of these values should be always be treated as confidential.
3. Don't include `oauth.json` files in your publicly distributed applications. It is possible for someone to [inspect and reverse engineer](https://www.nowsecure.com/blog/2021/09/08/basics-of-reverse-engineering-ios-mobile-apps/) the contents of your app and look at any files inside your app bundle which means you could potentially expose any confidential values contained in this file.
4. Build OAuth Providers Programmatically via your CI Build Pipeline. Most continuous integration and delivery platforms have the ability to generate source code during build workflows that can get compiled into Swift byte code. It's should be feasible to write a step in the CI pipeline that generates a .swift file that provides access to a list of OAuth.Provider objects that have their confidential values set from the secure CI platform secret keys. This swift code can then compiled into the application as byte code. In practical terms, the security and obfuscation inherent in compiled languages make extracting confidential values difficult (but not impossible).
5. OAuth 2.0 providers shouldn't provide the ability for publicly distributed applications to initiate [Client Credentials](https://github.com/codefiesta/OAuthKit?tab=readme-ov-file#oauth-20-client-credentials-flow) workflows since it is possible for someone to extract your secrets.


## OAuth 2.0 Providers
OAuthKit should work with any standard OAuth2 provider. Below is a list of tested providers along with their OAuth2 documentation links. If you’re interested in seeing support or examples for a provider not listed here, please open an issue on our [here](https://github.com/codefiesta/OAuthKit/issues).

* [Auth0 / Okta](https://developer.okta.com/signup/)
* [Box](https://developer.box.com/guides/authentication/oauth2/)
* [Dropbox](https://developers.dropbox.com/oauth-guide)
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
* [Stripe](https://docs.stripe.com/stripe-apps/api-authentication/oauth)
* [Twitter](https://developer.x.com/en/docs/authentication/oauth-2-0)
	* **Unsupported**: Although OAuthKit *should* work with Twitter/X OAuth2 APIs without any modification, **@codefiesta** has chosen not to support any [Elon Musk](https://www.natesilver.net/p/elon-musk-polls-popularity-nate-silver-bulletin) backed ventures due to his facist, racist, and divisive behavior that epitomizes out-of-touch wealth and greed. **@codefiesta** will not raise objections to other developers who wish to contribute to OAuthKit in order to support Twitter OAuth2.

## OAuthKit Documentation

You can find the complete Swift DocC documentation for the [OAuthKit Framework here](https://codefiesta.github.io/OAuthKit/documentation/oauthkit/).

