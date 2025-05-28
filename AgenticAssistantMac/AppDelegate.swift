import SwiftUI
import AppKit
import ScreenCaptureKit

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
            ResponseContainer(viewModel: self.responseViewModel ?? ResponseViewModel())
        }

        // Create the custom window with dynamic sizing
        overlayWindow = InvisibleOverlayWindow(
            contentRect: NSRect(x: 0, y: 0, width: 550, height: 450),
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
            let maxHeight = mainScreen.visibleFrame.height * 0.8
            let maxWidth = mainScreen.visibleFrame.width * 0.6
            overlayWindow?.maxSize = NSSize(width: maxWidth, height: maxHeight)
            overlayWindow?.minSize = NSSize(width: 320, height: 200)
        }
        
        // Initialize and start the event monitor
        eventMonitor = GlobalEventMonitor()
        eventMonitor?.appDelegate = self
        eventMonitor?.startMonitoring()
        
        // Setup screenshot capture handler
        setupScreenshotHandler()
    }

    func applicationWillTerminate(_ notification: Notification) {
        eventMonitor?.stopMonitoring()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep running even if overlay is hidden
    }

    // MARK: - Overlay Window Visibility Control
    
    func showOverlay() {
        guard let window = overlayWindow else { return }
        if !window.isVisible {
            window.moveToActiveScreen()
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
    
    func cycleResponseMode() {
        responseViewModel?.cycleResponseMode()
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
