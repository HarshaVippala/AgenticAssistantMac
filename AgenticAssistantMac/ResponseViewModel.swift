import SwiftUI
import Combine

class ResponseViewModel: ObservableObject {
    // As per agentassist-macos-spec.md section 4.3
    @Published var responseMode: ResponseMode = .simple
    @Published var content: String = "This is a simple response." // For SimpleResponseView
    
    // For CodingResponseView
    @Published var code: String = "print('Hello, World!')"
    @Published var language: String = "python"
    @Published var complexity: String = "O(1)" // Or a more structured type
    
    // For BehavioralResponseView
    @Published var starResponse: StarResponsePlaceholder = StarResponsePlaceholder()
    
    // For SystemDesignView
    @Published var diagram: DiagramPlaceholder = DiagramPlaceholder() // Could be image data, SVG string, etc.
    @Published var designSteps: [String] = ["Step 1: Define Requirements", "Step 2: High-level design"]

    // As per agentassist-macos-spec.md section 6.2 (ConversationViewModel)
    // These might be merged or kept separate depending on final architecture.
    // For now, including them here for completeness based on the spec's ResponseContainer.
    @Published var currentQuestion: String = "What is the meaning of life?"
    @Published var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()

    // Placeholder for RealtimeConnection if needed directly by this ViewModel
    // private let connection: RealtimeConnection 

    init(/* connection: RealtimeConnection */) {
        // self.connection = connection
        // Setup publishers if needed, e.g., from a RealtimeConnection
        setInitialMockData() // Load a detailed example on init
        // startCyclingModes() // Uncomment to automatically cycle for testing
    }

    func setInitialMockData(mode: ResponseMode = .behavioral) {
        self.responseMode = mode
        updateContentForCurrentMode()
    }

    // Example function to simulate mode changes for UI testing
    func cycleResponseMode() {
        let allModes = ResponseMode.allCases
        if let currentIndex = allModes.firstIndex(of: responseMode), currentIndex + 1 < allModes.count {
            responseMode = allModes[currentIndex + 1]
        } else {
            responseMode = allModes.first ?? .simple
        }
        updateContentForCurrentMode()
    }
    
    private func updateContentForCurrentMode() {
        // Update content based on new mode for demonstration
        switch responseMode {
        case .simple:
            currentQuestion = "What is the difference between `let` and `var` in Swift?"
            content = "In Swift, `let` is used to declare constants, which are values that cannot be changed once assigned. `var` is used to declare variables, which can be reassigned a new value of the same type after their initial assignment. Using `let` is preferred for values that won't change, as it improves code safety and can allow for compiler optimizations."
        case .coding:
            currentQuestion = "How do you reverse a string in Python?"
            code = """
            def reverse_string(s):
                return s[::-1]

            # Example usage:
            my_string = "hello"
            reversed_str = reverse_string(my_string)
            print(f"Original: {my_string}, Reversed: {reversed_str}")
            # Output: Original: hello, Reversed: olleh
            """
            language = "python"
            complexity = "Time: O(n), Space: O(n)"
        case .behavioral:
            currentQuestion = "Describe a time you had to deal with a difficult stakeholder."
            starResponse = StarResponsePlaceholder(
                situation: "In a previous project, we had a key stakeholder who was consistently requesting features that were out of scope and threatened the project timeline. Their requests, while understandable from their perspective, were causing significant churn for the development team.",
                task: "My responsibility was to manage stakeholder expectations while protecting the team's focus and ensuring we met our core project deliverables on schedule.",
                action: "I scheduled a dedicated meeting with the stakeholder to understand their underlying needs. Instead of directly saying 'no,' I focused on active listening and then clearly explained the project's current priorities and the potential impact of their requests on the timeline and budget. I proposed a phased approach where some of their desired functionalities could be considered for a future iteration or as a separate enhancement project. I also made sure to provide regular, transparent updates on our progress towards the agreed-upon scope.",
                result: "The stakeholder appreciated the direct communication and the effort to understand their needs. While not all their requests were immediately implemented, they gained a better understanding of the project constraints and agreed to prioritize. We successfully delivered the core project on time, and some of their secondary requests were incorporated into the product roadmap for a later release. This improved our working relationship and set a better precedent for future scope discussions."
            )
        case .systemDesign:
            currentQuestion = "Design a basic URL shortener service like TinyURL."
            diagram = DiagramPlaceholder(representation: """
            [User] --HTTPS--> [API Gateway/Load Balancer] --HTTP--> [Web Servers (Stateless)]
                                        |                                 / | \\
                                        |                                /  |  \\
                                        +-------------------------------> [Database (e.g., NoSQL like DynamoDB/Cassandra)]
                                                                            - Stores: short_code -> long_url mapping
                                                                            - Potentially: custom_alias -> long_url
                                                                            - Analytics data (optional)
                                        
                                        [Web Servers] --(Cache Read/Write)--> [Distributed Cache (e.g., Redis/Memcached)]
                                                                            - Stores: short_code -> long_url (for fast lookups)
            """)
            designSteps = [
                "1. Requirements Clarification: Functional (shorten URL, redirect, custom aliases, analytics) & Non-Functional (high availability, low latency, scalability, fault tolerance).",
                "2. API Design: e.g., POST /shorten {long_url: string, custom_alias?: string} -> {short_url: string}; GET /{short_code} -> Redirect to long_url.",
                "3. URL Shortening Strategy: Generate a unique short code (e.g., base62 encoding of a counter, or hash of long URL + salt, ensuring uniqueness). Collision resolution if hashing.",
                "4. Data Storage: Choose a scalable database. NoSQL often preferred for simple key-value stores (short_code -> long_url). Consider sharding/partitioning for scale.",
                "5. Redirection Logic: When GET /{short_code} is hit, lookup long_url in cache first, then DB. Perform a 301 (permanent) or 302 (temporary) redirect.",
                "6. Scalability & Availability: Use load balancers, stateless web servers, replicate database, use a distributed cache.",
                "7. Analytics (Optional): Track clicks per short URL, geographic data, referrers.",
                "8. Security Considerations: Prevent abuse (rate limiting), validate URLs, consider malicious URL filtering."
            ]
        }
    }
    
    private func startCyclingModes() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.cycleResponseMode()
        }
    }
}