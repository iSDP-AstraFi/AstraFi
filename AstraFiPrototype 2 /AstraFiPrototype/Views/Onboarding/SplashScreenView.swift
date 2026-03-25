import SwiftUI

struct SplashScreenView: View {
    @EnvironmentObject var appState: AppStateManager

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.primaryTeal,
                    AppTheme.primaryGreen
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                Text("AstraFi")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("A finance Guiding Star")
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                appState.isLoading = false
            }
        }
    }
}

#Preview {
    SplashScreenView()
        .environmentObject(AppStateManager.withSampleData())
}
