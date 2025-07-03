//
//  OAWebView.swift
//
//
//  Created by Kevin McKee on 5/16/24.
//

#if canImport(WebKit)
import SwiftUI
import WebKit

/// A UIViewRepresentable / NSViewRepresentable wrapper type that coordinates
/// oauth authorization flows inside a `WKWebView`.
@MainActor
public struct OAWebView {

    let oauth: OAuth
    let view: WKWebView

    /// Initializer with the speciifed oauth object,
    /// - Parameter oauth: the oauth object to use
    public init(oauth: OAuth) {
        self.oauth = oauth
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = oauth.useNonPersistentWebDataStore ? WKWebsiteDataStore.nonPersistent() : WKWebsiteDataStore.default()
        self.view = WKWebView(frame: .zero, configuration: configuration)
    }

    public func makeWebView(context: Context) -> WKWebView {
        view.navigationDelegate = context.coordinator
        view.allowsLinkPreview = true
        return view
    }

    public func makeCoordinator() -> OAWebViewCoordinator {
        OAWebViewCoordinator(self)
    }
}
#endif


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
        context.coordinator.update(state: oauth.state)
    }
}

#endif
