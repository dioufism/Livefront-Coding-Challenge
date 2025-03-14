//
//  YelpViewModelTest.swift
//  LiveFrontCodingChallengeTests
//
//  Created by ousmane diouf on 3/6/25.
//

import Foundation
import XCTest
@testable import LiveFrontCodingChallenge

final class YelpViewModelTests: XCTestCase {
    var sut: YelpViewModel!
    var mockService: YelpService!
    var mockSession: URLSession!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        MockURLProtocol.reset()
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)
        
        mockService = YelpService(session: mockSession)
        sut = YelpViewModel(yelpService: mockService)
    }
    
    override func tearDownWithError() throws {
        sut = nil
        mockService = nil
        mockSession = nil
        try super.tearDownWithError()
    }
    
    func test_init_SetsInitialState() {
        // Assert initial state
        XCTAssertEqual(sut.searchText, "")
        XCTAssertEqual(sut.searchLocation, "")
        XCTAssertTrue(sut.businesses.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoadingMore)
        XCTAssertTrue(sut.hasMoreResults)
    }
    
    @MainActor
    func test_searchBusinesses_WithEmptyLocation_SetsErrorMessage() async {
        // Given
        sut.searchLocation = ""
        
        // When
        sut.searchBestMatchBusinesses()
        
        // Then
        XCTAssertEqual(sut.errorMessage, "Please enter a location to search")
        XCTAssertFalse(sut.isLoading)
        // Service shouldn't be called
        XCTAssertNil(MockURLProtocol.lastRequest)
    }
    
    @MainActor
    func test_searchBusinesses_WithValidParameters_ReturnsResults() async throws {
        // Given
        try setupSuccessResponse(businessCount: 5, totalCount: 10)
        
        sut.searchLocation = "San Francisco"
        sut.searchText = "coffee"
        
        // When
        sut.searchBestMatchBusinesses()
        
        // Wait for the async task to complete
        await waitForAsyncOperations()
        
        // Then
        XCTAssertEqual(sut.businesses.count, 5)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertTrue(sut.hasMoreResults)
        
        // Verify parameters passed to service (via captured URL)
        XCTAssertNotNil(MockURLProtocol.lastRequest)
        if let url = MockURLProtocol.lastRequest?.url,
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            let queryItems = components.queryItems ?? []
            XCTAssertTrue(queryItems.contains(where: { $0.name == "location" && $0.value == "San Francisco" }))
            XCTAssertTrue(queryItems.contains(where: { $0.name == "term" && $0.value == "coffee" }))
            XCTAssertTrue(queryItems.contains(where: { $0.name == "limit" && $0.value == "20" }))
            XCTAssertTrue(queryItems.contains(where: { $0.name == "offset" && $0.value == "0" }))
        }
    }
    
    @MainActor
    func test_searchBusinesses_WithEmptyResults_SetsNoResultsMessage() async throws {
        // Given
        try setupSuccessResponse(businessCount: 0, totalCount: 0)
        
        sut.searchLocation = "Non-existent location"
        sut.searchText = "xyz123"
        
        // When
        sut.searchBestMatchBusinesses()
        
        // Wait for the async task to complete
        await waitForAsyncOperations()
        
        // Then
        XCTAssertTrue(sut.businesses.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, "No results found")
        XCTAssertFalse(sut.hasMoreResults)
    }
    
    @MainActor
    func test_searchBusinesses_WithCustomQueryParameter_UsesProvidedQuery() async throws {
        // Given
        try setupSuccessResponse(businessCount: 5, totalCount: 10)
        
        sut.searchLocation = "San Francisco"
        sut.searchText = "coffee" // This should be ignored
        
        // When
        sut.searchBestMatchBusinesses(query: "tea") // This should be used
        
        // Wait for the async task to complete
        await waitForAsyncOperations()
        
        // Then
        if let url = MockURLProtocol.lastRequest?.url,
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            let queryItems = components.queryItems ?? []
            XCTAssertTrue(queryItems.contains(where: { $0.name == "term" && $0.value == "tea" }))
            // Make sure it's not using the stored value
            XCTAssertFalse(queryItems.contains(where: { $0.name == "term" && $0.value == "coffee" }))
        } else {
            XCTFail("No URL request was captured")
        }
    }
    
    // MARK: - Error Handling Tests
    
    @MainActor
    func test_searchBusinesses_WithNetworkError_SetsErrorMessage() async {
        // Given
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        setupErrorResponse(error: networkError)
        
        sut.searchLocation = "San Francisco"
        
        // When
        sut.searchBestMatchBusinesses()
        
        // Wait for the async task to complete
        await waitForAsyncOperations()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.businesses.isEmpty)
        XCTAssertFalse(sut.hasMoreResults)
    }
    
    @MainActor
    func test_searchBusinesses_WithLocationNotFound_SetsAppropriateErrorMessage() async throws {
        // Given - Use the actual Yelp API error response for location not found
        try setupYelpAPIErrorResponse(
            statusCode: 404,
            errorCode: "LOCATION_NOT_FOUND",
            description: "Could not execute search, try specifying a more exact location."
        )
        
        sut.searchLocation = "xyz123"
        
        // When
        sut.searchBestMatchBusinesses()
        
        // Wait for the async task to complete
        await waitForAsyncOperations()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        
        let errorMessage = try XCTUnwrap(sut.errorMessage)
        XCTAssertEqual(errorMessage, "The requested information could not be found.")
    }
    
    @MainActor
    func test_searchBusinesses_WithDecodingError_SetsAppropriateErrorMessage() async throws {
        // Given
        // Invalid JSON response that will cause a decoding error
        MockURLProtocol.mockData = "{ invalid json }".data(using: .utf8)
        try MockURLProtocol.mockResponse = createHTTPResponse()
        
        sut.searchLocation = "San Francisco"
        
        // When
        sut.searchBestMatchBusinesses()
        
        // Wait for the async task to complete
        await waitForAsyncOperations()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("Unable to process server response") ?? false)
    }
    
    // MARK: - Pagination Tests
    
    @MainActor
    func test_loadMoreBusinessesIfNeeded_WhenAtThreshold_LoadsMoreBusinesses() async throws {
        // Given - First load some initial businesses
        try setupSuccessResponse(businessCount: 20, totalCount: 40)
        
        sut.searchLocation = "San Francisco"
        sut.searchBestMatchBusinesses()
        
        // Wait for the initial load to complete
        await waitForAsyncOperations()
        
        // Setup for the next page of results
        MockURLProtocol.reset()
        try setupSuccessResponse(businessCount: 20, totalCount: 40)
        
        // When - call loadMoreBusinessesIfNeeded with an item at the threshold
        let thresholdItem = sut.businesses[17] // Third to last item (20 - 3 = 17)
        sut.loadMoreBusinessesIfNeeded(currentItem: thresholdItem)
        
        // Wait for pagination to complete
        await waitForAsyncOperations()
        
        // Then
        XCTAssertNotNil(MockURLProtocol.lastRequest)
        if let url = MockURLProtocol.lastRequest?.url,
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            let queryItems = components.queryItems ?? []
            // Verify this was a pagination request with offset=20
            XCTAssertTrue(queryItems.contains(where: { $0.name == "offset" && $0.value == "20" }))
        } else {
            XCTFail("No pagination request was made")
        }
    }
    
    @MainActor
    func test_loadMoreBusinessesIfNeeded_WhenNotAtThreshold_DoesNotLoadMore() async throws {
        // Given - Load initial businesses
        try setupSuccessResponse(businessCount: 20, totalCount: 40)
        
        sut.searchLocation = "San Francisco"
        sut.searchBestMatchBusinesses()
        
        // Wait for the initial load to complete
        await waitForAsyncOperations()
        
        // Reset to detect if another request is made
        MockURLProtocol.reset()
        
        // When - call with an item that's not at the threshold
        let nonThresholdItem = sut.businesses[10] // Middle of the list
        sut.loadMoreBusinessesIfNeeded(currentItem: nonThresholdItem)
        
        // Use a short delay to verify no additional calls were made
        await waitForAsyncOperations()
        
        // Then - no request should have been made
        XCTAssertNil(MockURLProtocol.lastRequest)
    }
    
    @MainActor
    func test_loadMoreBusinessesIfNeeded_WhenAlreadyLoading_DoesNotLoadMore() async throws {
        // Given
        try setupSuccessResponse(businessCount: 20, totalCount: 40)
        
        sut.searchLocation = "San Francisco"
        sut.searchBestMatchBusinesses()
        
        // Wait for the initial load to complete
        await waitForAsyncOperations()
        
        sut.isLoadingMore = true
        MockURLProtocol.reset()
        
        // When
        let thresholdItem = sut.businesses[17]
        sut.loadMoreBusinessesIfNeeded(currentItem: thresholdItem)
        
        // Wait a bit
        await waitForAsyncOperations()
        
        // Then - no request should have been made
        XCTAssertNil(MockURLProtocol.lastRequest)
    }
    
    @MainActor
    func test_loadMoreBusinessesIfNeeded_WhenNoMoreResults_DoesNotLoadMore() async throws {
        // Given
        try setupSuccessResponse(businessCount: 20, totalCount: 20)
        
        sut.searchLocation = "San Francisco"
        sut.searchBestMatchBusinesses()
        
        // Wait for the initial load to complete
        await waitForAsyncOperations()
        
        // hasMoreResults should be false since total equals the number of loaded businesses
        // Reset to detect if another request is made
        MockURLProtocol.reset()
        
        // When
        let thresholdItem = sut.businesses[17]
        sut.loadMoreBusinessesIfNeeded(currentItem: thresholdItem)
        
        // Wait a bit
        await waitForAsyncOperations()
        
        // Then - no request should have been made
        XCTAssertNil(MockURLProtocol.lastRequest)
    }
    
    @MainActor
    func test_loadMoreBusinessesIfNeeded_WithNonExistentItem_DoesNothing() async throws {
        // Arrange
        try setupSuccessResponse(businessCount: 5, totalCount: 10)
        
        sut.searchLocation = "San Francisco"
        sut.searchBestMatchBusinesses()
        
        // Wait for the initial load to complete
        await waitForAsyncOperations()
        
        // Reset to detect if another request is made
        MockURLProtocol.reset()
        
        // Create a business that doesn't exist in our list
        let nonExistentBusiness = YelpBusiness(
            id: "non-existent",
            name: "Not In List",
            imageURL: "https://example.com/image.jpg",
            isClosed: false,
            url: "https://example.com/business",
            reviewCount: 100,
            categories: [],
            rating: 4.5,
            coordinates: YelpCoordinates(latitude: 37.0, longitude: -122.0),
            transactions: [],
            price: "$$",
            location: YelpLocation(
                address1: "123 Main St",
                address2: nil,
                address3: nil,
                city: "San Francisco",
                zipCode: "CA",
                country: "94103",
                state: "US",
                displayAddress: []
            ),
            phone: "",
            displayPhone: "",
            distance: 1000.0
        )
        
        // Act
        sut.loadMoreBusinessesIfNeeded(currentItem: nonExistentBusiness)
        
        // Wait a bit
        await waitForAsyncOperations()
        
        // Assert - no request should have been made
        XCTAssertNil(MockURLProtocol.lastRequest)
    }
}

