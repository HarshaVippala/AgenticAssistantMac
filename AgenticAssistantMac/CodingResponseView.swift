import SwiftUI

struct CodingResponseView: View {
    let code: String
    let language: String
    let complexity: String
    var explanation: String? = "This code snippet demonstrates a common pattern for X. It's efficient because of Y. Consider edge case Z."
    
    @State private var isCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Code block with header
            VStack(alignment: .leading, spacing: 0) {
                // Code header
                HStack {
                    Text(language)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Complexity badge
                    Text(complexity)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.blue.opacity(0.2)))
                        .foregroundColor(.blue)
                    
                    // Copy button
                    Button(action: copyCode) {
                        Label(isCopied ? "Copied!" : "Copy", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                            .font(.caption)
                            .foregroundColor(isCopied ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.1))
                
                // Code content
                ScrollView {
                    Text(code)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
                .frame(maxHeight: 300)
                .background(Color.black.opacity(0.03))
            }
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
            )
            
            // Explanation section
            if let explanationText = explanation, !explanationText.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Explanation")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    
                    Text(explanationText)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)
            }
        }
    }
    
    private func copyCode() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        
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

struct CodingResponseView_Previews: PreviewProvider {
    static var previews: some View {
        CodingResponseView(
            code: """
            def reverse_string(s):
                return s[::-1]

            # Example usage:
            my_string = "hello"
            reversed_str = reverse_string(my_string)
            print(f"Original: {my_string}, Reversed: {reversed_str}")
            # Output: Original: hello, Reversed: olleh
            """,
            language: "python",
            complexity: "Time: O(n), Space: O(n)",
            explanation: "This implementation uses Python's slice notation to reverse the string. The [::-1] syntax creates a new string with elements in reverse order."
        )
        .padding()
        .frame(width: 500)
        .background(Color.gray.opacity(0.1))
    }
}