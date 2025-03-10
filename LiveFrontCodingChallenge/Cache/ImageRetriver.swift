//
//  ImageRetriver.swift
//  LiveFrontCodingChallenge
//
//  Created by ousmane diouf on 3/2/25.
//

import Foundation

protocol ImageRetrieverProtocol {
    func fetch(_ imageURL: String) async throws -> Data
}

struct ImageRetriver: ImageRetrieverProtocol {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetch(_ imageURL: String) async throws -> Data {
        guard let url = URL(string: imageURL) else {
            throw RetriverError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}

extension ImageRetriver: Equatable {
    enum RetriverError: Error {
        case invalidURL
    }
}
