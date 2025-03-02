//
//  YelpViewModel.swift
//  LiveFrontCodingChallenge
//
//  Created by ousmane diouf on 3/1/25.
//
import SwiftUI

enum LoadingState {
    case Idle
    case loading
    case loaded
    case error(String)
    
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case .error(let message) = self {
            return message
        }
        return nil
    }
}

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

class YelpViewModel: ObservableObject {
    @Published var searchText: String  = ""
    @Published var searchLocation: String = ""
    @Published var businesses: [YelpBusiness] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let yelpService: YelpServiceProtocol
    
    init(yelpService: YelpServiceProtocol = YelpService()) {
        self.yelpService = yelpService
        APIConfig.setupAPIKey()
    }
        
    /// Searches for businesses based on the current search text and location.
    @MainActor
    func searchBusinesses(query: String? = nil) {
        // Use provided query or fall back to the stored value
        let searchTerm = query ?? searchText
        
        // Check if we have a location to search with
        guard !searchLocation.isEmpty else {
            errorMessage = "Please enter a location to search"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let results = try await yelpService.searchBusinesses(
                    for: searchLocation,
                    term: searchTerm.isEmpty ? nil : searchTerm,
                    categories: nil,
                    limit: 20,
                    sortBy: .bestMatch
                )
                
                self.businesses = results
                self.isLoading = false
                
                if results.isEmpty {
                    self.errorMessage = "No results found"
                }
            } catch {
                self.businesses = []
                self.isLoading = false
                self.errorMessage = handleError(error)
            }
        }
    }
    
    /// Converts network errors to user-friendly messages.
    private func handleError(_ error: Error) -> String {
        switch error {
        case NetworkError.authenticationError:
            return "Authentication failed. Please check your API key."
        case NetworkError.httpError(let code):
            return "Server returned error code: \(code)"
        case NetworkError.invalidURL:
            return "Invalid URL. Please check your search parameters."
        case NetworkError.decodingError:
            return "Unable to process server response."
        case NetworkError.serverError(let err):
            return "Server error: \(err.localizedDescription)"
        default:
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}
