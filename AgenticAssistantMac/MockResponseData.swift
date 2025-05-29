import Foundation

// MARK: - Data Source Protocol
protocol ResponseDataSource {
    func getQuestionAnswerPair(for mode: ResponseMode) -> QuestionAnswerPair
}

// MARK: - Question-Answer Data Structure
struct QuestionAnswerPair {
    let question: String
    let answer: ResponseAnswer
}

enum ResponseAnswer {
    case simple(content: String)
    case multipleQA(pairs: [SimpleQAPair]) // New case for multiple Q&A pairs
    case coding(code: String, language: String, complexity: String)
    case behavioral(starResponse: StarResponsePlaceholder)
    case systemDesign(diagram: DiagramPlaceholder, steps: [String])
}

// New structure for simple Q&A pairs
struct SimpleQAPair {
    let question: String
    let answer: String
}

// MARK: - Mock Data Implementation
struct MockResponseData: ResponseDataSource {

    func getQuestionAnswerPair(for mode: ResponseMode) -> QuestionAnswerPair {
        switch mode {
        case .simple:
            return QuestionAnswerPair(
                question: "", // Empty question for simple mode since we'll show Q&A pairs inline
                answer: .multipleQA(pairs: [
                    SimpleQAPair(
                        question: "What is the difference between `let` and `var` in Swift?",
                        answer: "In Swift, `let` is used to declare constants, which are values that cannot be changed once assigned. `var` is used to declare variables, which can be reassigned a new value of the same type after their initial assignment. Using `let` is preferred for values that won't change, as it improves code safety and can allow for compiler optimizations."
                    ),
                    SimpleQAPair(
                        question: "What is the difference between `struct` and `class` in Swift?",
                        answer: "In Swift, structs are value types while classes are reference types. When you assign a struct to a variable or pass it to a function, you're working with a copy. Classes are passed by reference, meaning multiple variables can point to the same instance. Structs also get automatic memberwise initializers and are generally preferred for simple data containers."
                    ),
                    SimpleQAPair(
                        question: "What is optional binding in Swift?",
                        answer: "Optional binding is a way to safely unwrap optionals in Swift using `if let` or `guard let` statements. It allows you to check if an optional contains a value and, if so, extract that value into a new constant or variable. This prevents runtime crashes that could occur from force unwrapping nil values."
                    )
                ])
            )

        case .coding:
            return QuestionAnswerPair(
                question: "How do you reverse a string in Python?",
                answer: .coding(
                    code: """
                    def reverse_string(s):
                        return s[::-1]

                    # Example usage:
                    my_string = "hello"
                    reversed_str = reverse_string(my_string)
                    print(f"Original: {my_string}, Reversed: {reversed_str}")
                    # Output: Original: hello, Reversed: olleh
                    """,
                    language: "python",
                    complexity: "Time: O(n), Space: O(n)"
                )
            )

        case .behavioral:
            return QuestionAnswerPair(
                question: "Describe a time you had to deal with a difficult stakeholder.",
                answer: .behavioral(
                    starResponse: StarResponsePlaceholder(
                        situation: "In a previous project, we had a key stakeholder who was consistently requesting features that were out of scope and threatened the project timeline. Their requests, while understandable from their perspective, were causing significant churn for the development team.",
                        task: "My responsibility was to manage stakeholder expectations while protecting the team's focus and ensuring we met our core project deliverables on schedule.",
                        action: "I scheduled a dedicated meeting with the stakeholder to understand their underlying needs. Instead of directly saying 'no,' I focused on active listening and then clearly explained the project's current priorities and the potential impact of their requests on the timeline and budget. I proposed a phased approach where some of their desired functionalities could be considered for a future iteration or as a separate enhancement project. I also made sure to provide regular, transparent updates on our progress towards the agreed-upon scope.",
                        result: "The stakeholder appreciated the direct communication and the effort to understand their needs. While not all their requests were immediately implemented, they gained a better understanding of the project constraints and agreed to prioritize. We successfully delivered the core project on time, and some of their secondary requests were incorporated into the product roadmap for a later release. This improved our working relationship and set a better precedent for future scope discussions."
                    )
                )
            )

        case .systemDesign:
            return QuestionAnswerPair(
                question: "Design a basic URL shortener service like TinyURL.",
                answer: .systemDesign(
                    diagram: DiagramPlaceholder(representation: """
                    [User] --HTTPS--> [API Gateway/Load Balancer] --HTTP--> [Web Servers (Stateless)]
                                            |                                 / | \\
                                            |                                /  |  \\
                                            +-------------------------------> [Database (e.g., NoSQL like DynamoDB/Cassandra)]
                                                                                - Stores: short_code -> long_url mapping
                                                                                - Potentially: custom_alias -> long_url
                                                                                - Analytics data (optional)

                                            [Web Servers] --(Cache Read/Write)--> [Distributed Cache (e.g., Redis/Memcached)]
                                                                                - Stores: short_code -> long_url (for fast lookups)
                    """),
                    steps: [
                        "1. Requirements Clarification: Functional (shorten URL, redirect, custom aliases, analytics) & Non-Functional (high availability, low latency, scalability, fault tolerance).",
                        "2. API Design: e.g., POST /shorten {long_url: string, custom_alias?: string} -> {short_url: string}; GET /{short_code} -> Redirect to long_url.",
                        "3. URL Shortening Strategy: Generate a unique short code (e.g., base62 encoding of a counter, or hash of long URL + salt, ensuring uniqueness). Collision resolution if hashing.",
                        "4. Data Storage: Choose a scalable database. NoSQL often preferred for simple key-value stores (short_code -> long_url). Consider sharding/partitioning for scale.",
                        "5. Redirection Logic: When GET /{short_code} is hit, lookup long_url in cache first, then DB. Perform a 301 (permanent) or 302 (temporary) redirect.",
                        "6. Scalability & Availability: Use load balancers, stateless web servers, replicate database, use a distributed cache.",
                        "7. Analytics (Optional): Track clicks per short URL, geographic data, referrers.",
                        "8. Security Considerations: Prevent abuse (rate limiting), validate URLs, consider malicious URL filtering."
                    ]
                )
            )
        }
    }
}

