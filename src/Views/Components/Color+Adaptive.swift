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
        return Color(nsColor: adaptiveSuccessNSColor)
        #else
        return Color(red: 27.0 / 255, green: 94.0 / 255, blue: 32.0 / 255)
        #endif
    }

    #if canImport(AppKit)
    public static var adaptiveSuccessNSColor: NSColor {
        NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 48.0 / 255, green: 209.0 / 255, blue: 88.0 / 255, alpha: 1.0)
                : NSColor(red: 27.0 / 255, green: 94.0 / 255, blue: 32.0 / 255, alpha: 1.0)
        })
    }
    #endif

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
        return Color(nsColor: adaptiveErrorNSColor)
        #else
        return Color(red: 183.0 / 255, green: 28.0 / 255, blue: 28.0 / 255)
        #endif
    }

    #if canImport(AppKit)
    public static var adaptiveErrorNSColor: NSColor {
        NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 255.0 / 255, green: 105.0 / 255, blue: 97.0 / 255, alpha: 1.0)
                : NSColor(red: 183.0 / 255, green: 28.0 / 255, blue: 28.0 / 255, alpha: 1.0)
        })
    }
    #endif

    /// Adaptive amber/gold icon color providing >= 4.5:1 (AA) contrast:
    /// - Light mode: Deep amber `#B45309` (CR = 5.58:1 on white, 5.01:1 on canvas)
    /// - Dark mode: Warm golden yellow `#FBBF24` (CR = 9.82:1 on #1C1C1E, 12.38:1 on #000000)
    public static var adaptiveScoreIcon: Color {
        #if canImport(UIKit)
        return Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 251.0 / 255, green: 191.0 / 255, blue: 36.0 / 255, alpha: 1.0)
                : UIColor(red: 180.0 / 255, green: 83.0 / 255, blue: 9.0 / 255, alpha: 1.0)
        })
        #elseif canImport(AppKit)
        return Color(nsColor: adaptiveScoreNSColor)
        #else
        return Color(red: 180.0 / 255, green: 83.0 / 255, blue: 9.0 / 255)
        #endif
    }

    #if canImport(AppKit)
    public static var adaptiveScoreNSColor: NSColor {
        NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 251.0 / 255, green: 191.0 / 255, blue: 36.0 / 255, alpha: 1.0)
                : NSColor(red: 180.0 / 255, green: 83.0 / 255, blue: 9.0 / 255, alpha: 1.0)
        })
    }
    #endif

    /// Adaptive flame/orange icon color providing >= 4.5:1 (AA) contrast:
    /// - Light mode: Burnt orange `#C2410C` (CR = 6.03:1 on white, 5.41:1 on canvas)
    /// - Dark mode: Bright coral orange `#FB923C` (CR = 7.25:1 on #1C1C1E, 9.14:1 on #000000)
    public static var adaptiveStreakIcon: Color {
        #if canImport(UIKit)
        return Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 251.0 / 255, green: 146.0 / 255, blue: 60.0 / 255, alpha: 1.0)
                : UIColor(red: 194.0 / 255, green: 65.0 / 255, blue: 12.0 / 255, alpha: 1.0)
        })
        #elseif canImport(AppKit)
        return Color(nsColor: adaptiveStreakNSColor)
        #else
        return Color(red: 194.0 / 255, green: 65.0 / 255, blue: 12.0 / 255)
        #endif
    }

    #if canImport(AppKit)
    public static var adaptiveStreakNSColor: NSColor {
        NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 251.0 / 255, green: 146.0 / 255, blue: 60.0 / 255, alpha: 1.0)
                : NSColor(red: 194.0 / 255, green: 65.0 / 255, blue: 12.0 / 255, alpha: 1.0)
        })
    }
    #endif

    /// Adaptive timer/speed blue icon color providing >= 4.5:1 (AA) contrast:
    /// - Light mode: Rich cobalt blue `#1D4ED8` (CR = 6.73:1 on white, 6.03:1 on canvas)
    /// - Dark mode: Sky cyan `#38BDF8` (CR = 8.55:1 on #1C1C1E, 10.78:1 on #000000)
    public static var adaptiveSpeedIcon: Color {
        #if canImport(UIKit)
        return Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 56.0 / 255, green: 189.0 / 255, blue: 248.0 / 255, alpha: 1.0)
                : UIColor(red: 29.0 / 255, green: 78.0 / 255, blue: 216.0 / 255, alpha: 1.0)
        })
        #elseif canImport(AppKit)
        return Color(nsColor: adaptiveSpeedNSColor)
        #else
        return Color(red: 29.0 / 255, green: 78.0 / 255, blue: 216.0 / 255)
        #endif
    }

    #if canImport(AppKit)
    public static var adaptiveSpeedNSColor: NSColor {
        NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 56.0 / 255, green: 189.0 / 255, blue: 248.0 / 255, alpha: 1.0)
                : NSColor(red: 29.0 / 255, green: 78.0 / 255, blue: 216.0 / 255, alpha: 1.0)
        })
    }
    #endif

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
