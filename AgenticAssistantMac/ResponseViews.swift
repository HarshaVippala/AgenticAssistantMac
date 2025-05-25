import SwiftUI

// Placeholder for Simple Response
struct SimpleResponseView: View {
    let text: String
    
    var body: some View {
        ScrollView {
            Text(text)
                .fixedSize(horizontal: false, vertical: true) // Allow vertical expansion
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        // .frame(maxHeight: 400) // Removed to let content dictate height up to window's max
    }
}

// Placeholder for Coding Response
struct CodingResponseView: View {
    let code: String
    let language: String
    let complexity: String // Could be a more structured type
    // Placeholder for explanation or further details about the code
    var explanation: String? = "This code snippet demonstrates a common pattern for X. It's efficient because of Y. Consider edge case Z."
    
    var body: some View {
        // Using HStack for side-by-side layout
        HStack(alignment: .top, spacing: 15) {
            // Left side: Code block
            ScrollView {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(5) // Inner padding for the code text
                    .background(Color.black.opacity(0.05)) // Subtle background for code block
                    .cornerRadius(6)
            }
            .frame(minWidth: 150) // Ensure code block has some minimum width

            // Right side: Details (Language, Complexity, Explanation)
            VStack(alignment: .leading, spacing: 8) {
                Text("Language: \(language)")
                    .font(.caption.weight(.semibold))
                Text("Complexity: \(complexity)")
                    .font(.caption)
                
                if let explanationText = explanation, !explanationText.isEmpty {
                    Divider()
                    Text("Explanation:")
                        .font(.caption.weight(.semibold))
                        .padding(.top, 5)
                    ScrollView { // ScrollView for potentially long explanations
                        Text(explanationText)
                            .font(.caption)
                    }
                }
            }
            .frame(minWidth: 100) // Ensure details section has some minimum width
        }
        // .padding(8) // Optional internal padding for the whole HStack view
    }
}

// Placeholder for Behavioral Response
struct BehavioralResponseView: View {
    let starResponse: StarResponsePlaceholder // Using placeholder type
    
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
        // The outer .padding() and .background() are removed.
        // Caption title removed.
        // Headings for Situation, Task, Action, Result removed.
        ScrollView {
            Text(essayText)
                .fixedSize(horizontal: false, vertical: true) // Allow vertical expansion
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        // .frame(maxHeight: 500) // Removed to let content dictate height up to window's max
    }
}

// Helper to lowercase the first character of a string for smoother sentence flow
extension String {
    func lowercasedFirstChar() -> String {
        guard !self.isEmpty else { return self }
        return prefix(1).lowercased() + dropFirst()
    }
}

// Placeholder for System Design Response
struct SystemDesignView: View {
    let diagram: DiagramPlaceholder // Using placeholder type
    let steps: [String]
    
    var body: some View {
        // The outer .padding() and .background() are removed.
        // Caption title removed.
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Diagram:")
                    .font(.headline.weight(.semibold))
                Text(diagram.representation) // Simple text representation for now
                    .font(.system(.body, design: .monospaced))
                    .padding(.vertical, 5) // Reduced padding
                    .border(Color.gray.opacity(0.5)) // Lighter border
                
                Text("Steps:")
                    .font(.headline.weight(.semibold))
                    .padding(.top)
                ForEach(steps, id: \.self) { step in
                    Text(step)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // .padding(8) // Optional internal padding
        }
    }
}

struct ResponseViews_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SimpleResponseView(text: "This is a simple text response that might be quite long and require scrolling to see all of its content.")
            CodingResponseView(code: "func hello() {\n  print(\"Hello, World!\")\n}", language: "Swift", complexity: "O(1)")
            BehavioralResponseView(starResponse: StarResponsePlaceholder(situation: "S", task: "T", action: "A", result: "R"))
            SystemDesignView(diagram: DiagramPlaceholder(representation: "<Diagram ASCII Art>"), steps: ["Step 1", "Step 2", "Step 3"])
        }
        .padding()
    }
}