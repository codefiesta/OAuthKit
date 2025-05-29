//
//  OAWebView.swift
//
//
//  Created by Kevin McKee on 5/16/24.
//

#if !os(tvOS)
import SwiftUI
import WebKit

/// A UIViewRepresentable / NSViewRepresentable wrapper type that coordinates
/// oauth authorization flows inside a WKWebView.
@MainActor
public struct OAWebView {

    @Environment(\.oauth)
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
