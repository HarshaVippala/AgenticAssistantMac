import SwiftUI

struct StreamingTextView: View {
    let fullText: String
    @State private var displayedText: String = ""
    @State private var currentIndex: Int = 0

    private let charactersPerBatch: Int = 3
    private let delay: TimeInterval = 0.02

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Text(displayedText)
                .font(.title3) // Increased font size for better readability
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Pulsing cursor during streaming
            if currentIndex < fullText.count {
                Text("▋")
                    .font(.title3) // Match the text font size
                    .foregroundColor(.accentColor)
                    .opacity(0.7)
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true),
                        value: currentIndex
                    )
            }
        }
        .task {
            await streamText()
        }
        .onChange(of: fullText) {
            // Reset when text changes
            displayedText = ""
            currentIndex = 0
            Task {
                await streamText()
            }
        }
    }

    @MainActor
    private func streamText() async {
        let characters = Array(fullText)

        while currentIndex < characters.count {
            let endIndex = min(currentIndex + charactersPerBatch, characters.count)
            let batch = String(characters[currentIndex..<endIndex])
            displayedText.append(batch)
            currentIndex = endIndex

            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
    }
}


