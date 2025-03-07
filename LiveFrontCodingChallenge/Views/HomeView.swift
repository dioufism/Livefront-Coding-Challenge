//
//  ContentView.swift
//  LiveFrontCodingChallenge
//
//  Created by ousmane diouf on 3/1/25.
//

import SwiftUI

struct HomeView: View {
    @State private var viewModel = YelpViewModel()
    @State private var searchText: String = ""
    @State private var isLocationSheetPresented = false
    @State private var isSearchSubmitted = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Button(action: {
                    isLocationSheetPresented = true
                }) {
                    HStack {
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(.blue)
                        
                        Text(viewModel.searchLocation.isEmpty ? "No location selected" : viewModel.searchLocation)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                ZStack {
                    if viewModel.searchLocation.isEmpty {
                        LocationPromptView(onSelectLocation: {
                            isLocationSheetPresented = true
                        })
                    } else if viewModel.isLoading {
                        LoadingView(message: "Searching businesses...")
                    } else if !viewModel.businesses.isEmpty {
                        // Show list when we have results
                        BusinessListContent(
                            businesses: isSearchSubmitted ? viewModel.businesses : filteredBusinesses,
                            onRefresh: { viewModel.searchBestMatchBusinesses() },
                            viewModel: viewModel
                        )
                    } else if let error = viewModel.errorMessage {
                        // Show error
                        ErrorView(
                            // TODO: There are no available businesses at this location
                            message: error,
                            onRetry: { viewModel.searchBestMatchBusinesses() }
                        )
                    } else {
                        // Initial or empty state
                        EmptyStateView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Search restaurants, cafes..."
            )
            .onChange(of: searchText) {_ , newValue in
                if !newValue.isEmpty && !viewModel.searchLocation.isEmpty {
                    isSearchSubmitted = false
                }
            }
            .onSubmit(of: .search) {
                if !viewModel.searchLocation.isEmpty {
                    // Only search when location is set
                    isSearchSubmitted = true
                    viewModel.searchText = searchText
                    viewModel.searchBestMatchBusinesses(query: searchText)
                } else {
                    // Show location sheet if trying to search without location
                    isLocationSheetPresented = true
                }
            }
            .disableAutocorrection(true)
            .navigationTitle("Yelp Search")
            .sheet(isPresented: $isLocationSheetPresented) {
                LocationSelectionView(
                    selectedLocation: $viewModel.searchLocation,
                    onDismiss: {
                        isLocationSheetPresented = false
                        if !viewModel.searchLocation.isEmpty {
                            // After location is selected, perform search with current search term
                            viewModel.searchBestMatchBusinesses(query: searchText.isEmpty ? "" : searchText)
                        }
                    }
                )
            }
        }
    }
    
    // Filter businesses based on search text
    private var filteredBusinesses: [YelpBusiness] {
        if searchText.isEmpty {
            return viewModel.businesses
        } else {
            return viewModel.businesses.filter { business in
                business.name.lowercased().contains(searchText.lowercased()) ||
                business.categories.contains { category in
                    category.title.lowercased().contains(searchText.lowercased())
                }
            }
        }
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Results")
                .font(.title)
                .foregroundColor(.gray)
            
            Text("Enter a search term above to find restaurants, cafes, and more")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

private struct LocationPromptView: View {
    let onSelectLocation: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.circle")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Location Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Please select a location to search for businesses")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            Button("Select Location") {
                onSelectLocation()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

private struct LocationSelectionView: View {
    @State private var searchLocation = ""
    @Binding var selectedLocation: String
    
    let onDismiss: () -> Void
    let popularLocations = ["New York", "Los Angeles", "Chicago", "Dallas", "Miami", "San Francisco", "Seattle"]
    
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Enter a city, address, or zip code", text: $searchLocation)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding()
                
                Button("Use This Location") {
                    selectedLocation = searchLocation
                    onDismiss()
                }
                .disabled(searchLocation.isEmpty)
                .padding()
                .frame(maxWidth: .infinity)
                .background(searchLocation.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                
                Text("Popular Locations")
                    .font(.headline)
                    .padding(.top)
                
                List {
                    ForEach(popularLocations, id: \.self) { location in
                        Button(action: {
                            selectedLocation = location
                            onDismiss()
                        }) {
                            Text(location)
                        }
                    }
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

private struct BusinessListContent: View {
    let businesses: [YelpBusiness]
    let onRefresh: () -> Void
    @Bindable var viewModel: YelpViewModel
    
    var body: some View {
        List {
            ForEach(businesses) { business in
                NavigationLink(value: business) {
                    BusinessCardView(business: business)
                }
                .onAppear {
                    viewModel.loadMoreBusinessesIfNeeded(currentItem: business)
                }
            }
            
            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .refreshable {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            onRefresh()
        }
        .navigationDestination(for: YelpBusiness.self) { business in
            BusinessDetailView(business: business)
        }
    }
}

private struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack {
            Spacer()
            ProgressView(message)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 1)
            Spacer()
        }
    }
}

#Preview {
    HomeView()
}
