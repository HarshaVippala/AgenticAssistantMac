import AppKit
import Foundation

class GlobalEventMonitor: NSObject {
    private var eventMonitor: Any?
    private var localMonitor: Any?
    
    weak var appDelegate: AppDelegate?

    override init() {
        super.init()
    }

    func startMonitoring() {
        // Global hotkeys
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.keyDown],
            handler: { [weak self] event in
                // Toggle visibility with Cmd+Shift+A (keyCode 0 for 'A')
                if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 0 {
                    self?.appDelegate?.toggleOverlayVisibility()
                }
                // Cycle response modes with Cmd+Shift+S (keyCode 1 for 'S')
                else if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 1 {
                    self?.appDelegate?.cycleResponseMode()
                }
                // Capture screenshot with Cmd+Shift+C (keyCode 8 for 'C')
                else if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 8 {
                    self?.appDelegate?.captureScreenshot()
                }
            }
        )
        
        // Local escape key handling
        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: .keyDown,
            handler: { [weak self] event in
                if event.keyCode == 53 { // Escape key
                    self?.appDelegate?.hideOverlay()
                    return nil // Consume the event
                }
                
                // Additional local shortcuts when overlay is active
                if let window = self?.appDelegate?.overlayWindow, window.isKeyWindow {
                    // Cmd+C to copy response
                    if event.modifierFlags.contains(.command) && event.keyCode == 8 {
                        self?.copyCurrentResponse()
                        return nil
                    }
                }
                
                return event
            }
        )
    }

    func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
    
    private func copyCurrentResponse() {
        // This would copy the current response based on the active mode
        // Implementation would depend on the current view model state
        NSSound.beep() // Audio feedback
    }

    deinit {
        stopMonitoring()
    }
}