import SwiftUI

struct FollowUpWindowView: View {
    @ObservedObject var viewModel: FollowUpViewModel
    let onClose: () -> Void

    var body: some View {
        GlassmorphicContainer {
            VStack(spacing: 0) {
                // Header - simplified without close button
                HStack {
                    Text("Follow-ups")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            // Content
            if viewModel.qaPairs.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No follow-up questions available")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    Text("Follow-up questions will appear here for coding, behavioral, and system design responses.")
                        .font(.caption)
                        .foregroundColor(Color.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Q&A List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.qaPairs.enumerated()), id: \.element.id) { index, qaPair in
                                QARowView(
                                    qaPair: qaPair,
                                    isSelected: index == viewModel.selectedIndex
                                )
                                .id(qaPair.id)
                                .onTapGesture {
                                    viewModel.selectedIndex = index
                                }

                                if index < viewModel.qaPairs.count - 1 {
                                    Divider()
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                    }
                    .onChange(of: viewModel.selectedIndex) { newIndex in
                        // Auto-scroll to selected item
                        if newIndex < viewModel.qaPairs.count {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(viewModel.qaPairs[newIndex].id, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            // Focus the window for keyboard navigation
            DispatchQueue.main.async {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
        }
        }
    }
}

// MARK: - Q&A Row View
struct QARowView: View {
    let qaPair: QAPair
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Question
            Text(qaPair.question)
                .font(.system(.body, design: .default).weight(.medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)

            // Answer
            Text(qaPair.answer)
                .font(.system(.callout, design: .default))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .padding(.horizontal, 8)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Preview
#if DEBUG
struct FollowUpWindowView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = FollowUpViewModel()
        viewModel.updateResponseMode(.coding)

        return FollowUpWindowView(viewModel: viewModel) {
            print("Close tapped")
        }
        .frame(width: 400, height: 600)
    }
}
#endif
