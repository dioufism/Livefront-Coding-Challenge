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
    func searchBusinesses(for location: String, term: String?, categories: String?, limit: Int, offset: Int, sortBy: SortOption) async throws -> YelpBusinessSearchResponse
}

final class YelpService: YelpServiceProtocol {

    /// Injected to allow for custom configuration and testing.
     let session: URLSession
    
    /// Injected to allow for custom decoding strategies.
     let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = .init()) {
        self.session = session
        self.decoder = decoder
    }
    
    func searchBusinesses(for location: String, term: String?, categories: String?, limit: Int, offset: Int, sortBy: SortOption) async throws -> YelpBusinessSearchResponse {

        let endpoint = APIConfig.Endpoint.businessSearch(
            location: location,
            term: term,
            categories: categories,
            limit: limit,
            sortBy: sortBy
        )
        
        guard var urlComponents = URLComponents(string: Secrets.baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        
        var queryItems = try endpoint.queryItems
        queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }
        
        let response: YelpBusinessSearchResponse = try await performRequest(for: url)
        return response
    }
    
    /// generic helper method to perform request
    private func performRequest<T: Decodable>(for url: URL) async throws -> T {
        var request = URLRequest(url: url)
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
            
            if !(200...299).contains(httpResponse.statusCode) {
                do {
                    let yelpError = try decoder.decode(YelpAPIError.self, from: data)
                    let errorDetail = NSError(
                        domain: "YelpAPI",
                        code: httpResponse.statusCode,
                        userInfo: [
                            "errorCode": yelpError.error.code,
                            "errorDescription": yelpError.error.description,
                            "statusCode": httpResponse.statusCode
                        ]
                    )
                    throw NetworkError.serverError(errorDetail)
                } catch {
                    if error is DecodingError {
                        throw NetworkError.httpError(httpResponse.statusCode)
                    } else {
                        throw error
                    }
                }
            }
            
            return try decoder.decode(T.self, from: data)
            
        } catch let error as DecodingError {
            throw NetworkError.decodingError(error)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.serverError(error)
        }
    }}
// MARK: Error handling
extension YelpService {
    func handleResponseError(data: Data, response: HTTPURLResponse, decoder: JSONDecoder) throws {
        // If status code is not in the success range (200-299)
        guard (200...299).contains(response.statusCode) else {
            // Special handling for 401 Unauthorized errors
            if response.statusCode == 401 {
                // Try to decode as YelpAPIError for more details, but always throw authenticationError
                do {
                    let yelpError = try decoder.decode(YelpAPIError.self, from: data)
                    // log
                    print("401 Unauthorized: \(yelpError.error.code) - \(yelpError.error.description)")
                } catch {
                    //log
                    print("401 Unauthorized with non-parsable response")
                }
                throw NetworkError.authenticationError
            }
            
            // For other error status codes
            do {
                let yelpError = try decoder.decode(YelpAPIError.self, from: data)
                let errorDetail = NSError(
                    domain: "YelpAPI",
                    code: response.statusCode,
                    userInfo: [
                        "errorCode": yelpError.error.code,
                        "errorDescription": yelpError.error.description,
                        "statusCode": response.statusCode
                    ]
                )
                // Use the existing serverError case
                throw NetworkError.serverError(errorDetail)
            } catch {
                if error is DecodingError {
                    throw NetworkError.httpError(response.statusCode)
                } else {
                    throw error
                }
            }
        }
    }
}
