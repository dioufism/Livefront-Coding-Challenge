//
//  ContentView.swift
//  LiveFrontCodingChallenge
//
//  Created by ousmane diouf on 3/1/25.
//

import SwiftUI

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = YelpViewModel()
    @State private var searchText = ""
    
    var body: some View {
        VStack {
            HStack {
                TextField("Enter location (e.g. Dallas)", text: $searchText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Button("Search") {
                    viewModel.searchLocation = searchText
                    viewModel.searchBusinesses()
                }
                .padding(.horizontal)
                .disabled(searchText.isEmpty)
            }
            .padding()
            
            if viewModel.isLoading {
                ProgressView("Loading...")
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            }
            
            List(viewModel.businesses) { business in
                BusinessRow(business: business)
            }
            .listStyle(.plain)
        }
        .navigationTitle("Yelp Search")
    }
}

struct BusinessRow: View {
    let business: YelpBusiness
    
    var body: some View {
        HStack {
            CachedImageView(url: business.imageURL, imageWidth: 70, imageHeight: 70, showError: false)
            VStack(alignment: .leading, spacing: 5) {
                Text(business.name)
                    .font(.headline)
                
                Text(business.categories.map { $0.title }.joined(separator: ", "))
                    .font(.subheadline)
                
                HStack {
                    Text("Rating: \(business.rating, specifier: "%.1f")")
                    Text("•")
                    Text("\(business.reviewCount) reviews")
                    if let price = business.price {
                        Text("•")
                        Text(price)
                    }
                }
                .font(.caption)
            }
            .padding(.vertical, 5)
        }
    }
}

#Preview {
    HomeView()
}
