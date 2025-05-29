import SwiftUI
import Combine
import Foundation

class ResponseViewModel: ObservableObject {
    // Response properties
    @Published var responseMode: ResponseMode = .simple
    @Published var content: String = "This is a simple response."
    @Published var qaPairs: [SimpleQAPair] = [] // For multiple Q&A pairs

    // Coding response properties
    @Published var code: String = "print('Hello, World!')"
    @Published var language: String = "python"
    @Published var complexity: String = "O(1)"

    // Behavioral response properties
    @Published var starResponse: StarResponsePlaceholder = StarResponsePlaceholder()

    // System design properties
    @Published var diagram: DiagramPlaceholder = DiagramPlaceholder()
    @Published var designSteps: [String] = ["Step 1: Define Requirements", "Step 2: High-level design"]

    // UI state
    @Published var currentQuestion: String = "What is the meaning of life?"
    @Published var isLoading: Bool = false

    // Dynamic sizing
    @Published var idealContentSize: CGSize? = nil

    // Data source for dependency injection
    private let dataSource: ResponseDataSource

    // Configuration
    var webSocketURL: URL {
        // Make it configurable via UserDefaults or environment
        let urlString = UserDefaults.standard.string(forKey: "WebSocketURL") ?? "ws://localhost:8080/ws"
        return URL(string: urlString)!
    }

    init(dataSource: ResponseDataSource = MockResponseData()) {
        self.dataSource = dataSource
        Task { @MainActor in
            setInitialMockData()
        }
    }

    @MainActor
    func setInitialMockData(mode: ResponseMode = .behavioral) {
        self.responseMode = mode
        updateContentForCurrentMode()
    }

    @MainActor
    func cycleResponseMode() {
        let allModes = ResponseMode.allCases
        if let currentIndex = allModes.firstIndex(of: responseMode), currentIndex + 1 < allModes.count {
            responseMode = allModes[currentIndex + 1]
        } else {
            responseMode = allModes.first ?? .simple
        }
        updateContentForCurrentMode()
    }

    @MainActor
    func updateContentForCurrentMode() {
        // Get question-answer pair from data source
        let questionAnswerPair = dataSource.getQuestionAnswerPair(for: responseMode)

        // Update the current question
        currentQuestion = questionAnswerPair.question

        // Update content based on answer type
        switch questionAnswerPair.answer {
        case .simple(let content):
            self.content = content

        case .multipleQA(let pairs):
            self.qaPairs = pairs

        case .coding(let code, let language, let complexity):
            self.code = code
            self.language = language
            self.complexity = complexity

        case .behavioral(let starResponse):
            self.starResponse = starResponse

        case .systemDesign(let diagram, let steps):
            self.diagram = diagram
            self.designSteps = steps
        }
    }

    // MARK: - Additional Methods for Dynamic Data Updates

    @MainActor
    func updateWithLiveData(question: String, answer: ResponseAnswer) {
        currentQuestion = question

        switch answer {
        case .simple(let content):
            responseMode = .simple
            self.content = content

        case .multipleQA(let pairs):
            responseMode = .simple
            self.qaPairs = pairs

        case .coding(let code, let language, let complexity):
            responseMode = .coding
            self.code = code
            self.language = language
            self.complexity = complexity

        case .behavioral(let starResponse):
            responseMode = .behavioral
            self.starResponse = starResponse

        case .systemDesign(let diagram, let steps):
            responseMode = .systemDesign
            self.diagram = diagram
            self.designSteps = steps
        }
    }

    // MARK: - Data Source Management

    @MainActor
    func switchToLiveDataSource() {
        // Example of how to switch to live data
        // In a real implementation, you would recreate the ViewModel with a different data source
        // For demonstration, we'll just update the content to show the concept
        let liveData = LiveResponseData()
        let questionAnswer = liveData.getQuestionAnswerPair(for: responseMode)
        currentQuestion = questionAnswer.question

        switch questionAnswer.answer {
        case .simple(let content):
            self.content = content
        default:
            self.content = "Live data would be loaded here for \(responseMode.displayName) mode"
        }
    }

    @MainActor
    func nextQuestionInSeries() {
        // If using MultiQuestionDataSource, this would cycle to the next question
        // For now, we'll simulate by cycling through response modes
        cycleResponseMode()
    }
}
