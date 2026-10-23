import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Cross-platform dynamic color helpers ensuring native Apple system appearance
/// across iOS, iPadOS, and macOS preview environments.
extension Color {
    /// Fixed feedback fills chosen for white foreground contrast in both appearances.
    public static var quizCorrectFeedback: Color {
        Color(red: 27.0 / 255, green: 94.0 / 255, blue: 32.0 / 255)
    }

    public static var quizIncorrectFeedback: Color {
        Color(red: 183.0 / 255, green: 28.0 / 255, blue: 28.0 / 255)
    }

    /// Adaptive grouped canvas background:
    /// - Light mode: `#F2F2F7` (`UIColor.systemGroupedBackground`)
    /// - Dark mode: `#000000` (Pure OLED black)
    public static var adaptiveBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .systemGroupedBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color(.sRGB, red: 0.95, green: 0.95, blue: 0.97, opacity: 1)
        #endif
    }
    
    /// Adaptive elevated card surface color:
    /// - Light mode: `#FFFFFF` (Pure white)
    /// - Dark mode: `#1C1C1E` (Elevated dark gray)
    public static var adaptiveCardBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .secondarySystemGroupedBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 1)
        #endif
    }
    
    /// Adaptive secondary background color for input elements and unselected option buttons.
    public static var adaptiveSecondaryBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .secondarySystemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color.gray.opacity(0.12)
        #endif
    }
    
    /// Adaptive tertiary background color for explanation banners.
    public static var adaptiveTertiaryBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .tertiarySystemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color.gray.opacity(0.08)
        #endif
    }
    
    /// Subtle adaptive border/separator color.
    public static var adaptiveBorder: Color {
        #if canImport(UIKit)
        return Color(uiColor: .separator)
        #else
        return Color.gray.opacity(0.2)
        #endif
    }
}
