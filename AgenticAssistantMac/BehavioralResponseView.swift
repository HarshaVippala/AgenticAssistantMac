import SwiftUI

struct BehavioralResponseView: View {
    let starResponse: StarResponsePlaceholder
    @State private var isStreaming = true
    @State private var isCopied = false
    
    private var essayText: String {
        // Combine STAR components into an essay format with paragraph breaks
        return """
        \(starResponse.situation)

        My primary task was to \(starResponse.task.lowercasedFirstChar()).

        To address this, I \(starResponse.action.lowercasedFirstChar()).

        As a result, \(starResponse.result.lowercasedFirstChar()).
        """
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            ScrollView {
                if isStreaming {
                    StreamingTextView(fullText: essayText)
                        .onTapGesture {
                            // Skip to full text on tap
                            isStreaming = false
                        }
                } else {
                    Text(essayText)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            // Copy button at bottom right
            Button(action: copyResponse) {
                Label(isCopied ? "Copied!" : "Copy", systemImage: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                    .font(.caption)
                    .foregroundColor(isCopied ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }
    
    private func copyResponse() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(essayText, forType: .string)
        
        withAnimation(.easeInOut(duration: 0.2)) {
            isCopied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isCopied = false
            }
        }
    }
}

// Helper extension
extension String {
    func lowercasedFirstChar() -> String {
        guard !self.isEmpty else { return self }
        return prefix(1).lowercased() + dropFirst()
    }
}
