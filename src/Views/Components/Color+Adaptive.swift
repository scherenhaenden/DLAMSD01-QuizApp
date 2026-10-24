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

    /// Adaptive passing/success text color providing >= 7:1 (AAA) contrast:
    /// - Light mode: Dark emerald green `#1B5E20` on light backgrounds (CR = 7.87:1 on white)
    /// - Dark mode: Bright mint green `#30D158` on dark backgrounds (CR = 8.42:1 on #1C1C1E, 10.39:1 on #000000)
    public static var adaptiveSuccessText: Color {
        #if canImport(UIKit)
        return Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 48.0 / 255, green: 209.0 / 255, blue: 88.0 / 255, alpha: 1.0)
                : UIColor(red: 27.0 / 255, green: 94.0 / 255, blue: 32.0 / 255, alpha: 1.0)
        })
        #elseif canImport(AppKit)
        return Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 48.0 / 255, green: 209.0 / 255, blue: 88.0 / 255, alpha: 1.0)
                : NSColor(red: 27.0 / 255, green: 94.0 / 255, blue: 32.0 / 255, alpha: 1.0)
        }))
        #else
        return Color(red: 27.0 / 255, green: 94.0 / 255, blue: 32.0 / 255)
        #endif
    }

    /// Adaptive failing/error text color providing >= 4.5:1 (AA) contrast:
    /// - Light mode: Crimson red `#B71C1C` on light backgrounds (CR = 6.57:1 on white)
    /// - Dark mode: Bright coral red `#FF6961` on dark backgrounds (CR = 6.03:1 on #1C1C1E, 7.45:1 on #000000)
    public static var adaptiveErrorText: Color {
        #if canImport(UIKit)
        return Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 255.0 / 255, green: 105.0 / 255, blue: 97.0 / 255, alpha: 1.0)
                : UIColor(red: 183.0 / 255, green: 28.0 / 255, blue: 28.0 / 255, alpha: 1.0)
        })
        #elseif canImport(AppKit)
        return Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 255.0 / 255, green: 105.0 / 255, blue: 97.0 / 255, alpha: 1.0)
                : NSColor(red: 183.0 / 255, green: 28.0 / 255, blue: 28.0 / 255, alpha: 1.0)
        }))
        #else
        return Color(red: 183.0 / 255, green: 28.0 / 255, blue: 28.0 / 255)
        #endif
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
