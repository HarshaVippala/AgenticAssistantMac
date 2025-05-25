import SwiftUI
import AppKit

struct GlassmorphicContainer<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    // Placeholder for borderColor, to be defined based on design system
    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.2) : Color.gray.opacity(0.3)
    }

    var body: some View {
        ZStack {
            // Background blur using NSVisualEffectView
            VisualEffectBackground()
            
            // Content with adaptive colors
            content
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
        view.material = .hudWindow // .sidebar, .titlebar, .menu, .popover, .hudWindow, .sheet, .windowBackground
        view.blendingMode = .behindWindow
        view.state = .active // Follows window state, or .active, .inactive
        view.wantsLayer = true
        view.layer?.cornerRadius = 12
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        // Update the view if needed
    }
}

// Preview
struct GlassmorphicContainer_Previews: PreviewProvider {
    static var previews: some View {
        GlassmorphicContainer {
            Text("Hello, Glassmorphism!")
                .padding()
        }
        .frame(width: 300, height: 200)
        .padding()
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.light)

        GlassmorphicContainer {
            VStack {
                Text("Dark Mode")
                Button("A Button") {}
            }
            .padding()
        }
        .frame(width: 300, height: 200)
        .padding()
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
}