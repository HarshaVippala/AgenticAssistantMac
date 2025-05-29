import SwiftUI

struct ResponseContainer: View {
    @ObservedObject var viewModel: ResponseViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header with question
            ResponseHeader(
                question: viewModel.currentQuestion,
                mode: viewModel.responseMode,
                hasMultipleQA: viewModel.responseMode == .simple && !viewModel.qaPairs.isEmpty
            )

            // Response content based on mode
            Group {
                switch viewModel.responseMode {
                case .simple:
                    if !viewModel.qaPairs.isEmpty {
                        SimpleResponseView(qaPairs: viewModel.qaPairs)
                            .id(viewModel.responseMode)
                    } else {
                        SimpleResponseView(text: viewModel.content)
                            .id(viewModel.responseMode)
                    }
                case .coding:
                    CodingResponseView(
                        code: viewModel.code,
                        language: viewModel.language,
                        complexity: viewModel.complexity
                    )
                    .id(viewModel.responseMode)
                case .behavioral:
                    BehavioralResponseView(starResponse: viewModel.starResponse)
                        .id(viewModel.responseMode)
                case .systemDesign:
                    SystemDesignView(
                        diagram: viewModel.diagram,
                        steps: viewModel.designSteps
                    )
                    .id(viewModel.responseMode)
                }
            }
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: ContentSizePreferenceKey.self, value: geometry.size)
                }
            )
            .onPreferenceChange(ContentSizePreferenceKey.self) { newSize in
                if newSize != .zero {
                    viewModel.idealContentSize = newSize
                }
            }
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .center)),
                removal: .opacity.combined(with: .scale(scale: 1.05, anchor: .center))
            ))
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.responseMode)
            .padding(16)

            // Loading indicator overlay
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            }
        }
    }
}

struct ResponseContainer_Previews: PreviewProvider {
    static var previews: some View {
        let mockViewModel = ResponseViewModel()

        ResponseContainer(viewModel: mockViewModel)
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color.gray.opacity(0.1))

        let codingViewModel = ResponseViewModel()
        codingViewModel.responseMode = .coding

        return ResponseContainer(viewModel: codingViewModel)
            .previewDisplayName("Coding Mode")
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color.gray.opacity(0.1))
            .preferredColorScheme(.dark)
    }
}
