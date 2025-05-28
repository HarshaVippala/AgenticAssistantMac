import SwiftUI

    struct ResponseContainer: View {
        @StateObject var viewModel: ResponseViewModel
        @Environment(\.dismiss) private var dismiss
        
        var body: some View {
            VStack(spacing: 0) {
                // Header with question and close button
                ResponseHeader(
                    question: viewModel.currentQuestion,
                    mode: viewModel.responseMode,
                    onClose: {
                        // This should call the AppDelegate's hideOverlay method
                        if let appDelegate = NSApp.delegate as? AgenticAssistantMac.AppDelegate {
                            appDelegate.hideOverlay()
                        }
                    }
                )
                
                @ViewBuilder
                func responseView() -> some View {
                    switch viewModel.responseMode {
                    case .simple:
                        SimpleResponseView(text: viewModel.content)
                            .id(viewModel.responseMode)
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
                responseView
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
