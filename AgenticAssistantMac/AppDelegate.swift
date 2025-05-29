import SwiftUI
import AppKit
import ScreenCaptureKit
import Combine

// AppDelegate to manage the custom InvisibleOverlayWindow
class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindow: InvisibleOverlayWindow?
    private var responseViewModel: ResponseViewModel?
    private var eventMonitor: GlobalEventMonitor?
    private var sizeUpdateCancellable: AnyCancellable?
    private var responseModeUpdateCancellable: AnyCancellable?
    private var isResizing = false

    // Follow-up window management
    private var followUpWindows: [ResponseMode: FollowUpWindow] = [:]

    // Window movement observer
    private var windowMoveObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the ResponseViewModel
        responseViewModel = ResponseViewModel()

        // Create the main UI for the overlay
        let mainOverlayView = GlassmorphicContainer {
            ResponseContainer(viewModel: self.responseViewModel ?? ResponseViewModel())
        }

        // Create the custom window with dynamic sizing
        overlayWindow = InvisibleOverlayWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 350),
            styleMask: [.borderless, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )

        // Set the content view
        overlayWindow?.contentView = NSHostingView(rootView: mainOverlayView)
        overlayWindow?.makeKeyAndOrderFront(nil)
        overlayWindow?.center()

        // Configure dynamic sizing
        if let mainScreen = NSScreen.main {
            let maxHeight = min(mainScreen.visibleFrame.height * 0.5, 500) // Reduced from 0.8 to 0.5 and capped at 500
            let maxWidth = mainScreen.visibleFrame.width * 0.6
            overlayWindow?.maxSize = NSSize(width: maxWidth, height: maxHeight)
            overlayWindow?.minSize = NSSize(width: 320, height: 150) // Reduced from 200 to 150
        }

        // Subscribe to idealContentSize changes for dynamic window sizing
        sizeUpdateCancellable = responseViewModel?.$idealContentSize
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] (newIdealSize: CGSize?) in
                guard let self = self,
                      let idealSize = newIdealSize,
                      idealSize.width > 0,
                      idealSize.height > 0 else { return }
                self.adjustOverlayWindowSize(forContentSize: idealSize)
            }

        // Subscribe to response mode changes for follow-up window updates
        responseModeUpdateCancellable = responseViewModel?.$responseMode
            .sink { [weak self] newMode in
                self?.updateFollowUpWindowsForMode(newMode)
            }

        // Initialize and start the event monitor
        eventMonitor = GlobalEventMonitor()
        eventMonitor?.appDelegate = self
        eventMonitor?.startMonitoring()

        // Setup screenshot capture handler
        setupScreenshotHandler()

        // Setup notification observers
        setupNotificationObservers()

        // Setup window movement observer
        setupWindowMovementObserver()
    }

    func applicationWillTerminate(_ notification: Notification) {
        eventMonitor?.stopMonitoring()
        sizeUpdateCancellable?.cancel()
        responseModeUpdateCancellable?.cancel()
        closeAllFollowUpWindows()

        // Remove window movement observer
        if let observer = windowMoveObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        NotificationCenter.default.removeObserver(self)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep running even if overlay is hidden
    }

    // MARK: - Dynamic Window Sizing

    private func adjustOverlayWindowSize(forContentSize idealSwiftUISize: CGSize) {
        guard let window = overlayWindow, !isResizing else { return }

        // Add padding for window chrome and margins
        let padding: CGFloat = 20 // Reduced padding for more compact layout
        let headerHeight: CGFloat = 40 // Reduced header height for more compact layout

        let idealWindowWidth = window.frame.width // Keep current width unchanged
        let idealWindowHeight = idealSwiftUISize.height + headerHeight + padding

        // Respect min/max size constraints and add reasonable limits
        let maxReasonableHeight: CGFloat = 400 // Prevent excessive growth - more compact
        let constrainedWidth = min(max(idealWindowWidth, window.minSize.width), window.maxSize.width)
        let constrainedHeight = min(max(idealWindowHeight, window.minSize.height), min(window.maxSize.height, maxReasonableHeight))

        let newSize = NSSize(width: constrainedWidth, height: constrainedHeight)

        // Only resize if there's a meaningful difference and prevent feedback loops
        let currentSize = window.frame.size
        let threshold: CGFloat = 20 // Increased threshold to prevent minor fluctuations
        let heightDiff = abs(newSize.height - currentSize.height)

        // Prevent continuous growth by checking if we're already close to the target size
        if heightDiff > threshold && heightDiff < 200 { // Don't resize if difference is too large (likely a measurement error)

            isResizing = true

            // Calculate new frame maintaining current position (or centering if needed)
            var newFrame = window.frame
            newFrame.size = newSize

            // Keep the window centered horizontally, adjust vertically from top
            let widthDiff = newSize.width - currentSize.width
            let actualHeightDiff = newSize.height - currentSize.height

            newFrame.origin.x -= widthDiff / 2
            newFrame.origin.y -= actualHeightDiff // Adjust from top

            // Ensure the new frame is reasonably positioned on screen
            if let screen = window.screen ?? NSScreen.main {
                let visibleRect = screen.visibleFrame
                if newFrame.maxX > visibleRect.maxX { newFrame.origin.x = visibleRect.maxX - newFrame.width }
                if newFrame.minX < visibleRect.minX { newFrame.origin.x = visibleRect.minX }
                if newFrame.maxY > visibleRect.maxY { newFrame.origin.y = visibleRect.maxY - newFrame.height }
                if newFrame.minY < visibleRect.minY { newFrame.origin.y = visibleRect.minY }
            }

            // Animate the resize with a shorter duration to reduce feedback
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.15
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().setFrame(newFrame, display: true)
            }) { [weak self] in
                // Reset the flag after animation completes
                self?.isResizing = false
            }
        }
    }

    // MARK: - Overlay Window Visibility Control

    func showOverlay() {
        guard let window = overlayWindow else { return }
        if !window.isVisible {
            // Try to restore saved position, fallback to centering if no saved position
            if !window.restoreSavedPosition() {
                window.moveToActiveScreen()
            }

            window.makeKeyAndOrderFront(nil)

            // Animate appearance
            window.alphaValue = 0
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                window.animator().alphaValue = 1
            }
        }
    }

    func hideOverlay() {
        guard let window = overlayWindow else { return }

        // Animate disappearance
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
        }) {
            window.orderOut(nil)
            window.alphaValue = 1 // Reset for next show
        }
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

    @MainActor
    func cycleResponseMode() {
        responseViewModel?.cycleResponseMode()
    }

    // MARK: - Follow-up Window Management

    func toggleFollowUpWindow() {
        guard let currentMode = responseViewModel?.responseMode,
              currentMode != .simple, // Don't show for simple mode
              let mainWindow = overlayWindow else { return }

        if let existingWindow = followUpWindows[currentMode] {
            if existingWindow.isVisible {
                existingWindow.close()
            } else {
                existingWindow.updatePosition(relativeTo: mainWindow)
                existingWindow.makeKeyAndOrderFront(nil)
            }
        } else {
            // Create new follow-up window for this mode
            let followUpWindow = FollowUpWindow(parentWindow: mainWindow, responseMode: currentMode)
            followUpWindows[currentMode] = followUpWindow
            followUpWindow.makeKeyAndOrderFront(nil)
        }
    }

    private func updateFollowUpWindowsForMode(_ newMode: ResponseMode) {
        // Hide all follow-up windows first
        for window in followUpWindows.values {
            if window.isVisible {
                window.orderOut(nil)
            }
        }

        // Show follow-up window for new mode if it exists and mode is not simple
        if newMode != .simple, let window = followUpWindows[newMode] {
            if let mainWindow = overlayWindow {
                window.updatePosition(relativeTo: mainWindow)
                window.updateResponseMode(newMode)
                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    private func closeAllFollowUpWindows() {
        for window in followUpWindows.values {
            window.close()
        }
        followUpWindows.removeAll()
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleToggleFollowUpWindow),
            name: .toggleFollowUpWindow,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFollowUpWindowDidClose(_:)),
            name: .followUpWindowDidClose,
            object: nil
        )
    }

    private func setupWindowMovementObserver() {
        guard let window = overlayWindow else { return }

        // Observe window movement to update follow-up windows
        windowMoveObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.updateFollowUpWindowPositions()
        }
    }

    private func updateFollowUpWindowPositions() {
        guard let mainWindow = overlayWindow else { return }

        // Update all visible follow-up windows to maintain their relative position
        for window in followUpWindows.values {
            if window.isVisible {
                window.updatePosition(relativeTo: mainWindow)
            }
        }
    }

    @objc private func handleToggleFollowUpWindow() {
        toggleFollowUpWindow()
    }

    @objc private func handleFollowUpWindowDidClose(_ notification: Notification) {
        if let responseMode = notification.userInfo?["responseMode"] as? ResponseMode {
            followUpWindows.removeValue(forKey: responseMode)
        }
    }

    // MARK: - Screenshot Handling

    private func setupScreenshotHandler() {
        // This would be triggered by a hotkey or other mechanism
        // For now, it's a placeholder for the screenshot → AI flow
    }

    func captureScreenshot() {
        captureScreenshotWithScreenCaptureKit()
    }

    private func captureScreenshotWithScreenCaptureKit() {
        Task {
            do {
                // 1. Get the main display (just grab the first one)
                guard let mainDisplay = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true).displays.first else {
                    print("No displays found")
                    return
                }

                // 2. Create filter and config
                let filter = SCContentFilter(display: mainDisplay, excludingWindows: [])
                let config = SCStreamConfiguration()
                config.capturesAudio = false
                config.minimumFrameInterval = CMTime(value: 1, timescale: 30)

                // 3. Create stream (no delegate)
                let stream = try SCStream(filter: filter, configuration: config, delegate: nil)

                // 4. Setup output handler
                let frameHandler = StreamFrameHandler { [weak self] cgImage in
                    guard let self = self else { return }
                    self.processScreenshot(cgImage)
                }
                try stream.addStreamOutput(frameHandler, type: .screen, sampleHandlerQueue: .main)

                // 5. Start stream
                try await stream.startCapture()

                // 6. Stop stream after a frame is delivered (inside your StreamFrameHandler, you can call stream.stopCapture())
                // You can add logic in StreamFrameHandler to do this automatically.
            } catch {
                print("Screen capture failed: \(error)")
            }
        }
    }

    private func processScreenshot(_ image: CGImage) {
        // Convert to data and send to AI backend
        // For now, just simulate a coding question response
        responseViewModel?.responseMode = .coding
        responseViewModel?.currentQuestion = "Explain the code in this screenshot"
        responseViewModel?.isLoading = true

        // Simulate AI response after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.responseViewModel?.isLoading = false
            // Response would be populated from AI
        }

        showOverlay()
    }
}

@main
struct AgenticAssistantMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            Text("Settings coming soon...")
                .padding()
        }
        .commands {
            AppCommands()
        }
    }
}

private class StreamFrameHandler: NSObject, SCStreamOutput {
    private let frameHandler: (CGImage) -> Void
    private var didDeliverFrame = false

    init(frameHandler: @escaping (CGImage) -> Void) {
        self.frameHandler = frameHandler
        super.init()
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard !didDeliverFrame else { return }
        guard type == .screen else { return }
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            didDeliverFrame = true
            frameHandler(cgImage)
        }
    }
}
