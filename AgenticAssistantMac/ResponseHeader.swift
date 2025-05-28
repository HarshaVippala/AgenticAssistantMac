import SwiftUI

struct ResponseHeader: View {
    let question: String
    let mode: ResponseMode
    let onClose: () -> Void
    
    private var modeIcon: String {
        switch mode {
        case .simple:
            return "💬"
        case .coding:
            return "🟨"
        case .behavioral:
            return "🟩"
        case .systemDesign:
            return "🟥"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Mode icon
            Text(modeIcon)
                .font(.system(size: 16))
            
            // Question text
            Text(question)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Close button
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary.opacity(0.6))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Close (Esc)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.secondary.opacity(0.05))
        .overlay(
            Divider()
                .background(Color.secondary.opacity(0.2)),
            alignment: .bottom
        )
    }
}

struct ResponseHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            ResponseHeader(
                question: "How do you implement a binary search tree in Python?",
                mode: .coding,
                onClose: {}
            )
            Spacer()
        }
        .frame(width: 500, height: 300)
        .background(Color.gray.opacity(0.1))
    }
}