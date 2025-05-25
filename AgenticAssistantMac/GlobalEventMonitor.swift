import AppKit
import Foundation // For NSObject if not inheriting from AppKit class

class GlobalEventMonitor: NSObject {
    private var eventMonitor: Any?
    private var localMonitor: Any?
    
    // Weak reference to AppDelegate to call toggleVisibility or hide methods
    // This assumes AppDelegate will have these methods.
    weak var appDelegate: AppDelegate?

    override init() {
        super.init()
    }

    func startMonitoring() {
        // Global hotkey (Cmd+Shift+A)
        // Keycode for 'A' is 0.
        // Modifiers: .command, .shift
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
            }
        )
        
        // Local escape key handling (e.g., when the panel itself is key)
        // This might be better handled by the panel's view if it can become key.
        // For a non-activating panel, local monitors might not fire as expected
        // if the panel doesn't become the key window.
        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: .keyDown,
            handler: { [weak self] event in
                if event.keyCode == 53 { // Escape key
                    // Call a method on AppDelegate to hide the window
                    self?.appDelegate?.hideOverlay()
                    return nil // Consume the event
                }
                return event // Pass other events through
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

    deinit {
        stopMonitoring()
    }
}