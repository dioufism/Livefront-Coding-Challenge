//
//  BusinessActionButtonsView.swift
//  LiveFrontCodingChallenge
//
//  Created by ousmane diouf on 3/2/25.
//

import SwiftUI

struct BusinessActionButtonsView: View {
    let business: YelpBusiness
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                if let mapsUrlString = URL(string: "maps://?daddr=\(business.coordinates.latitude),\(business.coordinates.longitude)") {
                    Link(destination: mapsUrlString) {
                        Label("Directions", systemImage: "car.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                
                if let phoneNumber = URL(string: "tel:\(business.phone)") {
                    Link(destination: phoneNumber) {
                        Label("Call", systemImage: "phone.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            
            if let url = business.url, let businessUrlString = URL(string: url) {
                Link(destination: businessUrlString) {
                    Label("Visit Website", systemImage: "safari.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
    }
}
