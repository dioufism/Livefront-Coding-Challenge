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

@Observable
class YelpViewModel {
    var searchText: String  = ""
    var searchLocation: String = ""
    var businesses: [YelpBusiness] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var isLoadingMore: Bool = false
    var hasMoreResults: Bool = true
    
    private var currentPage: Int = 0
    private var totalResults: Int = 0
    private let pageSize: Int = 20
    
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
        
        currentPage = 0
        hasMoreResults = true
        totalResults = 0
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await yelpService.searchBusinesses(
                    for: searchLocation,
                    term: searchTerm.isEmpty ? nil : searchTerm,
                    categories: nil,
                    limit: pageSize,
                    offset: 0,
                    sortBy: .bestMatch)
                
                self.businesses = result.businesses
                self.totalResults = result.total
                self.currentPage = 1
                self.hasMoreResults = result.businesses.count < result.total
                self.isLoading = false
                
                if result.businesses.isEmpty {
                    self.errorMessage = "No results found"
                }
            } catch {
                self.businesses = []
                self.isLoading = false
                self.errorMessage = handleError(error)
                self.hasMoreResults = false
            }
        }
    }

    @MainActor
    func loadMoreBusinessesIfNeeded(currentItem: YelpBusiness?) {
        guard !isLoadingMore && hasMoreResults else {
            return
        }
        
        guard let currentItem = currentItem else {
            return
        }
        
        guard let index = businesses.firstIndex(where: { $0.id == currentItem.id }) else {
            return
        }
        
        let thresholdIndex = businesses.count - 3
        if index >= thresholdIndex {
            loadMoreBusinesses()
        }
    }

    private func loadMoreBusinesses() {
        isLoadingMore = true
        let offset = currentPage * pageSize
        Task {
            do {
                let result = try await yelpService.searchBusinesses(
                    for: searchLocation,
                    term: searchText.isEmpty ? nil : searchText,
                    categories: nil,
                    limit: pageSize,
                    offset: offset,
                    sortBy: .bestMatch)
                
                await MainActor.run {
                    self.businesses.append(contentsOf: result.businesses)
                    self.currentPage += 1
                    self.hasMoreResults = self.businesses.count < self.totalResults
                    self.isLoadingMore = false
                }
            }
            catch {
                await MainActor.run {
                    self.isLoadingMore = false
                    ///log error
                    print("Error loading more results: \(error.localizedDescription)")
                }
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
