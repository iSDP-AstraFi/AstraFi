

import SwiftUI

struct AppRootView: View {
    @EnvironmentObject var appState: AppStateManager

    var body: some View {
        Group {
            if appState.isLoading {
                // ── Stage 1: Splash ────────────────────────────────
                SplashScreenView()

            } else if appState.showDashboard {
                // ── Stage 7: Main app ──────────────────────────────
                FinalTab()

            } else if appState.isAuthenticated {
                // ── Stages 4-6: Assessment → Report ───────────────
                // WelcomeOnboardingView owns its own NavigationStack
                // and pushes through all 4 assessment steps, then
                // FinancialHealthReportView, which sets showDashboard = true
                WelcomeOnboardingView()

            } else if appState.hasCompletedOnboarding {
                // ── Stage 3: Sign In / Sign Up ─────────────────────
                NavigationStack {
                    AuthenticationFlowView()
                }

            } else {
                // ── Stage 2: 4-slide intro onboarding ─────────────
                OnboardingPagesView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.isLoading)
        .animation(.easeInOut(duration: 0.35), value: appState.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.35), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.35), value: appState.showDashboard)
        .task {
            await appState.syncMutualFundNAVs()
        }
    }
}

#Preview {
    AppRootView()
        .environmentObject(AppStateManager.withSampleData())
}
