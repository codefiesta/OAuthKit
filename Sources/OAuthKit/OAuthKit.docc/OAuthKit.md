# ``OAuthKit``

A modern and observable Swift Package for implementing OAuth 2.0 authorization flows.

@Metadata {
    @PageColor(purple)
}

## Overview

OAuthKit offers a robust, type-safe, and performant OAuth 2.0 implementation using the observer design pattern. This pattern allows applications to observe an ``OAuth`` object and be notified of ``OAuth/State`` changes. 

This has the advantage of avoiding direct coupling with an authorization flow, enabling highly flexible and fine-grained control when interacting with an ``OAuth/Provider``. It also allows updates across multiple observers.

### Featured

@Links(visualStyle: detailedGrid) {
    - <doc:GettingStarted>
    - <doc:SampleCode>
}

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:SampleCode>
- ``OAuth``

### State Observability
- ``OAuth/state``
