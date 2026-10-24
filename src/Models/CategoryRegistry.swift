import Foundation

/// Thread-safe in-memory registry for system and user-defined dynamic categories.
public final class CategoryRegistry: @unchecked Sendable {
    public static let shared = CategoryRegistry()
    private let lock = NSLock()
    private var customCategories: [String: QuizCategory] = [:]
    
    public init() {}
    
    /// Registers a custom or imported category.
    public func register(_ category: QuizCategory) {
        lock.lock()
        defer { lock.unlock() }
        customCategories[category.rawValue] = category
    }
    
    /// Registers multiple categories in bulk.
    public func register(contentsOf categories: [QuizCategory]) {
        lock.lock()
        defer { lock.unlock() }
        for category in categories {
            customCategories[category.rawValue] = category
        }
    }
    
    /// Removes a custom category from the registry.
    public func unregister(id: String) {
        lock.lock()
        defer { lock.unlock() }
        customCategories.removeValue(forKey: id)
    }
    
    /// Retrieves a category by its unique raw identifier if registered.
    public func category(for rawValue: String) -> QuizCategory? {
        lock.lock()
        defer { lock.unlock() }
        return customCategories[rawValue]
    }
    
    /// Returns all default system categories combined with registered custom categories.
    public var allCategories: [QuizCategory] {
        lock.lock()
        defer { lock.unlock() }
        var result = QuizCategory.defaultCategories
        for custom in customCategories.values {
            if !result.contains(where: { $0.rawValue == custom.rawValue }) {
                result.append(custom)
            }
        }
        return result
    }
    
    /// Returns only user-defined or imported custom categories.
    public var customCategoryList: [QuizCategory] {
        lock.lock()
        defer { lock.unlock() }
        return Array(customCategories.values)
    }
    
    /// Captures a thread-safe snapshot of all registered custom categories for transactional rollback.
    public func snapshot() -> [QuizCategory] {
        lock.lock()
        defer { lock.unlock() }
        return Array(customCategories.values)
    }
    
    /// Restores the registry's custom categories to a specified snapshot (used for transactional rollback).
    public func resetTo(_ categories: [QuizCategory]) {
        lock.lock()
        defer { lock.unlock() }
        customCategories.removeAll()
        for cat in categories where cat.isCustom {
            customCategories[cat.rawValue] = cat
        }
    }
    
    /// Resets the registry, clearing all custom categories while preserving system defaults.
    public func resetToDefaults() {
        lock.lock()
        defer { lock.unlock() }
        customCategories.removeAll()
    }
}
