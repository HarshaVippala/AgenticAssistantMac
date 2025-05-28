import SwiftUI

// Placeholder for Simple Response
// Placeholder for Coding Response

// Placeholder for Behavioral Response
// Helper to lowercase the first character of a string for smoother sentence flow
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