//
//  OnboardingPagesView.swift
//  AstraFiPrototype
//
//  The 4-slide intro screens shown on first launch.
//  After this → AuthenticationFlowView (Sign In / Sign Up)


import SwiftUI

private struct OnboardingPage {
    let imageName: String
    let title: String
    let subtitle: String
}

private let pages: [OnboardingPage] = [
    .init(imageName: "onboarding_financial_health",
          title: "Check Your\nFinancial Health",
          subtitle: "Get a clear view of your Income, Expenses, Risk level."),
    .init(imageName: "onboarding_investment_plan",
          title: "Plan your Investment\nAround Goals",
          subtitle: "Goal based Planning to Achieve Faster"),
    .init(imageName: "onboarding_track_assets",
          title: "Track Investment\nAnd Assets",
          subtitle: "Goal based Planning to Achieve Faster"),
    .init(imageName: "onboarding_news_updates",
          title: "News And Updates",
          subtitle: "Goal based Planning to Achieve Faster"),
]


struct OnboardingPagesView: View {
    @EnvironmentObject var appState: AppStateManager
    @State private var currentPage: Int = 0

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {

                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            appState.hasCompletedOnboarding = true  // jump straight to Sign In
                        }
                        .font(.system(size: 17))
                        .foregroundStyle(brandGradient)
                        .padding(.trailing, 24)
                        .padding(.top, 8)
                    } else {
                        // Keep the row height consistent on the last slide
                        Text("Skip").foregroundColor(.clear).padding(.trailing, 24).padding(.top, 8)
                    }
                }
                .frame(height: 44)

                // Swipeable pages
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        _OnboardingPageView(page: pages[index]).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                // Dot indicators
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index
                                  ? AppTheme.primaryTeal
                                  : Color(uiColor: .systemGray4))
                            .frame(width: currentPage == index ? 20 : 8, height: 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, 36)

                // Show "Get Started" button only on the last slide
                if currentPage == pages.count - 1 {
                    Button(action: advance) {
                        Text("Get Started")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .background(brandGradient)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 28)
                    .buttonStyle(PlainButtonStyle())
                } else {
                    // Keep layout stable on slides 1–3 (invisible placeholder)
                    Color.clear
                        .frame(height: 54) // matches button height (17*2 padding + ~20 text)
                }

                Spacer().frame(height: 52)
            }
        }
    }

    private func advance() {
        if currentPage < pages.count - 1 {
            withAnimation { currentPage += 1 }
        } else {
            appState.hasCompletedOnboarding = true
        }
    }
}

// MARK: - Single Page

private struct _OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Image(page.imageName)
                .resizable()
                .scaledToFit()
             //   .frame(width: 280, height: 280)
                .padding(.bottom, 48)

            Text(page.title)
                .font(.system(size: 30, weight: .bold))
                .multilineTextAlignment(.center)
               .foregroundColor(.primary)
            //    .fixedSize(horizontal: false, vertical: true)
              //  .padding(.horizontal, 32)
                .padding(.bottom, 10)

            Text(page.subtitle)
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)

            Spacer()
        }
    }
}

// MARK: - Brand Gradient (shared across auth screens)

var brandGradient: LinearGradient {
    LinearGradient(
        colors: [
            AppTheme.primaryTeal,
            AppTheme.primaryGreen
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Preview

#Preview {
    OnboardingPagesView()
        .environmentObject(AppStateManager())
}
