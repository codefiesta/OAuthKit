import OAuthKit
import SwiftUI

@main
struct OAuthApp: App {

    @Environment(\.oauth)
    var oauth: OAuth
    
    /// Build the scene body
    var body: some Scene {

        // The main window
        WindowGroup {
            ContentView()
        }
        
        // The authorization window
        WindowGroup(id: "oauth") {
            OAWebView(oauth: oauth)
        }
    }
}
