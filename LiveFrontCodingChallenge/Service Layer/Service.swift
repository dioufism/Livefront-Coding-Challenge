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
    func searchBusinesses(for location: String, term: String?, categories: String?, limit: Int, sortBy: SortOption) async throws -> [YelpBusiness]
}

final class YelpService: YelpServiceProtocol {

    /// Injected to allow for custom configuration and testing.
    private let session: URLSession
    
    /// Injected to allow for custom decoding strategies.
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = .init()) {
        self.session = session
        self.decoder = decoder
    }
    
    func searchBusinesses(for location: String,
                          term: String?,
                          categories: String?,
                          limit: Int = 20,
                          sortBy: SortOption = .bestMatch) async throws -> [YelpBusiness] {
        guard let url = try APIConfig.Endpoint.businessSearch(location: location,
                                                              term: term,
                                                              categories: categories,
                                                              limit: limit,
                                                              sortBy: sortBy).url() else {
            throw NetworkError.invalidURL
        }
        
        let response: YelpBusinessSearchResponse = try await performRequest(for: url)
        return response.businesses
    }
    
    /// generic helper method to perform request
    private func performRequest<T: Decodable>(for url: URL) async throws -> T {
        var request =  URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            let apiKey =  try APIConfig.getAPIKey()
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        } catch {
            throw NetworkError.authenticationError
        }
        
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse =  response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.httpError(httpResponse.statusCode)
            }
            
            return try decoder.decode(T.self, from: data)
            
        } catch let error as DecodingError {
            throw NetworkError.decodingError(error)
        } catch {
            throw NetworkError.serverError(error)
        }
    }
}
