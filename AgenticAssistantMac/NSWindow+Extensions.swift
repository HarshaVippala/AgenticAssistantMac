import AppKit

extension NSWindow {
    // MARK: - Position Persistence

    private static let windowPositionXKey = "MainWindowPositionX"
    private static let windowPositionYKey = "MainWindowPositionY"

    func savePosition() {
        let origin = self.frame.origin
        UserDefaults.standard.set(origin.x, forKey: Self.windowPositionXKey)
        UserDefaults.standard.set(origin.y, forKey: Self.windowPositionYKey)
    }

    func restoreSavedPosition() -> Bool {
        let savedX = UserDefaults.standard.object(forKey: Self.windowPositionXKey) as? CGFloat
        let savedY = UserDefaults.standard.object(forKey: Self.windowPositionYKey) as? CGFloat

        guard let x = savedX, let y = savedY else {
            return false // No saved position
        }

        let savedOrigin = NSPoint(x: x, y: y)

        // Validate that the saved position is still on a valid screen
        let windowFrame = NSRect(origin: savedOrigin, size: self.frame.size)
        let isOnValidScreen = NSScreen.screens.contains { screen in
            screen.visibleFrame.intersects(windowFrame)
        }

        if isOnValidScreen {
            self.setFrameOrigin(savedOrigin)
            return true
        }

        return false // Saved position is no longer valid
    }

    func moveToActiveScreen() {
        guard let activeScreen = NSScreen.main ?? NSScreen.screens.first else { return }

        let screenFrame = activeScreen.visibleFrame
        let windowFrame = self.frame // Use self.frame as we are in an extension

        // Center on active screen
        let newOrigin = NSPoint(
            x: screenFrame.midX - windowFrame.width / 2,
            y: screenFrame.midY - windowFrame.height / 2
        )

        self.setFrameOrigin(newOrigin)
    }

    func followMouseAcrossScreens() {
        // Track mouse across displays
        // Note: This creates a global monitor. Ensure it's managed appropriately
        // (e.g., started/stopped when the window's behavior requires it, and removed on deinit if necessary).
        // For a persistent panel, this might be started when the panel is shown.
        NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self else { return } // Ensure self is still around

            let mouseLocation = NSEvent.mouseLocation // Global mouse location
            var mouseScreen: NSScreen?

            for screen in NSScreen.screens {
                if screen.frame.contains(mouseLocation) {
                    mouseScreen = screen
                    break
                }
            }

            guard let currentMouseScreen = mouseScreen else { return }

            // Check if the window is on a different screen than the mouse
            if self.screen != currentMouseScreen {
                // Move the window to the currentMouseScreen, centering it.
                let screenFrame = currentMouseScreen.visibleFrame
                let windowFrame = self.frame
                let newOrigin = NSPoint(
                    x: screenFrame.midX - windowFrame.width / 2,
                    y: screenFrame.midY - windowFrame.height / 2
                )
                self.setFrameOrigin(newOrigin)
            }
        }
        // Consider returning the monitor object if it needs to be removed later.
    }
}