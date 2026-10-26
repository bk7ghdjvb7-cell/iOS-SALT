import SwiftUI

// MARK: - SALT Brand Colors
// Purple • Red • Gold — Minimal, professional, high-contrast

extension Color {
    // Primary Brand
    static let saltPurple = Color(red: 0.42, green: 0.18, blue: 0.55)      // Deep regal purple
    static let saltPurpleLight = Color(red: 0.55, green: 0.30, blue: 0.70)
    static let saltPurpleDark = Color(red: 0.28, green: 0.10, blue: 0.38)
    
    // Accent
    static let saltRed = Color(red: 0.78, green: 0.18, blue: 0.22)         // Strong red
    static let saltRedLight = Color(red: 0.90, green: 0.35, blue: 0.38)
    
    // Highlight / Gold
    static let saltGold = Color(red: 0.85, green: 0.68, blue: 0.22)        // Rich gold
    static let saltGoldLight = Color(red: 0.95, green: 0.82, blue: 0.45)
    
    // Neutrals
    static let saltBackground = Color(uiColor: .systemBackground)
    static let saltSecondaryBackground = Color(uiColor: .secondarySystemBackground)
    static let saltTertiaryBackground = Color(uiColor: .tertiarySystemBackground)
    static let saltLabel = Color(uiColor: .label)
    static let saltSecondaryLabel = Color(uiColor: .secondaryLabel)
}

// MARK: - Typography Scale
struct SaltTypography {
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
}

// MARK: - Reusable Button Styles
struct SaltPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SaltTypography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.saltPurple)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SaltSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SaltTypography.headline)
            .foregroundStyle(Color.saltPurple)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.saltPurple.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

struct SaltGoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SaltTypography.headline)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.saltGold)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

// MARK: - Card Modifier
struct SaltCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.saltSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func saltCard() -> some View {
        modifier(SaltCardModifier())
    }
}
