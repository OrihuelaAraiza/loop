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
    @State private var juniorMode = JuniorModeManager.shared

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
            .environment(\.isJuniorMode, juniorMode.isActive)
            .animation(.easeInOut, value: appState.isSignedIn)
            .animation(.easeInOut, value: appState.hasCompletedOnboarding)
            .onAppear {
                if juniorMode.isActive {
                    appState.userProfile.cardBadge = IdentityCardBadge.normalizedForJunior(
                        appState.userProfile.cardBadge,
                        junior: true
                    )
                }
            }
            .onChange(of: juniorMode.isActive) { _, isActive in
                if isActive {
                    appState.userProfile.cardBadge = IdentityCardBadge.normalizedForJunior(
                        appState.userProfile.cardBadge,
                        junior: true
                    )
                }
            }
        }
    }
}