// MARK: - Additional Mock Data Sets
extension MockResponseData {

    // Alternative question-answer pairs for variety
    static let alternativeQuestions: [ResponseMode: [QuestionAnswerPair]] = [
        .simple: [
            QuestionAnswerPair(
                question: "What is the difference between `struct` and `class` in Swift?",
                answer: .simple(content: "In Swift, structs are value types while classes are reference types. When you assign a struct to a variable or pass it to a function, you're working with a copy. Classes are passed by reference, meaning multiple variables can point to the same instance. Structs also get automatic memberwise initializers and are generally preferred for simple data containers.")
            ),
            QuestionAnswerPair(
                question: "Explain the concept of optionals in Swift.",
                answer: .simple(content: "Optionals in Swift represent a value that might be absent. They're declared with a question mark (?) after the type. You can unwrap optionals safely using optional binding (if let), nil coalescing operator (??), or force unwrapping (!). Optionals help prevent null pointer exceptions and make code more explicit about handling missing values.")
            )
        ],
        .coding: [
            QuestionAnswerPair(
                question: "Implement a function to find the maximum element in an array.",
                answer: .coding(
                    code: """
                    def find_maximum(arr):
                        if not arr:
                            return None

                        max_val = arr[0]
                        for num in arr[1:]:
                            if num > max_val:
                                max_val = num
                        return max_val

                    # Example usage:
                    numbers = [3, 7, 2, 9, 1]
                    result = find_maximum(numbers)
                    print(f"Maximum: {result}")  # Output: Maximum: 9
                    """,
                    language: "python",
                    complexity: "Time: O(n), Space: O(1)"
                )
            )
        ]
    ]
}

// MARK: - Live Data Source Implementation
struct LiveResponseData: ResponseDataSource {
    func getQuestionAnswerPair(for mode: ResponseMode) -> QuestionAnswerPair {
        // This would be implemented to fetch real data from your backend
        // For now, return a placeholder indicating live data
        return QuestionAnswerPair(
            question: "Live data question for \(mode.displayName) mode",
            answer: .simple(content: "This would be populated with live data from your backend service.")
        )
    }
}

// MARK: - Multi-Question Data Source
class MultiQuestionDataSource: ResponseDataSource {
    private var questionHistory: [ResponseMode: [QuestionAnswerPair]] = [:]
    private var currentIndices: [ResponseMode: Int] = [:]

    init() {
        // Initialize with mock data and alternatives
        questionHistory[.simple] = [MockResponseData().getQuestionAnswerPair(for: .simple)] + (MockResponseData.alternativeQuestions[.simple] ?? [])
        questionHistory[.coding] = [MockResponseData().getQuestionAnswerPair(for: .coding)] + (MockResponseData.alternativeQuestions[.coding] ?? [])
        questionHistory[.behavioral] = [MockResponseData().getQuestionAnswerPair(for: .behavioral)]
        questionHistory[.systemDesign] = [MockResponseData().getQuestionAnswerPair(for: .systemDesign)]

        // Initialize indices
        for mode in ResponseMode.allCases {
            currentIndices[mode] = 0
        }
    }

    func getQuestionAnswerPair(for mode: ResponseMode) -> QuestionAnswerPair {
        guard let questions = questionHistory[mode],
              let currentIndex = currentIndices[mode],
              currentIndex < questions.count else {
            return MockResponseData().getQuestionAnswerPair(for: mode)
        }

        return questions[currentIndex]
    }

    func nextQuestion(for mode: ResponseMode) {
        guard let questions = questionHistory[mode],
              let currentIndex = currentIndices[mode] else { return }

        currentIndices[mode] = (currentIndex + 1) % questions.count
    }

    func addQuestion(_ questionAnswer: QuestionAnswerPair, for mode: ResponseMode) {
        if questionHistory[mode] == nil {
            questionHistory[mode] = []
        }
        questionHistory[mode]?.append(questionAnswer)
    }
}
