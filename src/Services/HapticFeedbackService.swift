import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Discrete semantic categories for tactile feedback.
public enum HapticFeedbackType: String, CaseIterable, Equatable, Sendable {
    case success
    case error
    case warning
}

/// Abstract contract for delivering sensory tactile haptic feedback to the user.
///
/// Designed following the Dependency Inversion Principle (DIP) to decouple
/// domain view models and presentation components from hardware-specific UIKit APIs.
/// Enables deterministic unit testing via mock recorders across macOS and CI environments.
public protocol HapticFeedbackServiceProtocol: AnyObject, Sendable {
    /// Pre-warms the haptic hardware engine to minimize latency upon user interaction.
    func prepare()
    
    /// Triggers a distinct semantic haptic notification pattern.
    func trigger(_ type: HapticFeedbackType)
}

extension HapticFeedbackServiceProtocol {
    public func playSuccess() {
        trigger(.success)
    }
    
    public func playError() {
        trigger(.error)
    }
    
    public func playWarning() {
        trigger(.warning)
    }
}

/// Production implementation of `HapticFeedbackServiceProtocol` utilizing iOS `UINotificationFeedbackGenerator`.
///
/// Platform Compatibility:
/// On physical iOS devices supporting Taptic Engine, provides crisp sensory confirmation.
/// On iPad, Mac Catalyst, macOS test harnesses, or simulators where physical haptics are absent,
/// safely executes without crashes, errors, or runtime warnings.
public final class SystemHapticFeedbackService: HapticFeedbackServiceProtocol, @unchecked Sendable {
    
    public static let shared = SystemHapticFeedbackService()
    
    public init() {}
    
    public func prepare() {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
        }
        #endif
    }
    
    public func trigger(_ type: HapticFeedbackType) {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            switch type {
            case .success:
                generator.notificationOccurred(.success)
            case .error:
                generator.notificationOccurred(.error)
            case .warning:
                generator.notificationOccurred(.warning)
            }
        }
        #endif
    }
}

/// In-memory mock recording haptic invocations for deterministic unit and regression testing.
public final class MockHapticFeedbackService: HapticFeedbackServiceProtocol, @unchecked Sendable {
    public private(set) var triggerCount: Int = 0
    public private(set) var prepareCount: Int = 0
    public private(set) var recordedEvents: [HapticFeedbackType] = []
    
    public init() {}
    
    public func prepare() {
        prepareCount += 1
    }
    
    public func trigger(_ type: HapticFeedbackType) {
        triggerCount += 1
        recordedEvents.append(type)
    }
    
    public var lastEvent: HapticFeedbackType? {
        recordedEvents.last
    }
    
    public func reset() {
        triggerCount = 0
        prepareCount = 0
        recordedEvents.removeAll()
    }
}
