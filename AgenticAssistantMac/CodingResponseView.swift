import SwiftUI

struct CodingResponseView: View {
    let code: String
    let language: String
    let complexity: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Code header with language and complexity
                HStack {
                    Text(language)
                        .font(.title3.weight(.medium))
                        .foregroundColor(.secondary)

                    Spacer()

                    // Complexity badge
                    Text(complexity)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.blue.opacity(0.2)))
                        .foregroundColor(.blue)
                }
                .padding(.bottom, 8)

                // Code content with syntax highlighting
                SyntaxHighlightedText(code: code, language: language)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
            complexity: "Time: O(n), Space: O(n)"
        )
        .padding()
        .frame(width: 500)
        .background(Color.gray.opacity(0.1))
    }
}