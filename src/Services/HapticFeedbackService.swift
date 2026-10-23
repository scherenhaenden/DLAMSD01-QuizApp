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
/// Lifecycle & Pre-warming Architecture:
/// Retains a single `UINotificationFeedbackGenerator` instance across calls so that `prepare()`
/// places the Taptic Engine actuator into an active low-latency state. Apple's guidelines specify
/// that a generator's prepared state is forfeited once the generator object is deallocated;
/// by keeping a retained instance in memory, successive interactions benefit from preserved readiness.
///
/// Platform Compatibility:
/// On physical iOS devices supporting Taptic Engine, provides crisp sensory confirmation.
/// On iPad, Mac Catalyst, macOS test harnesses, or simulators where physical haptics are absent,
/// safely executes without crashes, errors, or runtime warnings.
public final class SystemHapticFeedbackService: HapticFeedbackServiceProtocol, @unchecked Sendable {
    
    public static let shared = SystemHapticFeedbackService()
    
    #if os(iOS) && !targetEnvironment(macCatalyst)
    private var generator: UINotificationFeedbackGenerator?
    private let lock = NSLock()
    #endif
    
    public init() {}
    
    /// Pre-warms the Taptic Engine using a retained generator instance.
    public func prepare() {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lock.lock()
            if self.generator == nil {
                self.generator = UINotificationFeedbackGenerator()
            }
            let currentGen = self.generator
            self.lock.unlock()
            currentGen?.prepare()
        }
        #endif
    }
    
    /// Triggers the requested notification pattern on the retained generator instance.
    public func trigger(_ type: HapticFeedbackType) {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lock.lock()
            let feedbackGenerator: UINotificationFeedbackGenerator
            if let existing = self.generator {
                feedbackGenerator = existing
            } else {
                feedbackGenerator = UINotificationFeedbackGenerator()
                self.generator = feedbackGenerator
            }
            self.lock.unlock()
            
            switch type {
            case .success:
                feedbackGenerator.notificationOccurred(.success)
            case .error:
                feedbackGenerator.notificationOccurred(.error)
            case .warning:
                feedbackGenerator.notificationOccurred(.warning)
            }
            
            // Re-arm the generator for upcoming interactions
            feedbackGenerator.prepare()
        }
        #endif
    }
    
    /// Inspects whether a generator instance is currently retained in memory.
    public var hasRetainedGenerator: Bool {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        lock.lock()
        defer { lock.unlock() }
        return generator != nil
        #else
        return false
        #endif
    }
    
    /// Clears the retained generator instance (used for resetting state between tests).
    public func clearPreparedGenerator() {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lock.lock()
            self.generator = nil
            self.lock.unlock()
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
