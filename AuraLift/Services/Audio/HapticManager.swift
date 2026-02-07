import UIKit

// MARK: - HapticManager

/// Manages haptic feedback for workout events using pre-warmed UIFeedbackGenerators.
/// All methods dispatch to @MainActor as UIFeedbackGenerator requires main thread.
final class HapticManager: ServiceProtocol {

    // MARK: - Generators

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    // MARK: - State

    private(set) var isAvailable: Bool = true
    var isEnabled: Bool = true

    // MARK: - ServiceProtocol

    func initialize() async throws {
        await prepareAll()
    }

    // MARK: - Prepare

    @MainActor
    private func prepareAll() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        notification.prepare()
        selection.prepare()
    }

    // MARK: - Rep Feedback

    /// Haptic on rep completion, intensity based on form score.
    /// - formScore >= 95: medium impact
    /// - formScore >= 80: light impact
    /// - below 80: no haptic
    func playRepFeedback(formScore: Double) {
        guard isEnabled else { return }
        Task { @MainActor in
            if formScore >= 95 {
                mediumImpact.impactOccurred()
                mediumImpact.prepare()
            } else if formScore >= 80 {
                lightImpact.impactOccurred()
                lightImpact.prepare()
            }
        }
    }

    // MARK: - Light Tap

    func lightTap() {
        guard isEnabled else { return }
        Task { @MainActor in
            selection.selectionChanged()
            selection.prepare()
        }
    }

    // MARK: - Combo Tick

    /// Escalating haptic for combo streaks: light at 3, medium at 5, heavy at 10+.
    func playComboTick(count: Int) {
        guard isEnabled else { return }
        Task { @MainActor in
            if count >= 10 {
                heavyImpact.impactOccurred()
                heavyImpact.prepare()
            } else if count >= 5 {
                mediumImpact.impactOccurred()
                mediumImpact.prepare()
            } else {
                lightImpact.impactOccurred()
                lightImpact.prepare()
            }
        }
    }

    // MARK: - Set Complete

    /// Double-tap pattern: heavy impact + notification success after 120ms.
    func playSetComplete(averageFormScore: Double) {
        guard isEnabled else { return }
        Task { @MainActor in
            heavyImpact.impactOccurred()
            heavyImpact.prepare()

            try? await Task.sleep(nanoseconds: 120_000_000) // 120ms
            notification.notificationOccurred(.success)
            notification.prepare()
        }
    }

    // MARK: - Rank Up

    /// Triple-hit escalating: light → medium → heavy → notification success at 100ms intervals.
    func playRankUp() {
        guard isEnabled else { return }
        Task { @MainActor in
            lightImpact.impactOccurred()
            lightImpact.prepare()

            try? await Task.sleep(nanoseconds: 100_000_000)
            mediumImpact.impactOccurred()
            mediumImpact.prepare()

            try? await Task.sleep(nanoseconds: 100_000_000)
            heavyImpact.impactOccurred()
            heavyImpact.prepare()

            try? await Task.sleep(nanoseconds: 100_000_000)
            notification.notificationOccurred(.success)
            notification.prepare()
        }
    }

    // MARK: - Safety Alert

    /// Warning + error haptic at 200ms interval for form safety issues.
    func playSafetyAlert() {
        guard isEnabled else { return }
        Task { @MainActor in
            notification.notificationOccurred(.warning)
            notification.prepare()

            try? await Task.sleep(nanoseconds: 200_000_000)
            notification.notificationOccurred(.error)
            notification.prepare()
        }
    }
}
