import Foundation

/// Thread-safe persistence service storing score records in `UserDefaults` (ADR-07).
///
/// Implements `ScoreStoreProtocol` by serializing an array of `ScoreRecord` value objects
/// into a compact JSON data blob. Enforces a maximum retention capacity (default: 100)
/// to maintain low memory footprints and fast access on mobile devices.
public final class UserDefaultsScoreStore: ScoreStoreProtocol, @unchecked Sendable {
    /// Default user defaults key for quiz score records.
    public static let defaultStorageKey = "com.trainyourbrain.scores.history"
    
    /// Maximum number of records retained in storage to prevent unbounded growth.
    public let maxCapacity: Int
    
    private let userDefaults: UserDefaults
    private let storageKey: String
    private let lock = NSLock()
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    /// Initializes a new score store with a target UserDefaults instance and key.
    ///
    /// - Parameters:
    ///   - userDefaults: Target `UserDefaults` database (defaults to `.standard`).
    ///   - storageKey: Unique key identifying the stored payload.
    ///   - maxCapacity: Maximum number of records to retain (defaults to 100).
    public init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = defaultStorageKey,
        maxCapacity: Int = 100
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        self.maxCapacity = max(1, maxCapacity)
        
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        self.encoder = enc
        
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }
    
    // MARK: - ScoreStoreProtocol Implementation
    
    public func save(record: ScoreRecord) throws {
        lock.lock()
        defer { lock.unlock() }
        
        var records = internalLoadRecords()
        // Prepend new record to maintain newest-first order
        records.insert(record, at: 0)
        
        // Enforce capacity while strictly preserving all-time personal bests (US-13)
        UserDefaultsScoreStore.pruneRecordsWithBestProtection(&records, maxCapacity: maxCapacity)
        
        do {
            let data = try encoder.encode(records)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            throw ScoreStoreError.encodingFailed(error.localizedDescription)
        }
    }
    
    public func loadRecords() -> [ScoreRecord] {
        lock.lock()
        defer { lock.unlock() }
        return internalLoadRecords()
    }
    
    public func loadHighScores(limit: Int = 50) -> [ScoreRecord] {
        let all = loadRecords()
        let sorted = all.sorted(by: >)
        return Array(sorted.prefix(max(0, limit)))
    }
    
    public func bestScore(for category: QuizCategory?) -> ScoreRecord? {
        let all = loadRecords()
        let matching = all.filter { record in
            if let target = category {
                return record.category == target
            }
            return true
        }
        return matching.max()
    }
    
    public func clearAll() throws {
        lock.lock()
        defer { lock.unlock() }
        userDefaults.removeObject(forKey: storageKey)
    }
    
    // MARK: - Private Helpers
    
    /// Prunes excess records beyond `maxCapacity`, guaranteeing that all-time personal bests
    /// (overall and for each individual category) are strictly protected against eviction (US-13).
    internal static func pruneRecordsWithBestProtection(_ records: inout [ScoreRecord], maxCapacity: Int) {
        guard records.count > maxCapacity else { return }
        
        var protectedIDs = Set<UUID>()
        if let globalBest = records.max() {
            protectedIDs.insert(globalBest.id)
        }
        for cat in QuizCategory.allCases {
            if let catBest = records.filter({ $0.category == cat }).max() {
                protectedIDs.insert(catBest.id)
            }
        }
        
        // Prune from oldest (at the end), sparing protected records
        var index = records.count - 1
        while records.count > maxCapacity && index >= 0 {
            if !protectedIDs.contains(records[index].id) {
                records.remove(at: index)
            }
            index -= 1
        }
        
        // Final boundary: if protected records alone exceed maxCapacity, retain top-scoring records (canonical Comparable)
        if records.count > maxCapacity {
            records = Array(records.sorted(by: >).prefix(maxCapacity))
        }
    }
    
    private func internalLoadRecords() -> [ScoreRecord] {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return []
        }
        
        do {
            let records = try decoder.decode([ScoreRecord].self, from: data)
            // Sort chronologically descending
            return records.sorted { $0.completedAt > $1.completedAt }
        } catch {
            // Defensive recovery: if payload is corrupted, clear to prevent persistent crash
            userDefaults.removeObject(forKey: storageKey)
            return []
        }
    }
}

/// In-memory mock implementation of `ScoreStoreProtocol` for isolated, ultra-fast unit testing.
public final class InMemoryScoreStore: ScoreStoreProtocol, @unchecked Sendable {
    private var records: [ScoreRecord] = []
    private let lock = NSLock()
    public let maxCapacity: Int
    
    public init(initialRecords: [ScoreRecord] = [], maxCapacity: Int = 100) {
        self.records = initialRecords
        self.maxCapacity = max(1, maxCapacity)
    }
    
    public func save(record: ScoreRecord) throws {
        lock.lock()
        defer { lock.unlock() }
        records.insert(record, at: 0)
        UserDefaultsScoreStore.pruneRecordsWithBestProtection(&records, maxCapacity: maxCapacity)
    }
    
    public func loadRecords() -> [ScoreRecord] {
        lock.lock()
        defer { lock.unlock() }
        return records.sorted { $0.completedAt > $1.completedAt }
    }
    
    public func loadHighScores(limit: Int = 50) -> [ScoreRecord] {
        let all = loadRecords()
        let sorted = all.sorted(by: >)
        return Array(sorted.prefix(max(0, limit)))
    }
    
    public func bestScore(for category: QuizCategory?) -> ScoreRecord? {
        let all = loadRecords()
        let matching = all.filter { record in
            if let target = category {
                return record.category == target
            }
            return true
        }
        return matching.max()
    }
    
    public func clearAll() throws {
        lock.lock()
        defer { lock.unlock() }
        records.removeAll()
    }
}
