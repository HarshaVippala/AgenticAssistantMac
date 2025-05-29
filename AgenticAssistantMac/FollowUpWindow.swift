import AppKit
import SwiftUI

class FollowUpWindow: NSWindow {
    private var viewModel: FollowUpViewModel
    private weak var associatedWindow: NSWindow?

    init(parentWindow: NSWindow, responseMode: ResponseMode) {
        self.associatedWindow = parentWindow
        self.viewModel = FollowUpViewModel()

        // Calculate window size - half width of parent, same height
        let parentFrame = parentWindow.frame
        let windowWidth = parentFrame.width / 2
        let windowHeight = parentFrame.height

        // Position to the right of parent window
        let windowX = parentFrame.maxX + 10 // 10pt gap
        let windowY = parentFrame.minY

        let contentRect = NSRect(
            x: windowX,
            y: windowY,
            width: windowWidth,
            height: windowHeight
        )

        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )

        // Window configuration to match main window
        self.level = .screenSaver + 1  // Same level as main window
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .transient,
            .ignoresCycle,
            .stationary,
            .fullScreenNone
        ]

        // Visual settings to match main window
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovableByWindowBackground = true
        self.isReleasedWhenClosed = false
        self.hidesOnDeactivate = false

        // Hide from system
        self.isExcludedFromWindowsMenu = true

        // Set up the SwiftUI content
        setupContent(for: responseMode)

        // Update view model with the response mode
        viewModel.updateResponseMode(responseMode)
    }

    private func setupContent(for responseMode: ResponseMode) {
        let followUpView = FollowUpWindowView(viewModel: viewModel) { [weak self] in
            self?.close()
        }

        let hostingView = NSHostingView(rootView: followUpView)
        self.contentView = hostingView

        // Enable keyboard events
        self.makeFirstResponder(hostingView)
    }

    func updateResponseMode(_ mode: ResponseMode) {
        viewModel.updateResponseMode(mode)
    }

    func updatePosition(relativeTo parentWindow: NSWindow) {
        self.associatedWindow = parentWindow
        let parentFrame = parentWindow.frame
        let windowWidth = parentFrame.width / 2
        let windowHeight = parentFrame.height

        let windowX = parentFrame.maxX + 10
        let windowY = parentFrame.minY

        let newFrame = NSRect(
            x: windowX,
            y: windowY,
            width: windowWidth,
            height: windowHeight
        )

        self.setFrame(newFrame, display: true, animate: true)
    }

    // MARK: - Keyboard Event Handling

    override func keyDown(with event: NSEvent) {
        let keyCode = event.keyCode
        let modifierFlags = event.modifierFlags

        // Handle keyboard navigation
        switch keyCode {
        case 126: // Up arrow
            viewModel.moveSelectionUp()
            return

        case 125: // Down arrow
            viewModel.moveSelectionDown()
            return

        case 115: // Home
            viewModel.moveToFirst()
            return

        case 119: // End
            viewModel.moveToLast()
            return

        case 53: // Escape
            self.close()
            return

        case 13: // W key with Cmd modifier
            if modifierFlags.contains(.command) {
                self.close()
                return
            }

        default:
            break
        }

        // Pass unhandled events to super
        super.keyDown(with: event)
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return false
    }

    // MARK: - Window Lifecycle

    override func close() {
        // Notify parent that we're closing
        NotificationCenter.default.post(
            name: .followUpWindowDidClose,
            object: self,
            userInfo: ["responseMode": viewModel.currentResponseMode]
        )

        super.close()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let followUpWindowDidClose = Notification.Name("followUpWindowDidClose")
    static let toggleFollowUpWindow = Notification.Name("toggleFollowUpWindow")
}
