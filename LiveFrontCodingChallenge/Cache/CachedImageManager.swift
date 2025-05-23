//
//  CachedImageManager.swift
//  LiveFrontCodingChallenge
//
//  Created by ousmane diouf on 3/2/25.
//

import UIKit

final class CachedImageManager: ObservableObject {
    @Published private(set) var state: CurrentState?
    
    private let imageRetriver = ImageRetriver()
    
    @MainActor
    func load(_ imageURL: String, cache: ImageCache = .shared) async {
        self.state = .loading
        
        if let uiImage = cache.image(forKey: imageURL) {
            state = .success(uiImage)
            return
        }
        
        do {
            let data = try await imageRetriver.fetch(imageURL)
            
            let processedImage = await Task.detached(priority: .userInitiated) { () -> UIImage? in
                guard let image = UIImage(data: data) else { return nil }
                
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200))
                return renderer.image { ctx in
                    image.draw(in: CGRect(origin: .zero, size: CGSize(width: 200, height: 200)))
                }
            }.value
            
            if let image = processedImage {
                state = .success(image)
                cache.set(image: image, forKey: imageURL)
            } else {
                state = .failed(CachedImageError.invalidData)
            }
        } catch {
            state = .failed(error)
        }
    }
}

// MARK: - Model
extension CachedImageManager {
    enum CurrentState: Equatable {
        case loading
        case failed(Error)
        case success(UIImage)
        
        static func == (lhs: CurrentState, rhs: CurrentState) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading):
                return true
            case (let .failed(lhsError), let .failed(rhsError)):
                return lhsError.localizedDescription == rhsError.localizedDescription
            case (let .success(lhsData), let .success(rhsData)):
                return lhsData == rhsData
            default:
                return false
            }
        }
    }
    
    enum CachedImageError: Error {
        case invalidData
    }
}
