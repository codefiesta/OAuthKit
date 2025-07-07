# ``OAuthKit/OAuth/Provider``

@Metadata {
    @Available(iOS, introduced: "18.0")
    @Available(macOS, introduced: "15.0")
    @Available(tvOS, introduced: "18.0")
    @Available(visionOS, introduced: "2.0")
    @Available(watchOS, introduced: "11.0")
}

## Overview
The Provider holds the configuration data that is used for communicating with an OAuth 2.0 server. The easiest way to configure OAuthKit is to simply drop an `oauth.json` file into your main bundle and it will get automatically loaded into your swift application and available as an ``SwiftUICore/EnvironmentValues/oauth`` property wrapper. You can find an example `oauth.json` file [here](https://github.com/codefiesta/OAuthKit/blob/main/Tests/OAuthKitTests/Resources/oauth.json). 
```json
[
    {
        "id": "GitHub",
        "authorizationURL": "https://github.com/login/oauth/authorize",
        "accessTokenURL": "https://github.com/login/oauth/access_token",
        "deviceCodeURL": "https://github.com/login/device/code",
        "clientID": "CLIENT_ID",
        "clientSecret": "CLIENT_SECRET",
        "redirectURI": "oauthkit://callback",
        "scope": [
            "user",
            "repo",
            "openid"
        ],
        "debug": true
    }
]
```
> Warning: It's highly recommended that developers only use `oauth.json` files during development and don't include them in publicly distributed applications. It is possible for someone to [inspect and reverse engineer](https://www.nowsecure.com/blog/2021/09/08/basics-of-reverse-engineering-ios-mobile-apps/) the contents of your app and look at any files inside your app bundle which means you could potentially expose any confidential values contained in this file. It's recommended to build OAuth Providers Programmatically via your CI Build Pipeline. Most continuous integration and delivery platforms have the ability to generate source code during build workflows that can get compiled into Swift byte code. It's should be feasible to write a step in the CI pipeline that generates a .swift file that provides access to a list of OAuth.Provider objects that have their confidential values set from the secure CI platform secret keys. This swift code can then compiled into the application as byte code. In practical terms, the security and obfuscation inherent in compiled languages make extracting confidential values difficult (but not impossible).
