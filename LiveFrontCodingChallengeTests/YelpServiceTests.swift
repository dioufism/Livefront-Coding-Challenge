//
//  YelpServiceTests.swift
//  YelpServiceTests
//
//  Created by ousmane diouf on 3/5/25.
//

import XCTest
@testable import LiveFrontCodingChallenge

class YelpServiceTests: XCTestCase {
    var sut: YelpService!
    var mockSession: URLSession!
        
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Reset mock state
        MockURLProtocol.reset()
        
        // Set up session with mock protocol
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)
        
        sut = YelpService(session: mockSession)
    }
    
    override func tearDownWithError() throws {
        sut = nil
        mockSession = nil
        try super.tearDownWithError()
    }
        
    func test_searchBusinesses_WithEmptyResults_ReturnsEmptyArray() async throws {
        // Given
        MockURLProtocol.mockData = createEmptyBusinessResponse()
        MockURLProtocol.mockResponse = createHTTPResponse()
        
        // When
        let result = try await sut.searchBusinesses(
            for: "San Francisco",
            term: nil,
            categories: nil,
            limit: 10,
            offset: 0,
            sortBy: .bestMatch
        )
        
        // Then
        XCTAssertEqual(result.businesses.count, 0)
        XCTAssertEqual(result.total, 0)
    }
    
    func test_searchBusinesses_WithValidResponse_ReturnsBusinessData() async throws {
        // Given
        MockURLProtocol.mockData = createDetailedBusinessResponse()
        MockURLProtocol.mockResponse = createHTTPResponse()
        
        // When
        let result = try await sut.searchBusinesses(
            for: "San Francisco",
            term: "restaurant",
            categories: "food",
            limit: 10,
            offset: 5,
            sortBy: .rating
        )
        
        // Then
        XCTAssertEqual(result.businesses.count, 1)
        XCTAssertEqual(result.businesses[0].id, "test-id-1")
        XCTAssertEqual(result.businesses[0].name, "Test Restaurant")
        XCTAssertEqual(result.businesses[0].rating, 4.5)
        XCTAssertEqual(result.businesses[0].price, "$$")
    }
    
    func test_searchBusinesses_WithHTTPError_ThrowsServerErrorWithHTTPError() async {
        //Given
        MockURLProtocol.mockData = Data()
        MockURLProtocol.mockResponse = createHTTPResponse(statusCode: 404)
        
        // when
        do {
            _ = try await sut.searchBusinesses(
                for: "San Francisco",
                term: nil,
                categories: nil,
                limit: 10,
                offset: 0,
                sortBy: .bestMatch
            )
            XCTFail("Expected error was not thrown")
        } catch let error as NetworkError {
            if case .serverError(let underlyingError) = error {
                // Check if the underlying error is a NetworkError.httpError
                if let networkError = underlyingError as? NetworkError,
                   case .httpError(let statusCode) = networkError {
                    XCTAssertEqual(statusCode, 404)
                } else {
                    XCTFail("Underlying error is not a NetworkError.httpError: \(underlyingError)")
                }
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func test_searchBusinesses_WithInvalidJSON_ThrowsDecodingError() async {
        // Given
        MockURLProtocol.mockData = "{ invalid json }".data(using: .utf8)
        MockURLProtocol.mockResponse = createHTTPResponse()
        
        // When
        do {
            _ = try await sut.searchBusinesses(
                for: "San Francisco",
                term: nil,
                categories: nil,
                limit: 10,
                offset: 0,
                sortBy: .bestMatch
            )
            XCTFail("Expected error was not thrown")
        } catch let error as NetworkError {
            if case .decodingError(let underlyingError) = error {
                XCTAssertNotNil(underlyingError, "Underlying error should not be nil")
                XCTAssertTrue(underlyingError is DecodingError, "Underlying error should be a DecodingError")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func test_searchBusinesses_WithNetworkError_ThrowsServerError() async {
        // Given
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        MockURLProtocol.mockError = networkError
        
        // Act & Assert
        do {
            _ = try await sut.searchBusinesses(
                for: "San Francisco",
                term: nil,
                categories: nil,
                limit: 10,
                offset: 0,
                sortBy: .bestMatch
            )
            XCTFail("Expected error was not thrown")
        } catch let error as NetworkError {
            if case .serverError = error {
                /// Success - correct error caught
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func test_searchBusinesses_FormatsURLParametersCorrectly() async throws {
        // Given
        MockURLProtocol.mockData = createEmptyBusinessResponse()
        MockURLProtocol.mockResponse = createHTTPResponse()
        
        // When
        _ = try await sut.searchBusinesses(
            for: "San Francisco",
            term: "coffee",
            categories: "food,restaurants",
            limit: 20,
            offset: 5,
            sortBy: .rating
        )
        
        // Then
        XCTAssertNotNil(MockURLProtocol.lastRequest)
        guard let url = MockURLProtocol.lastRequest?.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            XCTFail("Invalid URL in request")
            return
        }
        
        let queryItems = components.queryItems ?? []
        XCTAssertTrue(queryItems.contains(where: { $0.name == "location" && $0.value == "San Francisco" }))
        XCTAssertTrue(queryItems.contains(where: { $0.name == "term" && $0.value == "coffee" }))
        XCTAssertTrue(queryItems.contains(where: { $0.name == "categories" && $0.value == "food,restaurants" }))
        XCTAssertTrue(queryItems.contains(where: { $0.name == "limit" && $0.value == "20" }))
        XCTAssertTrue(queryItems.contains(where: { $0.name == "offset" && $0.value == "5" }))
        XCTAssertTrue(queryItems.contains(where: { $0.name == "sort_by" && $0.value == "rating" }))
    }
    
    func test_searchBusinesses_HandlesSpecialCharactersInParameters() async throws {
        // Given
        MockURLProtocol.mockData = createEmptyBusinessResponse()
        MockURLProtocol.mockResponse = createHTTPResponse()
        
        // When
        _ = try await sut.searchBusinesses(
            for: "San Francisco & Bay Area", // Contains special characters
            term: "café & bar",              // More special characters
            categories: nil,
            limit: 10,
            offset: 0,
            sortBy: .bestMatch
        )
        
        // Then
        XCTAssertNotNil(MockURLProtocol.lastRequest)
        guard let url = MockURLProtocol.lastRequest?.url?.absoluteString else {
            XCTFail("No URL in request")
            return
        }
        
        /// Checks that the URL is properly encoded
        XCTAssertTrue(url.contains("San%20Francisco%20%26%20Bay%20Area"))
        XCTAssertTrue(url.contains("caf%C3%A9%20%26%20bar"))
    }
    
    func test_searchBusinesses_SetsCorrectAuthorizationHeader() async throws {
        // Given
        MockURLProtocol.mockData = createEmptyBusinessResponse()
        MockURLProtocol.mockResponse = createHTTPResponse()
        
        // When
        _ = try await sut.searchBusinesses(
            for: "San Francisco",
            term: nil,
            categories: nil,
            limit: 10,
            offset: 0,
            sortBy: .bestMatch
        )
        
        // Then
        XCTAssertNotNil(MockURLProtocol.lastRequest)
        let authHeader = MockURLProtocol.lastRequest?.value(forHTTPHeaderField: "Authorization")
        XCTAssertNotNil(authHeader)
        XCTAssertTrue(authHeader?.hasPrefix("Bearer ") ?? false)
    }
}

// MARK: - Helper Methods
extension YelpServiceTests {
    func createHTTPResponse(statusCode: Int = 200) -> HTTPURLResponse {
        return HTTPURLResponse(
            url: URL(string: "https://api.yelp.com/v3/businesses/search")!,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
    }
    
    func createEmptyBusinessResponse() -> Data {
        let jsonString = """
        {
          "businesses": [],
          "total": 0,
          "region": {
            "center": {
              "latitude": 37.7749,
              "longitude": -122.4194
            }
          }
        }
        """
        return jsonString.data(using: .utf8)!
    }
    
    func createDetailedBusinessResponse() -> Data {
        let jsonString = """
        {
          "businesses": [
            {
              "id": "test-id-1",
              "name": "Test Restaurant",
              "image_url": "https://example.com/image.jpg",
              "is_closed": false,
              "url": "https://example.com/business",
              "review_count": 100,
              "categories": [
                {
                  "alias": "restaurant",
                  "title": "Restaurant"
                }
              ],
              "rating": 4.5,
              "coordinates": {
                "latitude": 37.7749,
                "longitude": -122.4194
              },
              "transactions": ["delivery", "pickup"],
              "price": "$$",
              "location": {
                "address1": "123 Test St",
                "address2": null,
                "address3": null,
                "city": "San Francisco",
                "state": "CA",
                "zip_code": "94103",
                "country": "US",
                "display_address": ["123 Test St", "San Francisco, CA 94103"]
              },
              "phone": "+14155551234",
              "display_phone": "(415) 555-1234",
              "distance": 1500.0
            }
          ],
          "total": 1,
          "region": {
            "center": {
              "latitude": 37.7749,
              "longitude": -122.4194
            }
          }
        }
        """
        return jsonString.data(using: .utf8)!
    }
}
