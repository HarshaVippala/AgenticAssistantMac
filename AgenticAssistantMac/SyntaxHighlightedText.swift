import SwiftUI
import Foundation

struct SyntaxHighlightedText: View {
    let code: String
    let language: String
    
    var body: some View {
        Text(highlightedCode)
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
    }
    
    private var highlightedCode: AttributedString {
        let highlighter = SyntaxHighlighter(language: language)
        return highlighter.highlight(code)
    }
}

struct SyntaxHighlighter {
    let language: String
    
    // Color scheme for syntax highlighting
    private let keywordColor = Color.purple
    private let stringColor = Color.red
    private let commentColor = Color.green
    private let numberColor = Color.blue
    private let functionColor = Color.cyan
    private let defaultColor = Color.primary
    
    func highlight(_ code: String) -> AttributedString {
        var attributedString = AttributedString(code)
        
        // Apply syntax highlighting based on language
        switch language.lowercased() {
        case "swift":
            highlightSwift(&attributedString)
        case "python":
            highlightPython(&attributedString)
        case "javascript", "js":
            highlightJavaScript(&attributedString)
        case "java":
            highlightJava(&attributedString)
        case "c", "c++", "cpp":
            highlightC(&attributedString)
        default:
            highlightGeneric(&attributedString)
        }
        
        return attributedString
    }
    
    private func highlightSwift(_ attributedString: inout AttributedString) {
        let keywords = ["func", "var", "let", "class", "struct", "enum", "protocol", "extension", "import", "if", "else", "for", "while", "switch", "case", "default", "return", "true", "false", "nil", "self", "super", "init", "deinit", "override", "final", "static", "private", "public", "internal", "open", "fileprivate"]
        
        highlightKeywords(keywords, in: &attributedString)
        highlightStrings(&attributedString)
        highlightComments(&attributedString, singleLine: "//", multiLineStart: "/*", multiLineEnd: "*/")
        highlightNumbers(&attributedString)
    }
    
    private func highlightPython(_ attributedString: inout AttributedString) {
        let keywords = ["def", "class", "if", "elif", "else", "for", "while", "try", "except", "finally", "with", "as", "import", "from", "return", "yield", "lambda", "and", "or", "not", "in", "is", "True", "False", "None", "pass", "break", "continue"]
        
        highlightKeywords(keywords, in: &attributedString)
        highlightStrings(&attributedString)
        highlightComments(&attributedString, singleLine: "#", multiLineStart: "\"\"\"", multiLineEnd: "\"\"\"")
        highlightNumbers(&attributedString)
    }
    
    private func highlightJavaScript(_ attributedString: inout AttributedString) {
        let keywords = ["function", "var", "let", "const", "if", "else", "for", "while", "do", "switch", "case", "default", "return", "true", "false", "null", "undefined", "this", "new", "typeof", "instanceof", "class", "extends", "import", "export", "async", "await"]
        
        highlightKeywords(keywords, in: &attributedString)
        highlightStrings(&attributedString)
        highlightComments(&attributedString, singleLine: "//", multiLineStart: "/*", multiLineEnd: "*/")
        highlightNumbers(&attributedString)
    }
    
    private func highlightJava(_ attributedString: inout AttributedString) {
        let keywords = ["public", "private", "protected", "static", "final", "abstract", "class", "interface", "extends", "implements", "import", "package", "if", "else", "for", "while", "do", "switch", "case", "default", "return", "true", "false", "null", "this", "super", "new", "instanceof", "try", "catch", "finally", "throw", "throws"]
        
        highlightKeywords(keywords, in: &attributedString)
        highlightStrings(&attributedString)
        highlightComments(&attributedString, singleLine: "//", multiLineStart: "/*", multiLineEnd: "*/")
        highlightNumbers(&attributedString)
    }
    
    private func highlightC(_ attributedString: inout AttributedString) {
        let keywords = ["int", "char", "float", "double", "void", "if", "else", "for", "while", "do", "switch", "case", "default", "return", "break", "continue", "struct", "union", "enum", "typedef", "static", "extern", "const", "volatile", "sizeof", "include", "define"]
        
        highlightKeywords(keywords, in: &attributedString)
        highlightStrings(&attributedString)
        highlightComments(&attributedString, singleLine: "//", multiLineStart: "/*", multiLineEnd: "*/")
        highlightNumbers(&attributedString)
    }
    
