# ``OAuthKit/OAuth/Authorization``
@Metadata {
    @Available(iOS, introduced: "18.0")
    @Available(macOS, introduced: "15.0")
    @Available(tvOS, introduced: "18.0")
    @Available(visionOS, introduced: "2.0")
    @Available(watchOS, introduced: "11.0")
}

## Overview
When an ``OAuth/Provider`` has issued an access ``token``, an `Authorization` is created and stored inside the user's `Keychain`. The `Authorization` holds an access ``token`` along with additional properties about the authorization such as the ``issuer``, when the token was ``issued``, and it's ``expiration``.

- SeeAlso:
[Access Token Response](https://www.oauth.com/oauth2-servers/access-tokens/access-token-response/)

## Topics

### Essentials

- ``OAuth/State``
- ``OAuth/State/authorized(_:_:)``
- ``Foundation/URLRequest/addAuthorization(auth:)``
