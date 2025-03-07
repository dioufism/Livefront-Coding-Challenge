//
//  LoadingState.swift
//  LiveFrontCodingChallenge
//
//  Created by ousmane diouf on 3/6/25.
//


enum LoadingState {
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
