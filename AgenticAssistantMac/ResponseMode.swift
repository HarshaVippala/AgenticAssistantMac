import Foundation

enum ResponseMode: CaseIterable, Identifiable {
    case simple
    case coding
    case behavioral
    case systemDesign
    
    var id: Self { self }
    
    var displayName: String {
        switch self {
        case .simple: return "Simple"
        case .coding: return "Coding"
        case .behavioral: return "Behavioral"
        case .systemDesign: return "System Design"
        }
    }
}