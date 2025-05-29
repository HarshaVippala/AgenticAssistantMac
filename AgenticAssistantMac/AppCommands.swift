import SwiftUI

struct AppCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .windowArrangement) {
            Divider()
            
            Button("Toggle Follow-up Q&A") {
                NotificationCenter.default.post(name: .toggleFollowUpWindow, object: nil)
            }
            .keyboardShortcut("u", modifiers: [.command, .shift])
            .help("Show or hide the Follow-up Q&A window")
        }
    }
}
