import AppKit

class InvisibleOverlayWindow: NSPanel {
    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 800),
            styleMask: [.borderless, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )

        // Core invisibility settings
        //self.sharingType = .none  // Excludes from screen capture
        self.level = .screenSaver + 1  // Above most windows
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .transient,
            .ignoresCycle,
            .stationary,
            .fullScreenNone
        ]

        // Visual settings
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovableByWindowBackground = true

        // Hide from system
        self.isExcludedFromWindowsMenu = true
        self.hidesOnDeactivate = false
        // self.setAccessibilityElement(false) // Deprecated in macOS 13
        // self.setAccessibilityRole(.unknown) // Deprecated

        // Disable screenshots
        //self.contentView?.wantsLayer = true
        self.contentView?.layer?.contentsGravity = .center
    }

    // Required initializer if you don't override the designated one or provide your own.
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Dragging Logic
    private var initialLocation: NSPoint?

    override func mouseDown(with event: NSEvent) {
        // Store the initial mouse location in window coordinates
        // The `isMovableByWindowBackground` property should handle basic dragging.
        // This override is for custom behavior like snapping or if `isMovableByWindowBackground` is false.
        // If `isMovableByWindowBackground` is true, this might not be strictly necessary
        // unless more complex drag logic (like the snapping below) is desired.
        self.initialLocation = event.locationInWindow
    }

    override func mouseDragged(with event: NSEvent) {
        // This logic is taken from the DraggableWindow example in the spec.
        // It's more advanced than simple isMovableByWindowBackground.
        // If isMovableByWindowBackground is true and this custom logic is not needed,
        // this method can be simplified or removed.

        // Ensure there's an initial location from mouseDown
        guard let initialLocation = self.initialLocation else {
            // If isMovableByWindowBackground is true, super.mouseDragged might still work.
            // super.mouseDragged(with: event)
            return
        }

        let currentLocation = event.locationInWindow
        var newOrigin = self.frame.origin

        // Calculate the difference (delta) from the initial mouse down position
        let deltaX = currentLocation.x - initialLocation.x
        let deltaY = currentLocation.y - initialLocation.y

        newOrigin.x += deltaX
        newOrigin.y += deltaY

        // Magnetic edge snapping (as per spec)
        let snapDistance: CGFloat = 20
        var snappedOrigin = newOrigin

        if let screen = self.screen ?? NSScreen.main { // Use window's screen or main screen
            let screenFrame = screen.visibleFrame // Use visibleFrame to avoid menu bar/Dock

            // Snap to left edge
            if abs(newOrigin.x - screenFrame.minX) < snapDistance {
                snappedOrigin.x = screenFrame.minX
            }
            // Snap to right edge
            else if abs(newOrigin.x + self.frame.width - screenFrame.maxX) < snapDistance {
                snappedOrigin.x = screenFrame.maxX - self.frame.width
            }

            // Snap to bottom edge
            if abs(newOrigin.y - screenFrame.minY) < snapDistance {
                snappedOrigin.y = screenFrame.minY
            }
            // Snap to top edge
            else if abs(newOrigin.y + self.frame.height - screenFrame.maxY) < snapDistance {
                snappedOrigin.y = screenFrame.maxY - self.frame.height
            }
        }

        self.setFrameOrigin(snappedOrigin)

        // Note: We are not calling super.mouseDragged(with: event) here because we are
        // fully managing the drag. If isMovableByWindowBackground was true and we wanted
        // to augment its behavior, we might call super.
    }

    // It's good practice to reset initialLocation on mouseUp to prevent stale data.
    override func mouseUp(with event: NSEvent) {
        self.initialLocation = nil

        // Save position when drag ends
        self.savePosition()

        // super.mouseUp(with: event) // If any superclass behavior is needed
    }
}
