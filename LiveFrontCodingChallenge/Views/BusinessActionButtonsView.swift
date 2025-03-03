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
                Link(destination: URL(string: "maps://?daddr=\(business.coordinates.latitude),\(business.coordinates.longitude)")!) {
                    Label("Directions", systemImage: "car.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Link(destination: URL(string: "tel:\(business.phone)")!) {
                    Label("Call", systemImage: "phone.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            
            Link(destination: URL(string: business.url!)!) {
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
