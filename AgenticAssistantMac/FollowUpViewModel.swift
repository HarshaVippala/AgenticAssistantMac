import SwiftUI
import Combine

// MARK: - Q&A Pair Structure
struct QAPair: Identifiable, Equatable {
    let id = UUID()
    let question: String
    let answer: String
}

// MARK: - Follow-Up View Model
class FollowUpViewModel: ObservableObject {
    @Published var qaPairs: [QAPair] = []
    @Published var selectedIndex: Int = 0
    @Published var currentResponseMode: ResponseMode = .simple
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Initialize with empty data
        updateQAPairs(for: .simple)
    }
    
    // MARK: - Public Methods
    
    func updateResponseMode(_ mode: ResponseMode) {
        currentResponseMode = mode
        updateQAPairs(for: mode)
        selectedIndex = 0 // Reset selection when mode changes
    }
    
    func moveSelectionUp() {
        if selectedIndex > 0 {
            selectedIndex -= 1
        }
    }
    
    func moveSelectionDown() {
        if selectedIndex < qaPairs.count - 1 {
            selectedIndex += 1
        }
    }
    
    func moveToFirst() {
        selectedIndex = 0
    }
    
    func moveToLast() {
        selectedIndex = max(0, qaPairs.count - 1)
    }
    
    // MARK: - Private Methods
    
    private func updateQAPairs(for mode: ResponseMode) {
        switch mode {
        case .simple:
            // Simple mode doesn't show follow-up window as per requirements
            qaPairs = []
            
        case .coding:
            qaPairs = [
                QAPair(
                    question: "How can I optimize this code for better performance?",
                    answer: "Consider using more efficient algorithms, reducing time complexity, caching results, and minimizing memory allocations. Profile your code to identify bottlenecks."
                ),
                QAPair(
                    question: "What are the potential security vulnerabilities in this code?",
                    answer: "Look for input validation issues, SQL injection risks, XSS vulnerabilities, buffer overflows, and ensure proper authentication and authorization."
                ),
                QAPair(
                    question: "How would you refactor this code to make it more maintainable?",
                    answer: "Apply SOLID principles, extract methods, use design patterns appropriately, improve naming conventions, and add comprehensive documentation."
                ),
                QAPair(
                    question: "What testing strategies would you recommend for this code?",
                    answer: "Implement unit tests, integration tests, and end-to-end tests. Use test-driven development, mock dependencies, and aim for high code coverage."
                )
            ]
            
        case .behavioral:
            qaPairs = [
                QAPair(
                    question: "Can you provide another example using the STAR method?",
                    answer: "Situation: Working on a tight deadline project. Task: Deliver feature on time. Action: Prioritized tasks, communicated with stakeholders, worked extra hours. Result: Delivered on time with high quality."
                ),
                QAPair(
                    question: "How do you handle conflict in a team setting?",
                    answer: "I listen to all perspectives, find common ground, focus on the problem not the person, and work collaboratively toward a solution that benefits the team and project goals."
                ),
                QAPair(
                    question: "Describe a time when you had to learn a new technology quickly.",
                    answer: "I break down the learning into manageable chunks, use official documentation, practice with small projects, seek mentorship, and apply the knowledge immediately to reinforce learning."
                ),
                QAPair(
                    question: "How do you prioritize tasks when everything seems urgent?",
                    answer: "I assess impact vs effort, communicate with stakeholders about trade-offs, focus on business-critical items first, and regularly reassess priorities as situations change."
                )
            ]
            
        case .systemDesign:
            qaPairs = [
                QAPair(
                    question: "How would you handle scaling this system to millions of users?",
                    answer: "Implement horizontal scaling, use load balancers, add caching layers, consider database sharding, use CDNs, and implement microservices architecture for better scalability."
                ),
                QAPair(
                    question: "What are the trade-offs of this design approach?",
                    answer: "Consider consistency vs availability, cost vs performance, complexity vs maintainability, and latency vs throughput. Each choice has implications for the overall system."
                ),
                QAPair(
                    question: "How would you ensure high availability for this system?",
                    answer: "Use redundancy, implement failover mechanisms, design for graceful degradation, use health checks, and deploy across multiple availability zones."
                ),
                QAPair(
                    question: "What monitoring and observability would you add?",
                    answer: "Implement logging, metrics collection, distributed tracing, alerting systems, and dashboards to monitor system health, performance, and user experience."
                )
            ]
        }
    }
}
