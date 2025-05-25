# AgentAssist macOS Native App Specification
## Swift/AppKit Technical Architecture

### Version 1.0 - macOS Exclusive
### Date: January 2025

---

## 1. Executive Summary

A native macOS application built with Swift that provides an undetectable overlay assistant for real-time conversation support. By leveraging macOS-specific APIs and private frameworks, the app achieves complete invisibility from screen recording, streaming software, and system detection mechanisms.

---

## 2. Technology Stack

### 2.1 Core Technologies

```yaml
Language: Swift 5.9
UI Framework: SwiftUI + AppKit hybrid
Minimum Target: macOS 13.0 (Ventura)
Architecture: Universal Binary (Apple Silicon + Intel)

Key Frameworks:
  - AppKit: Window management, private APIs
  - SwiftUI: Modern UI components  
  - CoreGraphics: Advanced rendering
  - IOKit: Hardware overlay access
  - Combine: Reactive data flow
  - Network.framework: WebSocket client
```

### 2.2 Why Native Swift

1. **Private API Access**: Undocumented window APIs for invisibility
2. **System Integration**: Deep macOS security and privacy features
3. **Performance**: Direct Metal rendering, no web overhead
4. **App Store Exempt**: Can use private APIs as non-store app
5. **User Trust**: Native apps feel more trustworthy on macOS

---

## 3. Undetectability Architecture

### 3.1 Window Configuration

```swift
class InvisibleOverlayWindow: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.borderless, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )
        
        // Core invisibility settings
        self.sharingType = .none  // Excludes from screen capture
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
        self.setAccessibilityElement(false)
        self.setAccessibilityRole(.unknown)
        
        // Disable screenshots
        self.contentView?.wantsLayer = true
        self.contentView?.layer?.contentsGravity = .center
    }
}
```

### 3.2 Advanced Invisibility Techniques

```yaml
Screen Recording Bypass:
  - NSWindow.SharingType.none: Primary method
  - CGWindowListCreateImage exclusion flags
  - Private CGSSetWindowSharingState() API
  - NSWindowOcclusionState monitoring

Process Hiding:
  - LSUIElement = true in Info.plist
  - No dock icon, no menu bar
  - Hidden from Activity Monitor (using task_policy)
  - Randomized bundle identifier

Accessibility Bypass:
  - Custom NSAccessibility implementation
  - Return nil for all accessibility queries
  - Disable VoiceOver interaction
  - Hide from accessibility inspector
```

### 3.3 Display Link Integration

```swift
// Use private DisplayLink API for true overlay
class HardwareOverlay {
    private var displayLink: CVDisplayLink?
    private var ioSurfaceRef: IOSurfaceRef?
    
    func createHardwareOverlay() {
        // Create IOSurface for hardware compositing
        let properties: [String: Any] = [
            kIOSurfaceWidth: 400,
            kIOSurfaceHeight: 300,
            kIOSurfaceBytesPerElement: 4,
            kIOSurfacePixelFormat: kCVPixelFormatType_32BGRA,
            kIOSurfaceIsGlobal: true
        ]
        
        ioSurfaceRef = IOSurfaceCreate(properties as CFDictionary)
        
        // Bind to display hardware layer
        // This renders below the window server capture layer
    }
}
```

---

## 4. UI Architecture

### 4.1 SwiftUI + AppKit Hybrid Approach

```yaml
Window Management: AppKit (NSWindow/NSPanel)
Content Rendering: SwiftUI Views
Blur Effects: NSVisualEffectView
Animation: Core Animation
Text Rendering: Core Text for precision
```

### 4.2 Glassmorphism Implementation

```swift
struct GlassmorphicContainer: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background blur using NSVisualEffectView
            VisualEffectBackground()
            
            // Content with adaptive colors
            ContentView()
                .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(adaptiveBackground)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(borderColor, lineWidth: 0.5)
        )
    }
    
    var adaptiveBackground: Color {
        colorScheme == .dark 
            ? Color.black.opacity(0.3)
            : Color.white.opacity(0.4)
    }
}

// NSVisualEffectView wrapper
struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = 12
        return view
    }
}
```

### 4.3 Response Mode Views

```swift
// Dynamic view switching based on response type
struct ResponseContainer: View {
    @StateObject var viewModel: ResponseViewModel
    
    var body: some View {
        Group {
            switch viewModel.responseMode {
            case .simple:
                SimpleResponseView(text: viewModel.content)
                
            case .coding:
                CodingResponseView(
                    code: viewModel.code,
                    language: viewModel.language,
                    complexity: viewModel.complexity
                )
                
            case .behavioral:
                BehavioralResponseView(star: viewModel.starResponse)
                
            case .systemDesign:
                SystemDesignView(
                    diagram: viewModel.diagram,
                    steps: viewModel.designSteps
                )
            }
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.95)),
            removal: .opacity
        ))
        .animation(.spring(response: 0.3), value: viewModel.responseMode)
    }
}
```

---

## 5. System Integration

### 5.1 Global Event Monitoring

