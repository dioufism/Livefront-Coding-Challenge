//
//  ImageCache.swift
//  LiveFrontCodingChallenge
//
//  Created by ousmane diouf on 3/2/25.
//

import Foundation
import UIKit

final class ImageCache {
    static let shared = ImageCache()
    private init() {}
    
    typealias CacheType = NSCache<NSString, UIImage>
    
    private lazy var cache: CacheType = {
        let cache = CacheType()
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024
        return cache
    }()
}

// MARK: - Internal
extension ImageCache {
    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: NSString(string: key))
    }
    
    func set(image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: NSString(string: key))
    }
}
