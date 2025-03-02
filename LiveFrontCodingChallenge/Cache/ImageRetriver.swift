//
//  ImageRetriver.swift
//  LiveFrontCodingChallenge
//
//  Created by ousmane diouf on 3/2/25.
//

import Foundation

struct ImageRetriver {
    func fetch(_ imageURL: String) async throws -> Data {
        guard let url = URL(string: imageURL) else {
            throw RetriverError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}

private extension ImageRetriver {
    enum RetriverError: Error {
        case invalidURL
    }
}
