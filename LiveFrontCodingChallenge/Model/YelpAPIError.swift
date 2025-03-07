//
//  YelpAPIError.swift
//  LiveFrontCodingChallenge
//
//  Created by ousmane diouf on 3/6/25.
//


import Foundation

struct YelpAPIError: Decodable {
    struct ErrorDetail: Decodable {
        let code: String
        let description: String
    }
    
    let error: ErrorDetail

    static func yelpError(_ apiError: YelpAPIError, statusCode: Int) -> NetworkError {
        return .serverError(NSError(
            domain: "YelpAPI",
            code: statusCode,
            userInfo: [
                "errorCode": apiError.error.code,
                "errorDescription": apiError.error.description,
                "statusCode": statusCode
            ]
        ))
    }
    
    // Helper to check if an error is a Yelp API error
    static func isYelpError(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == "YelpAPI"
    }
    
    // Extract the error code from an Error
    static func getYelpErrorCode(from error: Error) -> String? {
        let nsError = error as NSError
        return nsError.domain == "YelpAPI" ? nsError.userInfo["errorCode"] as? String : nil
    }
    
    // Extract the error description from an Error
    static func getYelpErrorDescription(from error: Error) -> String? {
        let nsError = error as NSError
        return nsError.domain == "YelpAPI" ? nsError.userInfo["errorDescription"] as? String : nil
    }
    
    // Extract the HTTP status code from an Error
    static func getStatusCode(from error: Error) -> Int? {
        let nsError = error as NSError
        return nsError.domain == "YelpAPI" ? nsError.userInfo["statusCode"] as? Int : nil
    }
}

