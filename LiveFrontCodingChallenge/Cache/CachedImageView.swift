//
//  CachedImageView.swift
//  LiveFrontCodingChallenge
//
//  Created by ousmane diouf on 3/2/25.

import SwiftUI

struct CachedImageView: View {
    let url: String?
    var imageWidth: CGFloat?
    let imageHeight: CGFloat
    let showError: Bool
    
    var body: some View {
        Group {
            if let url = url {
                cached(url: url)
            } else {
                placeholder
            }
        }
    }
}

// MARK: - Private Methods
private extension CachedImageView {
    func cached(url: String) -> some View {
        CachedImage(url: url, animation: .easeInOut, transition: .opacity) { phase in
            switch phase {
                case .empty:
                placeholder
                
                case let .success(image):
                GeometryReader { proxy in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
                .frame(width: imageWidth, height: imageHeight)
                .clipped()
                
                case let .failure(error):
                if showError {
                    Text(error.localizedDescription)
                        .frame(width: imageWidth, height: imageHeight)
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(.red)
                } else {
                    placeholder
                }
            @unknown default:
                placeholder
            }
        }
    }
    
    var placeholder: some View {
        Color.gray
            .opacity(0.2)
            .frame(width: imageWidth, height: imageHeight)
    }
}
