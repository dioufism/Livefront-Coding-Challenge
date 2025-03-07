enum SortOption: String, CaseIterable, Identifiable {
    case bestMatch = "best_match"
    case rating = "rating"
    case reviewCount = "review_count"
    case distance = "distance"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .bestMatch: return "Best Match"
        case .rating: return "Highest Rated"
        case .reviewCount: return "Most Reviewed"
        case .distance: return "Distance"
        }
    }
    
    var apiValue: String {
        return self.rawValue
    }
    
    static var `default`: SortOption {
        return .bestMatch
    }
}
