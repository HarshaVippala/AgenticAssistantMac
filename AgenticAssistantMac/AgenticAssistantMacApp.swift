//
//  AgenticAssistantMacApp.swift
//  AgenticAssistantMac
//
//  Created by Harsha Vippala on 5/25/25.
//

import SwiftUI
import AppKit // Required for NSApplicationDelegate

// AppDelegate to manage the custom InvisibleOverlayWindow
class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindow: InvisibleOverlayWindow?
    private var responseViewModel: ResponseViewModel?
    private var eventMonitor: GlobalEventMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the ResponseViewModel
        responseViewModel = ResponseViewModel()

        // Create the main UI for the overlay
        let mainOverlayView = GlassmorphicContainer {
            ResponseContainer(viewModel: self.responseViewModel ?? ResponseViewModel()) // Fallback just in case
        }

        // Create the custom window
        overlayWindow = InvisibleOverlayWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 700), // Further adjusted initial size
            styleMask: [NSWindow.StyleMask.borderless, NSWindow.StyleMask.nonactivatingPanel, NSWindow.StyleMask.hudWindow],
            backing: NSWindow.BackingStoreType.buffered,
            defer: false
        )

        // Set the content view
        overlayWindow?.contentView = NSHostingView(rootView: mainOverlayView)
        overlayWindow?.makeKeyAndOrderFront(nil) // Show the window
        overlayWindow?.center() // Center it on screen initially
        
        // Set a maxSize for the window to prevent it from becoming too large
        if let mainScreen = NSScreen.main {
            let maxHeight = mainScreen.visibleFrame.height * 0.7 // 70% of visible screen height
            let maxWidth = mainScreen.visibleFrame.width * 0.8 // 80% of visible screen width (generous)
            overlayWindow?.maxSize = NSSize(width: maxWidth, height: maxHeight)
        }
        
        // To make the panel appear, especially if LSUIElement is true in Info.plist
        // and there are no other windows, you might need to explicitly activate the app.
        // However, for a non-activating panel, this might not be desired.
        // NSApp.activate(ignoringOtherApps: true)

        // Ensure the app remains active even without a standard window group
        // and to allow the panel to be shown.
        // NSApp.setActivationPolicy(.accessory) // Use .accessory if no Dock icon/menu is desired
                                             // This should be paired with LSUIElement in Info.plist
        
        // Initialize and start the event monitor
        eventMonitor = GlobalEventMonitor()
        eventMonitor?.appDelegate = self // Pass a reference to self
        eventMonitor?.startMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Clean up resources if needed
    }
    
    // Optional: Keep the app running if the last window (our panel) is closed.
    // This might not be strictly necessary for a panel that's meant to be toggled.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep running if you want to re-show the panel later
    }

    // MARK: - Overlay Window Visibility Control
    
    func showOverlay() {
        guard let window = overlayWindow else { return }
        if !window.isVisible {
            // Potentially move to active screen or last known position before showing
            window.moveToActiveScreen() // Example from spec, or restore saved position
            window.makeKeyAndOrderFront(nil)
            // Or simply: window.orderFront(nil) if it doesn't need to be key
        }
    }

    func hideOverlay() {
        overlayWindow?.orderOut(nil)
    }

    func toggleOverlayVisibility() {
        guard let window = overlayWindow else { return }
        if window.isVisible {
            hideOverlay()
        } else {
            showOverlay()
        }
    }
    
    // MARK: - Response Mode Control
    func cycleResponseMode() {
        // Ensure the overlay is visible when cycling modes, or make it visible.
        // If the window is hidden, cycling modes might not be user-visible.
        // Consider if showOverlay() should be called here if the window is not visible.
        // For now, it will only affect the content if the window is already visible.
        // if overlayWindow?.isVisible == false {
        //     showOverlay()
        // }
        responseViewModel?.cycleResponseMode()
    }
}

@main
struct AgenticAssistantMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No WindowGroup here, as the AppDelegate manages the window.
        // If you need settings or other utility windows, they can be added as separate Scenes.
        Settings {
            // Placeholder for settings view if needed in the future
            Text("Settings Placeholder")
        }
    }
}
