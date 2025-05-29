import SwiftUI

// Simple Response View - supports both single text and multiple Q&A pairs
struct SimpleResponseView: View {
    let text: String?
    let qaPairs: [SimpleQAPair]?
    @State private var isStreaming = true

    // Convenience initializers
    init(text: String) {
        self.text = text
        self.qaPairs = nil
    }

    init(qaPairs: [SimpleQAPair]) {
        self.text = nil
        self.qaPairs = qaPairs
    }

    var body: some View {
        ScrollView {
            if let qaPairs = qaPairs {
                // Multiple Q&A pairs view
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(qaPairs.enumerated()), id: \.offset) { index, qaPair in
                        VStack(alignment: .leading, spacing: 8) {
                            // Question
                            Text(qaPair.question)
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.primary)
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // Answer
                            Text(qaPair.answer)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Divider between Q&A pairs (except for the last one)
                        if index < qaPairs.count - 1 {
                            Divider()
                                .background(Color.secondary.opacity(0.3))
                                .padding(.vertical, 4)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if let text = text {
                // Single text view (legacy support)
                if isStreaming {
                    StreamingTextView(fullText: text)
                        .onTapGesture {
                            // Skip to full text on tap
                            isStreaming = false
                        }
                } else {
                    Text(text)
                        .font(.title3) // Increased font size for better readability
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
struct SystemDesignView: View {
    let diagram: DiagramPlaceholder // Using placeholder type
    let steps: [String]

    var body: some View {
        // The outer .padding() and .background() are removed.
        // Caption title removed.
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Diagram:")
                    .font(.title2.weight(.semibold)) // Increased font size
                Text(diagram.representation) // Simple text representation for now
                    .font(.system(.body, design: .monospaced))
                    .padding(.vertical, 8) // Slightly increased padding
                    .border(Color.gray.opacity(0.5)) // Lighter border

                Text("Steps:")
                    .font(.title2.weight(.semibold)) // Increased font size
                    .padding(.top)
                ForEach(steps, id: \.self) { step in
                    Text(step)
                        .font(.title3) // Increased font size for better readability
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
            SimpleResponseView(qaPairs: [
                SimpleQAPair(
                    question: "What is the difference between `let` and `var` in Swift?",
                    answer: "In Swift, `let` is used to declare constants, which are values that cannot be changed once assigned. `var` is used to declare variables, which can be reassigned a new value of the same type after their initial assignment."
                ),
                SimpleQAPair(
                    question: "What is optional binding in Swift?",
                    answer: "Optional binding is a way to safely unwrap optionals in Swift using `if let` or `guard let` statements. It allows you to check if an optional contains a value and, if so, extract that value into a new constant or variable."
                )
            ])
            SystemDesignView(diagram: DiagramPlaceholder(representation: "<Diagram ASCII Art>"), steps: ["Step 1", "Step 2", "Step 3"])
        }
        .padding()
    }
}