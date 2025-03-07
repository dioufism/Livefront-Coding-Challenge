//
//  YelpViewModel.swift
//  LiveFrontCodingChallenge
//
//  Created by ousmane diouf on 3/1/25.
//

import SwiftUI

@Observable
final class YelpViewModel {
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
}

extension YelpViewModel {
    func handleError(_ error: Error) -> String {
        let nsError = error as NSError
        
        // First try to handle HTTP-specific error codes
        if let httpError = error as? NetworkError, case .httpError(let statusCode) = httpError {
            return handleHTTPStatusCode(statusCode)
        }
        
        // Next check if it's a server error with an HTTP status code in userInfo
        if let networkError = error as? NetworkError,
           case let .serverError(underlyingError) = networkError {
            // Try to get status code from underlying error
            let underlyingError = underlyingError as NSError
            if let statusCode = underlyingError.userInfo["statusCode"] as? Int {
                return handleHTTPStatusCode(statusCode)
            }
        }
        
        // Try to extract status code directly from NSError
        if let statusCode = nsError.userInfo["statusCode"] as? Int {
            return handleHTTPStatusCode(statusCode)
        }

        // Fall back to general error types
        switch error {
        case NetworkError.authenticationError:
            return "Authentication failed. Please check your API key."
            
        case NetworkError.invalidURL:
            return "Invalid URL. Please check your search parameters."
            
        case NetworkError.decodingError:
            return "Unable to process server response."
            
        case let NetworkError.serverError(err):
            return "Server error: \(err.localizedDescription)"
            
        default:
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
    
    // Helper to handle HTTP status codes
    private func handleHTTPStatusCode(_ statusCode: Int) -> String {
        switch statusCode {
        case 400:
            return "Invalid request."
        case 401:
            return "Authentication failed. Please check your API key."
        case 403:
            return "You don't have permission to access this resource."
        case 404:
            return "The requested information could not be found."
        case 429:
            return "Too many requests. Please try again later."
        case 500...599:
            return "The server encountered an error. Please try again later."
        default:
            return "Server returned error code: \(statusCode)"
        }
    }
}
