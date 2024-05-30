//
//  OAWebView.swift
//
//
//  Created by Kevin McKee on 5/16/24.
//

import SwiftUI
import WebKit

public struct OAWebView {

    @EnvironmentObject
    var oauth: OAuth
    let view = WKWebView()

    /// Public Initializer.
    public init() { }

    public func makeWebView(context: Context) -> WKWebView {
        view.navigationDelegate = context.coordinator
        view.allowsLinkPreview = true
        return view
    }

    public func makeCoordinator() -> OAWebViewCoordinator {
        OAWebViewCoordinator(self)
    }
}

#if os(iOS) || os(visionOS)

extension OAWebView: UIViewRepresentable {

    public func makeUIView(context: Context) -> WKWebView {
        makeWebView(context: context)
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.update(state: oauth.state)
    }
}

#elseif os(macOS)

extension OAWebView: NSViewRepresentable {

    public func makeNSView(context: Context) -> some NSView {
        makeWebView(context: context)
    }

    public func updateNSView(_ nsView: NSViewType, context: Context) {
        debugPrint("✅ [Pushing state]", oauth.state)
        context.coordinator.update(state: oauth.state)
    }
}

#endif
