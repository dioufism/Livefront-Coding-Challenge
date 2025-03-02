//
//  YelpBusiness.swift
//  LiveFrontCodingChallenge
//
//  Created by ousmane diouf on 3/1/25.
//

import Foundation

struct YelpBusinessSearchResponse: Decodable {
    let businesses: [YelpBusiness]
    let total: Int
    let region: YelpRegion?
}

struct YelpRegion: Decodable {
    let center: YelpCoordinates
}

struct YelpBusiness: Decodable, Identifiable {
    let id: String
    let name: String
    let imageURL: String?
    let isClosed: Bool
    let url: String?
    let reviewCount: Int
    let categories: [YelpCategory]
    let rating: Double
    let coordinates: YelpCoordinates
    let transactions: [String]
    let price: String?
    let location: YelpLocation
    let phone: String
    let displayPhone: String
    let distance: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, name, url, categories, rating, coordinates, transactions, price, location, phone, distance
        case imageURL = "image_url"
        case isClosed = "is_closed"
        case reviewCount = "review_count"
        case displayPhone = "display_phone"
    }
}

struct YelpCategory: Decodable {
    let alias: String
    let title: String
}

struct YelpCoordinates: Decodable {
    let latitude: Double
    let longitude: Double
}

struct YelpLocation: Decodable {
    let address1: String?
    let address2: String?
    let address3: String?
    let city: String
    let zipCode: String
    let country: String
    let state: String
    let displayAddress: [String]
    
    enum CodingKeys: String, CodingKey {
        case address1, address2, address3, city, country, state
        case zipCode = "zip_code"
        case displayAddress = "display_address"
    }
}
