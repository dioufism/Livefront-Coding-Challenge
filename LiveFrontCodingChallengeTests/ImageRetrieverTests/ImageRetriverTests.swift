//
//  ImageRetriverTests.swift
//  LiveFrontCodingChallenge
//
//  Created by ousmane diouf on 3/8/25.
//

import XCTest
@testable import LiveFrontCodingChallenge

final class ImageRetriverTests: XCTestCase {
    // Use MockURLProtocol approach from our YelpService tests
    var mockSession: URLSession!
    var imageRetriver: ImageRetriver!
    
    override func setUpWithError() throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)
        
        // Need to modify ImageRetriver to accept a URLSession
        imageRetriver = ImageRetriver(session: mockSession)
    }
    
    func test_fetch_withValidURL_returnsImageData() async throws {
        // Arrange
        let mockImageData = UIImage(systemName: "star")!.pngData()!
        MockURLProtocol.mockData = mockImageData
        MockURLProtocol.mockResponse = HTTPURLResponse(url: URL(string: "https://yelp-photos.yelpcorp.com/bphoto/b0mx7p6x9Z1ivb8yzaU3dg/o.jpg")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Act
        let result = try await imageRetriver.fetch("https://yelp-photos.yelpcorp.com/bphoto/b0mx7p6x9Z1ivb8yzaU3dg/o.jpg")
        
        // Assert
        XCTAssertEqual(result, mockImageData)
    }
    
    func test_fetch_withInvalidURL_throwsError() async {
        // Act & Assert
        do {
            _ = try await imageRetriver.fetch("invalid-url")
            XCTFail("Expected error not thrown")
        } catch let error as ImageRetriver.RetriverError {
            XCTAssertEqual(error, .invalidURL)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func test_fetch_withNetworkError_throwsError() async {
        // Arrange
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        MockURLProtocol.mockError = networkError
        
        // Act & Assert
        do {
            _ = try await imageRetriver.fetch("https://yelp-photos.yelpcorp.com/bphoto/b0mx7p6x9Z1ivb8yzaU3dg/o.jpg")
            XCTFail("Expected error not thrown")
        } catch {
            // Successfully threw an error
        }
    }
}