// MARK: Test helpers
extension YelpViewModelTests {
    func createBusinessSearchResponse(businessCount: Int, totalCount: Int) throws -> Data {
        // Build a JSON string with the specified number of businesses
        var businessJsonArray = ""
        
        for i in 0..<businessCount {
            if i > 0 {
                businessJsonArray += ","
            }
            
            businessJsonArray += """
            {
              "id": "business-\(i)",
              "name": "Business \(i)",
              "image_url": "https://example.com/image\(i).jpg",
              "is_closed": false,
              "url": "https://example.com/business\(i)",
              "review_count": \(100 + i),
              "categories": [
                {
                  "alias": "restaurant",
                  "title": "Restaurant"
                }
              ],
              "rating": \(4.0 + (Double(i) / 10.0)),
              "coordinates": {
                "latitude": \(37.0 + Double(i)),
                "longitude": \(-122.0 + Double(i))
              },
              "transactions": ["delivery", "pickup"],
              "price": "$$",
              "location": {
                "address1": "123 Main St",
                "address2": null,
                "address3": null,
                "city": "San Francisco",
                "state": "CA",
                "zip_code": "94103",
                "country": "US",
                "display_address": ["123 Main St", "San Francisco, CA 94103"]
              },
              "phone": "+14155551234",
              "display_phone": "(415) 555-1234",
              "distance": \(1000.0 + Double(i * 100))
            }
            """
        }
        
        let jsonString = """
        {
          "businesses": [\(businessJsonArray)],
          "total": \(totalCount),
          "region": {
            "center": {
              "latitude": 37.0,
              "longitude": -122.0
            }
          }
        }
        """
        let data =  try XCTUnwrap(jsonString.data(using: .utf8))
        
        return data
    }
    
