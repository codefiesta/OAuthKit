# ``OAuthKit/OAuth/GrantType``
@Metadata {
    @Available(iOS, introduced: "18.0")
    @Available(macOS, introduced: "15.0")
    @Available(tvOS, introduced: "18.0")
    @Available(visionOS, introduced: "2.0")
    @Available(watchOS, introduced: "11.0")
}

## Overview
A GrantType is used to define how an application obtains an access token from an OAuth 2.0 server. OAuthKit supports all major OAuth 2.0 grant types:
- [Authorization Code](#Enumeration-Cases)
- [Client Credentials](#Enumeration-Cases)
- [Device Code](#Enumeration-Cases)
- [Proof Key for Code Exchange (PKCE)](#Enumeration-Cases)
- [Refresh Token](#Enumeration-Cases)


> Important: For apps that don't have access to a web browser (like tvOS or watchOS), you'll need to start
an ``OAuth/authorize(provider:grantType:)`` flow with the ``deviceCode`` grant Type. See <doc:GettingStarted> for more details.

> Tip: The [OAuth 2.0 Playground](https://www.oauth.com/playground/index.html) will help you understand the OAuth authorization flows and show each step of the process of obtaining an access token.

## Topics

### Associated Values

- ``OAuth/PKCE``
- ``OAuth/DeviceCode``
