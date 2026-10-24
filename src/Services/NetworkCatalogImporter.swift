import Foundation

/// Errors specific to network-based study material retrieval.
public enum NetworkCatalogError: LocalizedError, Equatable {
    case invalidURL
    case networkFailure(String)
    case invalidHTTPResponse(statusCode: Int)
    case emptyResponse
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The provided URL is invalid or malformed."
        case .networkFailure(let details):
            return "Failed to download study catalog from remote URL: \(details)"
        case .invalidHTTPResponse(let statusCode):
            return "Remote server returned an unsuccessful HTTP status code: \(statusCode)."
        case .emptyResponse:
            return "The remote server returned an empty response with no question data."
        }
    }
}

/// Abstract contract for fetching remote study materials via URLSession.
public protocol NetworkCatalogImporterProtocol: Sendable {
    /// Downloads raw data from a given web URL.
    func fetchCatalogData(from url: URL) async throws -> Data
}

/// Production implementation of `NetworkCatalogImporterProtocol` utilizing `URLSession`.
public final class NetworkCatalogImporter: NetworkCatalogImporterProtocol, @unchecked Sendable {
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func fetchCatalogData(from url: URL) async throws -> Data {
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            throw NetworkCatalogError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkCatalogError.invalidHTTPResponse(statusCode: httpResponse.statusCode)
                }
            }
            
            guard !data.isEmpty else {
                throw NetworkCatalogError.emptyResponse
            }
            
            return data
        } catch let error as NetworkCatalogError {
            throw error
        } catch {
            throw NetworkCatalogError.networkFailure(error.localizedDescription)
        }
    }
}
