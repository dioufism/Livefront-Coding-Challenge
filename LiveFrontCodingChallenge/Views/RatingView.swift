//
//  RatingView.swift
//  LiveFrontCodingChallenge
//
//  Created by ousmane diouf on 3/2/25.
//

import SwiftUI

struct RatingView: View {
    let rating: Double
    var size: StarSize = .small
    
    enum StarSize {
        case small, medium
        
        var fontSize: Font {
            switch self {
            case .small: return .caption
            case .medium: return .subheadline
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<Int(rating), id: \.self) { _ in
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(size.fontSize)
            }
            
            if rating.truncatingRemainder(dividingBy: 1) >= 0.5 {
                Image(systemName: "star.leadinghalf.filled")
                    .foregroundColor(.yellow)
                    .font(size.fontSize)
            }
        }
    }
}