    func createHTTPResponse(statusCode: Int = 200)  throws ->  HTTPURLResponse {
        let url = try XCTUnwrap(URL(string: "https://api.yelp.com/v3/businesses/search"))
        let response = try XCTUnwrap(HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        ))
        return response
    }
    
    func setupSuccessResponse(businessCount: Int, totalCount: Int) throws {
        MockURLProtocol.mockData = try createBusinessSearchResponse(businessCount: businessCount, totalCount: totalCount)
        MockURLProtocol.mockResponse = try createHTTPResponse()
        MockURLProtocol.mockError = nil
    }
    
    func setupErrorResponse(error: Error) {
        MockURLProtocol.mockData = nil
        MockURLProtocol.mockResponse = nil
        MockURLProtocol.mockError = error
    }
    
    func setupHTTPErrorResponse(statusCode: Int) throws {
        MockURLProtocol.mockData = "{}".data(using: .utf8)
        MockURLProtocol.mockResponse = try createHTTPResponse(statusCode: statusCode)
        MockURLProtocol.mockError = nil
    }
    
    func setupYelpAPIErrorResponse(statusCode: Int, errorCode: String, description: String) throws {
        let errorJson = """
        {
          "error": {
            "code": "\(errorCode)",
            "description": "\(description)"
          }
        }
        """
        
        MockURLProtocol.mockData = errorJson.data(using: .utf8)
        MockURLProtocol.mockResponse = try createHTTPResponse(statusCode: statusCode)
        MockURLProtocol.mockError = nil
    }
    
    // Helper to wait for async operations
    func waitForAsyncOperations() async {
        try? await Task.sleep(nanoseconds: 100_000_000)
    }
}