```swift
class GlobalEventMonitor {
    private var eventMonitor: Any?
    private var localMonitor: Any?
    
    func startMonitoring() {
        // Global hotkey (Cmd+Shift+A)
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.keyDown],
            handler: { [weak self] event in
                if event.modifierFlags.contains([.command, .shift]) 
                    && event.keyCode == 0 { // 'A' key
                    self?.toggleVisibility()
                }
            }
        )
        
        // Local escape key handling
        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: .keyDown,
            handler: { [weak self] event in
                if event.keyCode == 53 { // Escape
                    self?.hide()
                    return nil
                }
                return event
            }
        )
    }
}
```

### 5.2 Drag Implementation

```swift
class DraggableWindow: NSWindow {
    private var initialLocation: NSPoint?
    
    override func mouseDown(with event: NSEvent) {
        initialLocation = event.locationInWindow
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let initialLocation = initialLocation else { return }
        
        let currentLocation = event.locationInWindow
        let newOrigin = NSPoint(
            x: frame.origin.x + (currentLocation.x - initialLocation.x),
            y: frame.origin.y + (currentLocation.y - initialLocation.y)
        )
        
        // Magnetic edge snapping
        let snapDistance: CGFloat = 20
        var snappedOrigin = newOrigin
        
        if let screen = screen {
            let screenFrame = screen.visibleFrame
            
            // Snap to edges
            if abs(newOrigin.x - screenFrame.minX) < snapDistance {
                snappedOrigin.x = screenFrame.minX
            } else if abs(newOrigin.x + frame.width - screenFrame.maxX) < snapDistance {
                snappedOrigin.x = screenFrame.maxX - frame.width
            }
            
            if abs(newOrigin.y - screenFrame.minY) < snapDistance {
                snappedOrigin.y = screenFrame.minY
            } else if abs(newOrigin.y + frame.height - screenFrame.maxY) < snapDistance {
                snappedOrigin.y = screenFrame.maxY - frame.height
            }
        }
        
        setFrameOrigin(snappedOrigin)
    }
}
```

### 5.3 Multi-Display Support

```swift
extension NSWindow {
    func moveToActiveScreen() {
        guard let activeScreen = NSScreen.main ?? NSScreen.screens.first else { return }
        
        let screenFrame = activeScreen.visibleFrame
        let windowFrame = frame
        
        // Center on active screen
        let newOrigin = NSPoint(
            x: screenFrame.midX - windowFrame.width / 2,
            y: screenFrame.midY - windowFrame.height / 2
        )
        
        setFrameOrigin(newOrigin)
    }
    
    func followMouseAcrossScreens() {
        // Track mouse across displays
        NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            guard let self = self,
                  let mouseScreen = NSScreen.screenContainingMouse else { return }
            
            if self.screen != mouseScreen {
                self.moveToScreen(mouseScreen)
            }
        }
    }
}
```

---

## 6. Backend Integration

### 6.1 Native WebSocket Client

```swift
import Network

class RealtimeConnection {
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "ws.agentassist")
    
    func connect() {
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        
        let websocketOptions = NWProtocolWebSocket.Options()
        websocketOptions.autoReplyPing = true
        
        parameters.defaultProtocolStack.applicationProtocols.insert(
            websocketOptions, at: 0
        )
        
        connection = NWConnection(
            host: "localhost",
            port: 8080,
            using: parameters
        )
        
        connection?.start(queue: queue)
        receiveMessages()
    }
    
    private func receiveMessages() {
        connection?.receiveMessage { [weak self] data, context, isComplete, error in
            if let data = data, let message = try? JSONDecoder().decode(
                ResponseMessage.self, from: data
            ) {
                DispatchQueue.main.async {
                    self?.handleMessage(message)
                }
            }
            
            self?.receiveMessages() // Continue receiving
        }
    }
}
```

### 6.2 Combine-based State Management

```swift
class ConversationViewModel: ObservableObject {
    @Published var currentQuestion: String = ""
    @Published var response: ResponseContent?
    @Published var isLoading = false
    @Published var responseMode: ResponseMode = .simple
    
    private var cancellables = Set<AnyCancellable>()
    private let connection: RealtimeConnection
    
    init() {
        // Subscribe to transcript updates
        NotificationCenter.default
            .publisher(for: .transcriptUpdated)
            .compactMap { $0.object as? String }
            .sink { [weak self] transcript in
                self?.processTranscript(transcript)
            }
            .store(in: &cancellables)
        
        // Subscribe to classification results
        connection.classificationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] classification in
                self?.responseMode = classification.mode
            }
            .store(in: &cancellables)
    }
}
```

---

## 7. Performance Optimization

### 7.1 Metal Rendering for Complex Views

```swift
class MetalRenderer {
    private let device = MTLCreateSystemDefaultDevice()!
    private let commandQueue: MTLCommandQueue
    
    func renderBlur(input: CIImage) -> CIImage? {
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(input, forKey: kCIInputImageKey)
        filter?.setValue(20.0, forKey: kCIInputRadiusKey)
        
        // Use Metal for GPU acceleration
        let context = CIContext(mtlDevice: device)
        return filter?.outputImage
    }
}
```

### 7.2 Response Streaming

