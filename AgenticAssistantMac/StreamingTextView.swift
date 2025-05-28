import SwiftUI

struct StreamingTextView: View {
    let fullText: String
    @State private var displayedText: String = ""
    @State private var wordIndex: Int = 0
    
    private let wordsPerSecond: Double = 15 // Adjust speed as needed
    
    private var words: [String] {
        fullText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Text(displayedText)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Pulsing cursor during streaming
            if wordIndex < words.count {
                Text("▋")
                    .font(.system(size: 14))
                    .foregroundColor(.accentColor)
                    .opacity(0.7)
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true),
                        value: wordIndex
                    )
            }
        }
        .onAppear {
            startStreaming()
        }
        .onChange(of: fullText) { _ in
            // Reset and restart if text changes
            displayedText = ""
            wordIndex = 0
            startStreaming()
        }
    }
    
    private func startStreaming() {
        guard !words.isEmpty else { return }
        
        Timer.scheduledTimer(withTimeInterval: 1.0 / wordsPerSecond, repeats: true) { timer in
            if wordIndex < words.count {
                if !displayedText.isEmpty {
                    displayedText += " "
                }
                displayedText += words[wordIndex]
                wordIndex += 1
            } else {
                timer.invalidate()
            }
        }
    }
}

// Updated SimpleResponseView with streaming
struct SimpleResponseView: View {
    let text: String
    @State private var isStreaming = true
    
    var body: some View {
        ScrollView {
            if isStreaming {
                StreamingTextView(fullText: text)
                    .onTapGesture {
                        // Skip to full text on tap
                        isStreaming = false
                    }
            } else {
                Text(text)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct StreamingTextView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            StreamingTextView(fullText: "This is a demo of streaming text that appears word by word, creating a natural typing effect for the AI response.")
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            SimpleResponseView(text: "In Swift, `let` is used to declare constants, which are values that cannot be changed once assigned. `var` is used to declare variables, which can be reassigned a new value of the same type after their initial assignment.")
                .padding()
                .frame(width: 400, height: 200)
                .background(Color.gray.opacity(0.1))
        }
        .padding()
    }
}