    private func highlightGeneric(_ attributedString: inout AttributedString) {
        // Basic highlighting for unknown languages
        highlightStrings(&attributedString)
        highlightComments(&attributedString, singleLine: "//", multiLineStart: "/*", multiLineEnd: "*/")
        highlightNumbers(&attributedString)
    }
    
    private func highlightKeywords(_ keywords: [String], in attributedString: inout AttributedString) {
        let text = String(attributedString.characters)
        
        for keyword in keywords {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: keyword))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
                
                for match in matches.reversed() {
                    if let range = Range(match.range, in: text) {
                        let attributedRange = AttributedString.Index(range.lowerBound, within: attributedString)!..<AttributedString.Index(range.upperBound, within: attributedString)!
                        attributedString[attributedRange].foregroundColor = keywordColor
                        attributedString[attributedRange].font = .system(.body, design: .monospaced).weight(.semibold)
                    }
                }
            }
        }
    }
    
    private func highlightStrings(_ attributedString: inout AttributedString) {
        let text = String(attributedString.characters)
        
        // Match strings in double quotes
        let doubleQuotePattern = "\"[^\"\\n]*\""
        if let regex = try? NSRegularExpression(pattern: doubleQuotePattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            
            for match in matches.reversed() {
                if let range = Range(match.range, in: text) {
                    let attributedRange = AttributedString.Index(range.lowerBound, within: attributedString)!..<AttributedString.Index(range.upperBound, within: attributedString)!
                    attributedString[attributedRange].foregroundColor = stringColor
                }
            }
        }
        
        // Match strings in single quotes
        let singleQuotePattern = "'[^'\\n]*'"
        if let regex = try? NSRegularExpression(pattern: singleQuotePattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            
            for match in matches.reversed() {
                if let range = Range(match.range, in: text) {
                    let attributedRange = AttributedString.Index(range.lowerBound, within: attributedString)!..<AttributedString.Index(range.upperBound, within: attributedString)!
                    attributedString[attributedRange].foregroundColor = stringColor
                }
            }
        }
    }
    
    private func highlightComments(_ attributedString: inout AttributedString, singleLine: String, multiLineStart: String? = nil, multiLineEnd: String? = nil) {
        let text = String(attributedString.characters)
        
        // Single line comments
        let singleLinePattern = "\(NSRegularExpression.escapedPattern(for: singleLine)).*$"
        if let regex = try? NSRegularExpression(pattern: singleLinePattern, options: [.anchorsMatchLines]) {
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            
            for match in matches.reversed() {
                if let range = Range(match.range, in: text) {
                    let attributedRange = AttributedString.Index(range.lowerBound, within: attributedString)!..<AttributedString.Index(range.upperBound, within: attributedString)!
                    attributedString[attributedRange].foregroundColor = commentColor
                    attributedString[attributedRange].font = .system(.body, design: .monospaced).italic()
                }
            }
        }
        
        // Multi-line comments
        if let start = multiLineStart, let end = multiLineEnd {
            let multiLinePattern = "\(NSRegularExpression.escapedPattern(for: start)).*?\(NSRegularExpression.escapedPattern(for: end))"
            if let regex = try? NSRegularExpression(pattern: multiLinePattern, options: [.dotMatchesLineSeparators]) {
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
                
                for match in matches.reversed() {
                    if let range = Range(match.range, in: text) {
                        let attributedRange = AttributedString.Index(range.lowerBound, within: attributedString)!..<AttributedString.Index(range.upperBound, within: attributedString)!
                        attributedString[attributedRange].foregroundColor = commentColor
                        attributedString[attributedRange].font = .system(.body, design: .monospaced).italic()
                    }
                }
            }
        }
    }
    
    private func highlightNumbers(_ attributedString: inout AttributedString) {
        let text = String(attributedString.characters)
        
        // Match numbers (integers and floats)
        let numberPattern = "\\b\\d+(\\.\\d+)?\\b"
        if let regex = try? NSRegularExpression(pattern: numberPattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            
            for match in matches.reversed() {
                if let range = Range(match.range, in: text) {
                    let attributedRange = AttributedString.Index(range.lowerBound, within: attributedString)!..<AttributedString.Index(range.upperBound, within: attributedString)!
                    attributedString[attributedRange].foregroundColor = numberColor
                }
            }
        }
    }
}
