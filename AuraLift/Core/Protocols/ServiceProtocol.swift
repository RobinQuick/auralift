import Foundation

/// Base protocol for all AUREA services.
/// Services encapsulate business logic and external integrations.
protocol ServiceProtocol {
    /// Whether the service has been initialized and is ready to use.
    var isAvailable: Bool { get }

    /// Perform any async setup required before use.
    func initialize() async throws
}

extension ServiceProtocol {
    var isAvailable: Bool { true }

    func initialize() async throws {
        // Default no-op implementation
    }
}
