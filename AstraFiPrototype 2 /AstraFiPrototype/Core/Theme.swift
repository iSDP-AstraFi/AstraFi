import SwiftUI

struct AppTheme {
    // MARK: - App Colors
    static let primaryTeal = Color(red: 0.1, green: 0.3, blue: 0.3)
    static let primaryGreen = Color(red: 0.4, green: 0.7, blue: 0.25)
    static let darkTealBackground = Color(red: 0.05, green: 0.15, blue: 0.1)
    
    // MARK: - Backgrounds
    static func appBackground(for colorScheme: ColorScheme) -> AnyView {
        if colorScheme == .dark {
            return AnyView(
                Color(red: 0.08, green: 0.08, blue: 0.1)
                    .ignoresSafeArea()
            )
        } else {
            return AnyView(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .white,
                        .purple.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
        }
    }
    
    static let cardBackground = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 1)
            : .white
    })
    
    static let adaptiveShadow = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(white: 0, alpha: 0)
            : UIColor(white: 0, alpha: 0.06)
    })
    
    static let healthCardBackgroundDark = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.20, blue: 0.15, alpha: 1)
            : UIColor(red: 0.88, green: 0.95, blue: 0.87, alpha: 1)
    })
    
    static let healthCardBackgroundLight = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.17, blue: 0.12, alpha: 1)
            : UIColor(red: 0.85, green: 0.93, blue: 0.84, alpha: 1)
    })
    
    // MARK: - Accent Styles
    static let accentGradient = LinearGradient(
        gradient: Gradient(colors: [primaryTeal, primaryGreen]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentShadow = Color.purple.opacity(0.3)
    static let shadowRadius: CGFloat = 20
    static let shadowOffset = CGPoint(x: 0, y: 10)
    
    // Helper to apply common accent style
    static func applyAccentStyle<V: View>(_ content: V) -> some View {
        content
            .background(accentGradient)
            .shadow(color: accentShadow, radius: shadowRadius, x: shadowOffset.x, y: shadowOffset.y)
    }
}

extension View {
    func appAccentButtonStyle() -> some View {
        self
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.accentGradient)
            .cornerRadius(14)
            .shadow(color: AppTheme.accentShadow, radius: 10, x: 0, y: 5)
    }
}

extension Color {
    static let tableHeaderBackground = Color(UIColor.secondarySystemBackground)
    static let subtleBackground      = Color(UIColor.tertiarySystemBackground)
    static let tableBorder           = Color.gray.opacity(0.2)
    static let recommendationBackground = Color.blue.opacity(0.05)
    static let connectorLine         = Color.gray.opacity(0.3)
    static let stripeBackground      = Color.gray.opacity(0.05)
}
