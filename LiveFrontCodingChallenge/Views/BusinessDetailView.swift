//
//  BusinessDetailView.swift
//  LiveFrontCodingChallenge
//
//  Created by ousmane diouf on 3/2/25.
//

import SwiftUI

struct BusinessDetailView: View {
    let business: YelpBusiness
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let imageURL = business.imageURL {
                    BusinesDisplayImageView(imageURL: imageURL)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        BusinessHeaderInfoView(business: business)
                        
                        Divider()
                        
                        ContactInfoView(business: business)
                        
                        Divider()
                        
                        BusinessActionButtonsView(business: business)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(business.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BusinessHeaderInfoView: View {
    let business: YelpBusiness
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(business.name)
            .font(.title)
            .fontWeight(.bold)
            
            HStack {
                if !business.categories.isEmpty {
                    Text(business.categories.map {
                        $0.title
                    }
                    .joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                }
                
                if let price = business.price {
                    Text("•")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    Text(price)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                }
            }
            
            HStack {
                RatingView(rating: business.rating, size: .medium)
                
                Text("\(business.rating, specifier: "%.1f") (\(business.reviewCount) reviews)")
                .foregroundColor(.gray)
            }
        }
    }
}

private struct ContactInfoView: View {
    let business: YelpBusiness
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !business.location.displayAddress.isEmpty {
                Label {
                    Text(business.location.displayAddress.joined(separator: ", "))
                    .font(.subheadline)
                }
                
                icon: {
                    Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                }
            }
            
            Label {
                Text(business.displayPhone)
                .font(.subheadline)
            }
            
            icon: {
                Image(systemName: "phone.fill")
                .foregroundColor(.green)
            }
        }
    }

}

private struct BusinesDisplayImageView: View {
    let imageURL: String?
    
    var body: some View {
        if let imageURL = imageURL {
            CachedImageView(url: imageURL, imageWidth: .infinity, imageHeight: 200, showError: true)
            .aspectRatio(contentMode: .fill)
            .frame(height: 200)
            .clipped()
        }
    }
}
