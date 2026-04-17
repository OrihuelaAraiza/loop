//
//  loopApp.swift
//  loop
//
//  Created by Juan Pablo Orihuela Araiza on 15/04/26.
//

import SwiftUI

@main
struct loopApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            Group {
                if !appState.isSignedIn {
                    AuthView()
                        .environmentObject(appState)
                } else if appState.hasCompletedOnboarding {
                    MainTabView()
                        .environmentObject(appState)
                } else {
                    OnboardingFlow()
                        .environmentObject(appState)
                }
            }
            .animation(.easeInOut, value: appState.isSignedIn)
            .animation(.easeInOut, value: appState.hasCompletedOnboarding)
        }
    }
}