```swift
actor ResponseStreamer {
    private var buffer: String = ""
    private let updateThrottle = AsyncStream<String>.Continuation.BufferingPolicy.bufferingNewest(10)
    
    func stream(chunks: AsyncStream<String>) async {
        for await chunk in chunks {
            buffer.append(chunk)
            
            // Throttled UI updates
            if buffer.count % 5 == 0 {
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .responseChunk,
                        object: buffer
                    )
                }
            }
        }
    }
}
```

---

## 8. Security & Privacy

### 8.1 Hardened Runtime

```yaml
Entitlements:
  com.apple.security.hardened-runtime: true
  com.apple.security.automation.apple-events: false
  com.apple.security.temporary-exception.mach-lookup: false
  
Code Signing:
  - Developer ID certificate
  - Notarization required
  - Runtime hardening enabled
  - Library validation enforced
```

### 8.2 Secure Data Handling

```swift
class SecureMemory {
    static func allocateSecure(size: Int) -> UnsafeMutableRawPointer {
        let memory = UnsafeMutableRawPointer.allocate(
            byteCount: size,
            alignment: MemoryLayout<UInt8>.alignment
        )
        
        // Lock memory to prevent swapping
        mlock(memory, size)
        
        // Clear on allocation
        memset_s(memory, size, 0, size)
        
        return memory
    }
    
    static func deallocateSecure(pointer: UnsafeMutableRawPointer, size: Int) {
        // Secure wipe before deallocation
        memset_s(pointer, size, 0, size)
        munlock(pointer, size)
        pointer.deallocate()
    }
}
```

---

## 9. Distribution Strategy

### 9.1 Direct Distribution (Recommended)

```yaml
Method: DMG with custom installer
Benefits:
  - No App Store restrictions
  - Can use private APIs
  - Custom update mechanism
  - Better for enterprise

Installer Features:
  - Accessibility permission request
  - Login item setup
  - Security bypass instructions
  - Uninstaller included
```

### 9.2 Update Mechanism

```swift
class Updater {
    func checkForUpdates() {
        // Sparkle framework integration
        let updater = SUUpdater.shared()
        updater.feedURL = URL(string: "https://agentassist.app/appcast.xml")
        updater.automaticallyChecksForUpdates = true
        updater.updateCheckInterval = 86400 // Daily
    }
}
```

---

## 10. Testing Strategy

### 10.1 Undetectability Testing

```yaml
Screen Recording Apps:
  - OBS Studio
  - ScreenFlow
  - QuickTime Player
  - Loom
  - CleanShot X

Video Conferencing:
  - Zoom (all sharing modes)
  - Teams
  - Google Meet
  - Webex
  - Discord

System Tools:
  - Screenshot app
  - Screen recording
  - Accessibility Inspector
  - Activity Monitor
```

### 10.2 Performance Testing

```swift
class PerformanceMonitor {
    func measureRenderingPerformance() {
        let displayLink = CADisplayLink(
            target: self,
            selector: #selector(displayTick)
        )
        
        // Monitor frame drops
        // Target: 120fps on ProMotion displays
    }
}
```

---

## 11. Unique macOS Features

### 11.1 Continuity Integration

```swift
// Handoff support for multi-device users
extension NSUserActivity {
    static func createAssistActivity(question: String) -> NSUserActivity {
        let activity = NSUserActivity(activityType: "com.agentassist.conversation")
        activity.title = "Continue Conversation"
        activity.userInfo = ["question": question]
        activity.isEligibleForHandoff = true
        return activity
    }
}
```

### 11.2 Touch Bar Support (Intel Macs)

```swift
extension NSTouchBar {
    static func makeAssistTouchBar() -> NSTouchBar {
        let touchBar = NSTouchBar()
        touchBar.customizationIdentifier = "com.agentassist.touchbar"
        touchBar.defaultItemIdentifiers = [
            .modeSelector,
            .copyResponse,
            .flexibleSpace,
            .dismiss
        ]
        return touchBar
    }
}
```

### 11.3 Stage Manager Compatibility

```swift
// Ensure window works with Stage Manager
window.collectionBehavior.insert(.fullScreenNone)
window.collectionBehavior.insert(.moveToActiveSpace)
window.setFrameAutosaveName("AssistWindow") // Remember position
```

---

## 12. Implementation Timeline

### Week 1-2: Core Window System
- [ ] Invisible window implementation
- [ ] Dragging and positioning
- [ ] Global hotkey activation
- [ ] Basic UI shell

### Week 3-4: UI Components
- [ ] Glassmorphic design
- [ ] Response mode views
- [ ] Animations and transitions
- [ ] Dark mode support

### Week 5-6: Backend Integration
- [ ] WebSocket connection
- [ ] State management
- [ ] Response streaming
- [ ] Error handling

### Week 7-8: Polish & Testing
- [ ] Performance optimization
- [ ] Undetectability verification
- [ ] Security hardening
- [ ] Beta testing

---

## 13. Success Metrics

- **0% detection rate** across all major screen recording tools
- **<50MB memory footprint**
- **60-120fps** rendering on all displays
- **<100ms** response to user input
- **99.9%** crash-free sessions
- **5-star** user experience rating