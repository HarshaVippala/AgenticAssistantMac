import SwiftUI
import AppKit

struct GlassmorphicContainer<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    private var borderColor: Color {
        colorScheme == .dark 
            ? Color.white.opacity(0.18) 
            : Color.black.opacity(0.12)
    }

    var body: some View {
        ZStack {
            // Background blur using NSVisualEffectView
            VisualEffectBackground()
            
            // Content - no padding here since ResponseContainer handles it
            content
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(adaptiveBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(borderColor, lineWidth: 0.5)
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08),
            radius: colorScheme == .dark ? 16 : 8,
            x: 0,
            y: colorScheme == .dark ? 8 : 4
        )
        .shadow(
            color: Color.black.opacity(0.04),
            radius: 2,
            x: 0,
            y: 2
        )
    }
    
    var adaptiveBackground: Color {
        colorScheme == .dark 
            ? Color.black.opacity(0.3)
            : Color.white.opacity(0.4)
    }
}

// Enhanced NSVisualEffectView wrapper
struct VisualEffectBackground: NSViewRepresentable {
    @Environment(\.colorScheme) var colorScheme
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = colorScheme == .dark ? .hudWindow : .popover
        view.blendingMode = .behindWindow
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = 12
        view.layer?.cornerCurve = .continuous
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = colorScheme == .dark ? .hudWindow : .popover
    }
}

// Preview
struct GlassmorphicContainer_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GlassmorphicContainer {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Glassmorphic Container")
                        .font(.headline)
                    Text("This demonstrates the enhanced glassmorphic design with better shadows and blur effects.")
                        .font(.body)
                }
                .padding()
            }
            .frame(width: 400, height: 150)
            .padding(40)
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .previewDisplayName("Light Mode")
            
            GlassmorphicContainer {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Dark Mode Glass")
                        .font(.headline)
                    Text("Enhanced shadows and material for dark appearance.")
                        .font(.body)
                }
                .padding()
            }
            .frame(width: 400, height: 150)
            .padding(40)
            .background(Color.black)
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}