import SwiftUI

struct ResponseContainer: View {
    @StateObject var viewModel: ResponseViewModel // ViewModel will be injected
    
    var body: some View {
        // The VStack is removed to allow the Group to be the top-level content,
        // which will then be directly placed inside the GlassmorphicContainer.
        // The GlassmorphicContainer already provides padding.
        // Spacing and alignment will be handled by the individual ResponseViews.
            Group {
                switch viewModel.responseMode {
                case .simple:
                    SimpleResponseView(text: viewModel.content)
                        .id(viewModel.responseMode) // Ensure view updates on mode change
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
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .center)),
                removal: .opacity.combined(with: .scale(scale: 1.05, anchor: .center))
            ))
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.responseMode)
        // The .frame modifier is removed from here.
        // The size of the ResponseContainer will be determined by its content
        // and the constraints imposed by GlassmorphicContainer and InvisibleOverlayWindow.
        // The InvisibleOverlayWindow's initial size is set in AppDelegate.
        // Individual ResponseViews can define their own sizing needs.
    }
}

struct ResponseContainer_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock ViewModel for previewing
        let mockViewModel = ResponseViewModel()
        
        ResponseContainer(viewModel: mockViewModel)
            .previewLayout(.sizeThatFits)
            .padding()

        // Preview in a specific mode
        let codingViewModel = ResponseViewModel()
        // Set the mode on the viewModel *before* creating the view for the preview
        codingViewModel.responseMode = .coding
        // You might also want to call cycleResponseMode or manually set other properties
        // on codingViewModel here if the .coding case expects specific data to be present
        // for a meaningful preview. For example:
        // codingViewModel.code = "func example() -> String { return \"Preview Code\" }"
        // codingViewModel.language = "swift"
        // codingViewModel.complexity = "O(1)"

        return ResponseContainer(viewModel: codingViewModel)
            .previewDisplayName("Coding Mode")
            .previewLayout(.sizeThatFits)
            .padding()
            .preferredColorScheme(.dark)
    }
}