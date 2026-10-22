import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {
    /// Adaptive secondary background color supporting iOS, iPadOS, and macOS previews/tests.
    public static var adaptiveSecondaryBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .secondarySystemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color.gray.opacity(0.12)
        #endif
    }
    
    /// Adaptive tertiary background color supporting iOS, iPadOS, and macOS previews/tests.
    public static var adaptiveTertiaryBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .tertiarySystemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color.gray.opacity(0.08)
        #endif
    }
}
