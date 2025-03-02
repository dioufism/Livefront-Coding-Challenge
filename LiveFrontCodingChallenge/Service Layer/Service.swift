//
//  Service.swift
//  LiveFrontCodingChallenge
//
//  Created by ousmane diouf on 3/1/25.
//

import Foundation


/// Represents possible errors that can occur during network operations.
/// Used throughout the app's networking layer for consistent error handling.
enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case serverError(Error)
    case noData
    case authenticationError
}

protocol YelpServiceProtocol {
    func searchBusinesses(for location: String, term: String?, categories: String?, limit: Int, sortBy: String) async throws -> [YelpBusiness]
}

final class WeatherService: YelpServiceProtocol {
    /// Injected to allow for custom configuration and testing.
    private let session: URLSession
    
    /// Injected to allow for custom decoding strategies.
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = .init()) {
        self.session = session
        self.decoder = decoder
    }
    
    func searchBusinesses(for location: String, term: String?, categories: String?, limit: Int, sortBy: String) async throws -> [YelpBusiness] {

        return []
    }
    
    // MARK: helper methods
    
    private func performRequest<T: Decodable>(for url: URL) async throws -> T {
        return T.Type
    }
        
}
