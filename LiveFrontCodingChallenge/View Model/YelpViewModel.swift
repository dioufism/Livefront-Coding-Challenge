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
}

class YelpViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchLocation = ""
    @Published var businesses: [YelpBusiness] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let yelpService: YelpServiceProtocol
    
    init(yelpService: YelpServiceProtocol = YelpService()) {
        self.yelpService = yelpService
    }
        
    /// Searches for businesses based on the current search text and location.
    @MainActor
    func searchBusinesses(query: String? = nil) {
        // Use provided query or fall back to the stored value
        let searchTerm: String? = query ?? searchText
        
        // Check if we have a location to search with
        guard !searchLocation.isEmpty else {
            errorMessage = "Please enter a location to search"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
         Task {
             do {
                         var components = URLComponents(string: "https://api.yelp.com/v3/businesses/search")!
                         components.queryItems = [
                                    URLQueryItem(name: "location", value: searchLocation),
                                    URLQueryItem(name: "limit", value: "20")
                                ]
                         
                         if let searchTerm = searchTerm, !searchTerm.isEmpty {
                                    components.queryItems?.append(URLQueryItem(name: "term", value: searchTerm))
                                }
                         
                         var request = URLRequest(url: components.url!)
                         request.httpMethod = "GET"
                         
                         request.addValue("Bearer 0Pf310N0KSmInyvZ45jFcY8D24VrXYcsVd5_Ow3Izn8-W5-y3R6Tf6R-GQUo_BZ1K1WdZEGoh09lZGmvh3EZIqag7vDiCi-lWMpYOLIMoVg1a8t5Ni9aiUkUCJzDZ3Yx", forHTTPHeaderField: "Authorization")
                         request.addValue("application/json", forHTTPHeaderField: "accept")
                         
                         let (data, response) = try await URLSession.shared.data(for: request)
                         
                         if let httpResponse = response as? HTTPURLResponse {
                                    print("Response status code: \(httpResponse.statusCode)")
                                    
                                    if httpResponse.statusCode == 200 {
                                            let decoder = JSONDecoder()
                                            let searchResponse = try decoder.decode(YelpBusinessSearchResponse.self, from: data)
                                            self.businesses = searchResponse.businesses
                                            self.isLoading = false
                                        } else {
                                                let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                                                print("Error response: \(errorText)")
                                                self.errorMessage = "API Error: HTTP \(httpResponse.statusCode)"
                                                self.isLoading = false
                                            }
                                }
                     } catch {
                                print("Error: \(error)")
                                self.errorMessage = "Error: \(error.localizedDescription)"
                                self.isLoading = false
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
