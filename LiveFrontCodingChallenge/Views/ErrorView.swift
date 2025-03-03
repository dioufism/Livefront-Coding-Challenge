//
//  ErrorView.swift
//  LiveFrontCodingChallenge
//
//  Created by ousmane diouf on 3/2/25.
//

import SwiftUI

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Error")
                .font(.title)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.gray)
            
            Button("Retry") {
                onRetry()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
