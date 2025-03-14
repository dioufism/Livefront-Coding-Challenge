//
//  MockYelpService.swift
//  LiveFrontCodingChallengeTests
//
//  Created by ousmane diouf on 3/5/25.
//

import Foundation
import XCTest
@testable import LiveFrontCodingChallenge


class MockURLProtocol: URLProtocol {
    static var mockData: Data?
    static var mockResponse: URLResponse?
    static var mockError: Error?
    
    static var lastRequest: URLRequest?
    
    // Reset between tests
    static func reset() {
        mockData = nil
        mockResponse = nil
        mockError = nil
        lastRequest = nil
    }
    
    // Required URLProtocol methods
    override class func canInit(with request: URLRequest) -> Bool {
        lastRequest = request
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let error = MockURLProtocol.mockError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        
        if let response = MockURLProtocol.mockResponse {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        
        if let data = MockURLProtocol.mockData {
            client?.urlProtocol(self, didLoad: data)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() { }
}
