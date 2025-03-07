import Foundation

/// Model for decoding Yelp API error responses
struct YelpAPIError: Decodable {
    struct ErrorDetail: Decodable {
        let code: String
        let description: String
    }
    
    let error: ErrorDetail
}

/// Extension to add Yelp API specific error types to NetworkError
extension NetworkError {
    // Create a NetworkError from a YelpAPIError
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
        guard let nsError = error as? NSError else { return false }
        return nsError.domain == "YelpAPI"
    }
    
    // Extract the Yelp error code from an Error
    static func getYelpErrorCode(from error: Error) -> String? {
        guard let nsError = error as? NSError, nsError.domain == "YelpAPI" else { 
            return nil 
        }
        return nsError.userInfo["errorCode"] as? String
    }
    
    // Extract the Yelp error description from an Error
    static func getYelpErrorDescription(from error: Error) -> String? {
        guard let nsError = error as? NSError, nsError.domain == "YelpAPI" else { 
            return nil 
        }
        return nsError.userInfo["errorDescription"] as? String
    }
    
    // Extract the HTTP status code from an Error
    static func getStatusCode(from error: Error) -> Int? {
        guard let nsError = error as? NSError, nsError.domain == "YelpAPI" else { 
            return nil 
        }
        return nsError.userInfo["statusCode"] as? Int
    }
}