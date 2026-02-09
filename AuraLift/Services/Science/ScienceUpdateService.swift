import Foundation

/// Fetches the latest exercise science research summaries to keep training protocols current.
/// This service is intentionally unavailable until real backend endpoints are implemented.
final class ScienceUpdateService: ServiceProtocol {

    enum ScienceServiceError: Error {
        case notConfigured
    }

    var isAvailable: Bool { false }

    func initialize() async throws {
        throw ScienceServiceError.notConfigured
    }

    /// Fetches the latest research updates relevant to the user's training.
    func fetchLatestUpdates() async throws -> [[String: String]] {
        throw ScienceServiceError.notConfigured
    }

    /// Checks if any new research contradicts current training protocols.
    func checkForProtocolConflicts() async throws -> [String] {
        throw ScienceServiceError.notConfigured
    }
}
