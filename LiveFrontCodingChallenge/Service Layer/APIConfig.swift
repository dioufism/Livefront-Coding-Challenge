//
//  APIConfig.swift
//  LiveFrontCodingChallenge
//
//  Created by ousmane diouf on 3/1/25.
//

import Foundation

struct APIConfig {
    
    // Initialize API key in keychain on first launch
    static func setupAPIKey() {
        do {
            try KeychainManager.shared.saveAPIKey(Secrets.KeyChain.APIKey)
        } catch {
            print("Failed to save API key to keychain: \(error)")
        }
    }
    
    static func getAPIKey() throws -> String {
        return try KeychainManager.shared.retrieveAPIKey()
    }
    
    enum Endpoint {
        case businessSearch(location: String?, term: String?, categories: String?, limit: Int, sortBy: SortOption)
        
        var path: String {
            switch self {
            case .businessSearch:
                return "businesses/search"
            }
        }
        
        func url(baseURL: String = Secrets.baseURL) throws -> URL? {
            let urlString =  baseURL + path
            var components = URLComponents(string: urlString)
            components?.queryItems = try queryItems
            print("this is my url\(urlString)")
            return components?.url
        }
        
        var queryItems: [URLQueryItem] {
            get throws {
                switch self {
                case .businessSearch(let location, let term, let categories, let limit, let sortBy):
                    var items: [URLQueryItem] = [
                    URLQueryItem(name: "location", value: location),
                    URLQueryItem(name: "limit", value: String(limit)),
                    URLQueryItem(name: "sort_by", value: sortBy.rawValue)
                    ]
                    
                    if let term = term {
                        items.append(URLQueryItem(name: "term", value: term))
                    }
                    
                    if let categories = categories {
                        items.append(URLQueryItem(name: "categories", value: categories))
                    }
                    return items
                }
            }
        }
    }
}
