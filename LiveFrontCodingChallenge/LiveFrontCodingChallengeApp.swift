//
//  LiveFrontCodingChallengeApp.swift
//  LiveFrontCodingChallenge
//
//  Created by ousmane diouf on 3/1/25.
//

import SwiftUI

@main
struct LiveFrontCodingChallengeApp: App {
    
    init() {
        APIConfig.setupAPIKey()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
