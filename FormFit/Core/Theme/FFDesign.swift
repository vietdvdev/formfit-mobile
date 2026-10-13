import SwiftUI

/// Hệ thống Design System cao cấp dành cho FormFit
/// Bao gồm: Bảng màu thể thao công nghệ cao, Gradient, Card Styles, Glassmorphism và Micro-interactions
public enum FFDesign {
    
    // MARK: - Color Palette
    public enum Colors {
        // Neon / High-energy Sports Accents
        public static let primaryNeon = Color(red: 0.13, green: 0.88, blue: 0.55) // Electric Emerald / Volt Green
        public static let primaryGradientStart = Color(red: 0.05, green: 0.78, blue: 0.58)
        public static let primaryGradientEnd = Color(red: 0.12, green: 0.58, blue: 0.95)
        
        public static let electricBlue = Color(red: 0.15, green: 0.55, blue: 1.0)
        public static let vibrantOrange = Color(red: 1.0, green: 0.42, blue: 0.18)
        public static let sunsetPink = Color(red: 0.98, green: 0.22, blue: 0.48)
        public static let cyberPurple = Color(red: 0.58, green: 0.28, blue: 0.98)
        public static let energyYellow = Color(red: 1.0, green: 0.82, blue: 0.15)
        
        // Neutral & Surfaces (Dark-mode & Premium Glass surfaces)
        public static let backgroundDark = Color(red: 0.06, green: 0.07, blue: 0.10)
        public static let cardSurface = Color(uiColor: .secondarySystemGroupedBackground)
        public static let cardSurfaceElevated = Color(uiColor: .tertiarySystemGroupedBackground)
        public static let glassBorder = Color.white.opacity(0.12)
        public static let glassBackground = Color(uiColor: .systemBackground).opacity(0.72)
    }
    
    // MARK: - Premium Gradients
    public enum Gradients {
        public static let workoutHero = LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.55, blue: 0.95),
                Color(red: 0.12, green: 0.32, blue: 0.88),
                Color(red: 0.42, green: 0.18, blue: 0.85)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        public static let energyFlame = LinearGradient(
            colors: [Colors.vibrantOrange, Colors.sunsetPink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        public static let neonSuccess = LinearGradient(
            colors: [Colors.primaryNeon, Color(red: 0.05, green: 0.65, blue: 0.55)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        public static let glassCard = LinearGradient(
            colors: [
                Color.white.opacity(0.12),
                Color.white.opacity(0.04)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Common Metrics & Corners
    public enum Radius {
        public static let small: CGFloat = 10
        public static let medium: CGFloat = 16
        public static let large: CGFloat = 22
        public static let pill: CGFloat = 999
    }
    
    public enum Shadow {
        public static let soft = ShadowConfig(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        public static let glow = ShadowConfig(color: Colors.primaryNeon.opacity(0.35), radius: 16, x: 0, y: 6)
        public static let neonBlue = ShadowConfig(color: Colors.electricBlue.opacity(0.3), radius: 14, x: 0, y: 6)
    }
    
    public struct ShadowConfig {
        public let color: Color
        public let radius: CGFloat
        public let x: CGFloat
        public let y: CGFloat
    }
}

// MARK: - View Modifiers
public struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = FFDesign.Radius.large
    
    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.25), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Color.black.opacity(0.06),
                radius: 12,
                x: 0,
                y: 6
            )
    }
}

public struct PressableSpringModifier: ViewModifier {
    @State private var isPressed = false
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

public extension View {
    func ffGlassCard(cornerRadius: CGFloat = FFDesign.Radius.large) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
    
    func ffPressable() -> some View {
        modifier(PressableSpringModifier())
    }
}
