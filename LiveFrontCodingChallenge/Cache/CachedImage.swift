//
//  CachedImage.swift
//  LiveFrontCodingChallenge
//
//  Created by ousmane diouf on 3/2/25.
//

import SwiftUI

public struct CachedImage<Content: View>: View {
    @StateObject private var manager = CachedImageManager()
    
    let url: String
    let animation: Animation?
    let transition: AnyTransition
    @ViewBuilder let content: (AsyncImagePhase) -> Content
    
    public init(
        url: String, animation: Animation? = nil,
        transition: AnyTransition = .identity,
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ) {
        self.url = url
        self.animation = animation
        self.transition = transition
        self.content = content
    }
    
    public var body: some View {
        ZStack {
            switch manager.state {
            case .loading:
                content(.empty)
                    .transition(transition)
            case let .failed(error):
                content(.failure(error))
                    .transition(transition)
            case let .success(uiImage):
                content(.success(Image(uiImage: uiImage)))
                    .transition(transition)
            case .none:
                content(.empty)
                    .transition(transition)
            }
        }
        .animation(animation, value: manager.state)
        .task(id: url) { await manager.load(url) }
    }
}
