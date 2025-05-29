import SwiftUI

struct BehavioralResponseView: View {
    let starResponse: StarResponsePlaceholder
    @State private var isStreaming = true

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
        ScrollView {
            if isStreaming {
                StreamingTextView(fullText: essayText)
                    .onTapGesture {
                        // Skip to full text on tap
                        isStreaming = false
                    }
            } else {
                Text(essayText)
                    .font(.title3) // Increased font size for better readability
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
