//
//  BusinessCardView.swift
//  LiveFrontCodingChallenge
//
//  Created by ousmane diouf on 3/2/25.
//

import SwiftUI

struct BusinessCardView: View {
    let business: YelpBusiness
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if let imageURL = business.imageURL {
                CachedImageView(url: imageURL, imageWidth: 60, imageHeight: 60, showError: false)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(business.name)
                .font(.headline)
                
                if !business.categories.isEmpty {
                    Text(business.categories.map {
                        $0.title
                    }
                         .joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    RatingView(rating: business.rating)
                    
                    Text("(\(business.reviewCount))")
                    .font(.caption)
                    .foregroundColor(.gray)
                    
                    if let price = business.price {
                        Text("•")
                        .font(.caption)
                        .foregroundColor(.gray)
                        Text(price)
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
        }
        .padding(.vertical, 8)
    }
}
