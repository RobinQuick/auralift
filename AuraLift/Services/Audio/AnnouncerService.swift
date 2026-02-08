import Foundation

// MARK: - VoicePack

/// Selectable voice personality for the workout announcer.
enum VoicePack: String, CaseIterable {
    case esportAnnouncer = "esportAnnouncer"
    case soberCoach = "soberCoach"
    case spartanWarrior = "spartanWarrior"

    var displayName: String {
        switch self {
        case .esportAnnouncer: return "E-Sport Announcer"
        case .soberCoach: return "Sober Coach"
        case .spartanWarrior: return "Spartan Warrior"
        }
    }

    var description: String {
        switch self {
        case .esportAnnouncer: return "High-energy competitive gaming caster"
        case .soberCoach: return "Calm, precise, science-based coaching"
        case .spartanWarrior: return "Ancient warrior battle commander"
        }
    }

    var iconName: String {
        switch self {
        case .esportAnnouncer: return "gamecontroller.fill"
        case .soberCoach: return "graduationcap.fill"
        case .spartanWarrior: return "shield.checkered"
        }
    }

    var voiceConfig: VoiceConfig {
        switch self {
        case .esportAnnouncer: return .esportAnnouncer
        case .soberCoach: return .soberCoach
        case .spartanWarrior: return .spartanWarrior
        }
    }
}

// MARK: - AnnouncerEvent

/// Events that trigger announcer voice lines and haptics.
enum AnnouncerEvent {
    case repCompleted(formScore: Double, velocity: Double, repNumber: Int)
    case comboMilestone(count: Int)
    case setCompleted(summary: SetSummary)
    case rankUp(newTier: RankTier)
    case safetyAlert(issue: FormIssue)
    case sessionStart
    case sessionEnd(totalXP: Int32, totalLP: Int32)
    case personalRecord(type: String)
    case velocityAutoStop
}

// MARK: - AnnouncerService

/// Triggers voice lines and haptic feedback during workouts based on performance events.
/// Implements per-category cooldown to prevent announcer spam.
final class AnnouncerService: ServiceProtocol {

    // MARK: - Dependencies

    private let audioManager: AudioManager
    private let hapticManager: HapticManager

    // MARK: - Settings

    let personaEngine = PersonaEngine()

    var activeVoicePack: VoicePack {
        didSet { UserDefaults.standard.set(activeVoicePack.rawValue, forKey: "announcer.voicePack") }
    }

    // MARK: - Cooldown State

    private var lastAnnouncementTime: Date = .distantPast
    private var lastComboTime: Date = .distantPast
    private var lastSafetyTimes: [String: Date] = [:]  // issue name → last time

    // MARK: - Cooldown Durations

    private let standardCooldown: TimeInterval = 2.0
    private let comboCooldown: TimeInterval = 3.0
    private let safetyCooldown: TimeInterval = 5.0

    // MARK: - ServiceProtocol

    var isAvailable: Bool { audioManager.isAvailable }

    func initialize() async throws {
        // No additional setup needed; depends on AudioManager being initialized
    }

    // MARK: - Init

    init(audioManager: AudioManager, hapticManager: HapticManager) {
        self.audioManager = audioManager
        self.hapticManager = hapticManager

        let saved = UserDefaults.standard.string(forKey: "announcer.voicePack") ?? ""
        self.activeVoicePack = VoicePack(rawValue: saved) ?? .esportAnnouncer
    }

    // MARK: - Main Entry Point

    func handleEvent(_ event: AnnouncerEvent) {
        switch event {
        case .repCompleted(let formScore, _, let repNumber):
            handleRepCompleted(formScore: formScore, repNumber: repNumber)
        case .comboMilestone(let count):
            handleComboMilestone(count: count)
        case .setCompleted(let summary):
            handleSetCompleted(summary: summary)
        case .rankUp(let newTier):
            handleRankUp(newTier: newTier)
        case .safetyAlert(let issue):
            handleSafetyAlert(issue: issue)
        case .sessionStart:
            handleSessionStart()
        case .sessionEnd(let totalXP, let totalLP):
            handleSessionEnd(totalXP: totalXP, totalLP: totalLP)
        case .personalRecord(let type):
            handlePersonalRecord(type: type)
        case .velocityAutoStop:
            handleAutoStop()
        }
    }

    // MARK: - Event Handlers

    private func handleRepCompleted(formScore: Double, repNumber: Int) {
        guard canAnnounce() else { return }

        let event: PersonaEvent
        if repNumber == 1 {
            event = .firstRep
        } else if formScore >= 97 {
            event = .perfectRep
        } else if formScore >= 90 {
            event = .excellentRep
        } else {
            // No announcement for average reps
            hapticManager.playRepFeedback(formScore: formScore)
            audioManager.playSFX(.repComplete)
            return
        }

        let line = personaEngine.lineFor(event: event)
        markAnnounced()
        speak(line, priority: .low)
        hapticManager.playRepFeedback(formScore: formScore)
        audioManager.playSFX(.repComplete)
    }

    private func handleComboMilestone(count: Int) {
        guard canAnnounceCombo() else { return }

        let line = personaEngine.lineFor(event: .comboMilestone(count: count))
        markComboAnnounced()
        speak(line, priority: .medium)
        hapticManager.playComboTick(count: count)
        audioManager.playSFX(.comboTick)
    }

    private func handleSetCompleted(summary: SetSummary) {
        let event: PersonaEvent
        if summary.averageFormScore >= 95 {
            event = .perfectSet
        } else if summary.averageFormScore >= 80 {
            event = .goodSet
        } else {
            event = .averageSet
        }

        let line = personaEngine.lineFor(event: event)
        // Set complete always plays (high priority, resets cooldown)
        markAnnounced()
        speak(line, priority: .high)
        hapticManager.playSetComplete(averageFormScore: summary.averageFormScore)
        audioManager.playSFX(.setComplete)
    }

    private func handleRankUp(newTier: RankTier) {
        let line = personaEngine.lineFor(event: .rankUp(tierName: newTier.displayName))

        speak(line, priority: .high)
        hapticManager.playRankUp()
        audioManager.playSFX(.rankUp)
    }

    private func handleSafetyAlert(issue: FormIssue) {
        // Safety cooldown is per-issue only: different issues always play
        let now = Date()
        if let lastTime = lastSafetyTimes[issue.name],
           now.timeIntervalSince(lastTime) < safetyCooldown {
            return
        }
        lastSafetyTimes[issue.name] = now

        let event: PersonaEvent
        if issue.severity == .major {
            event = .majorSafety(issueName: issue.name)
        } else {
            event = .moderateSafety(issueName: issue.name)
        }
        let line = personaEngine.lineFor(event: event)

        // Safety always plays, bypasses standard cooldown
        speak(line, priority: .safety)
        hapticManager.playSafetyAlert()
        audioManager.playSFX(.safetyAlert)
    }

    private func handleSessionStart() {
        let line = personaEngine.lineFor(event: .sessionStart)
        speak(line, priority: .high)
        hapticManager.lightTap()
    }

    private func handleSessionEnd(totalXP: Int32, totalLP: Int32) {
        let line = personaEngine.lineFor(event: .sessionEnd(xp: totalXP, lp: totalLP))
        speak(line, priority: .high)
        hapticManager.playSetComplete(averageFormScore: 100)
    }

    private func handlePersonalRecord(type: String) {
        let line = personaEngine.lineFor(event: .personalRecord)
        speak(line, priority: .high)
        hapticManager.playRankUp()
        audioManager.playSFX(.personalRecord)
    }

    private func handleAutoStop() {
        let line = personaEngine.lineFor(event: .autoStop)
        speak(line, priority: .high)
        hapticManager.playSafetyAlert()
    }

    // MARK: - Cooldown Logic

    private func canAnnounce() -> Bool {
        Date().timeIntervalSince(lastAnnouncementTime) >= standardCooldown
    }

    private func canAnnounceCombo() -> Bool {
        Date().timeIntervalSince(lastComboTime) >= comboCooldown
    }

    private func markAnnounced() {
        lastAnnouncementTime = Date()
    }

    private func markComboAnnounced() {
        lastComboTime = Date()
    }

    // MARK: - Speech Helper

    private func speak(_ text: String, priority: SpeechPriority) {
        audioManager.speak(text: text, priority: priority, voiceConfig: personaEngine.currentPersona.voiceConfig)
    }
}

// MARK: - VoicePackLines

/// Static voice line tables for each voice pack and event category.
enum VoicePackLines {

    // MARK: - First Rep

    private static let firstRepLines: [VoicePack: [String]] = [
        .esportAnnouncer: ["First blood!", "And we're off!", "Let's go!"],
        .soberCoach: ["Good first rep. Set the tempo.", "Clean start. Stay focused.", "First rep locked in."],
        .spartanWarrior: ["The battle begins!", "First strike!", "Steel meets iron!"]
    ]

    static func firstRep(for pack: VoicePack) -> String {
        firstRepLines[pack]?.randomElement() ?? "Let's go!"
    }

    // MARK: - Perfect Rep

    private static let perfectRepLines: [VoicePack: [String]] = [
        .esportAnnouncer: ["Legendary form!", "That was insane!", "Absolutely flawless!", "God-like precision!"],
        .soberCoach: ["Perfect execution.", "Textbook form.", "Optimal range of motion.", "Flawless mechanics."],
        .spartanWarrior: ["The gods approve!", "Worthy of Olympus!", "Spartan perfection!", "Glory!"]
    ]

    static func perfectRep(for pack: VoicePack) -> String {
        perfectRepLines[pack]?.randomElement() ?? "Perfect!"
    }

    // MARK: - Excellent Rep

    private static let excellentRepLines: [VoicePack: [String]] = [
        .esportAnnouncer: ["Nice one!", "Clean!", "Solid rep!", "That's how it's done!"],
        .soberCoach: ["Good rep.", "Solid form.", "Well controlled.", "Nice tempo."],
        .spartanWarrior: ["Strong!", "Well struck!", "A warrior's lift!", "Power!"]
    ]

    static func excellentRep(for pack: VoicePack) -> String {
        excellentRepLines[pack]?.randomElement() ?? "Nice!"
    }

    // MARK: - Combo Milestones

    private static let comboLines: [VoicePack: [Int: [String]]] = [
        .esportAnnouncer: [
            3:  ["Triple kill!", "Combo starting!"],
            5:  ["Penta kill!", "Five-streak! Unstoppable!"],
            8:  ["Dominating!", "On fire!"],
            10: ["Godlike!", "Legendary streak!"],
            15: ["Beyond legendary!", "Absolutely unreal!"],
            20: ["ULTRA KILL! Twenty perfect reps!", "History in the making!"]
        ],
        .soberCoach: [
            3:  ["Three clean reps. Good consistency.", "Solid streak of three."],
            5:  ["Five consecutive quality reps.", "Excellent consistency at five."],
            8:  ["Eight-rep streak. Impressive focus.", "Outstanding discipline."],
            10: ["Ten perfect reps. Elite consistency.", "Double digits. Remarkable."],
            15: ["Fifteen-rep streak. Extraordinary.", "Truly exceptional run."],
            20: ["Twenty clean reps. World-class control.", "Peak performance sustained."]
        ],
        .spartanWarrior: [
            3:  ["Three kills!", "The battle heats up!"],
            5:  ["Five foes vanquished!", "Unstoppable warrior!"],
            8:  ["Eight conquests!", "A true champion emerges!"],
            10: ["Ten victories! Legendary!", "The arena trembles!"],
            15: ["Fifteen! The gods watch in awe!", "Immortal performance!"],
            20: ["Twenty! You fight like a Titan!", "History will remember this!"]
        ]
    ]

    static func comboMilestone(for pack: VoicePack, count: Int) -> String {
        guard let packLines = comboLines[pack] else { return "Combo x\(count)!" }

        // Find the highest milestone threshold at or below count
        let thresholds = [20, 15, 10, 8, 5, 3]
        for threshold in thresholds {
            if count >= threshold, let lines = packLines[threshold] {
                return lines.randomElement() ?? "Combo x\(count)!"
            }
        }
        return "Combo x\(count)!"
    }

    // MARK: - Set Complete

    private static let perfectSetLines: [VoicePack: [String]] = [
        .esportAnnouncer: ["Flawless set! MVP performance!", "Set complete! That was championship level!"],
        .soberCoach: ["Excellent set. Near-perfect execution.", "Outstanding set quality."],
        .spartanWarrior: ["A set worthy of the gods!", "Glorious set! Sparta is proud!"]
    ]

    private static let goodSetLines: [VoicePack: [String]] = [
        .esportAnnouncer: ["Good set! Keep that energy!", "Set locked in! Let's go!"],
        .soberCoach: ["Solid set. Good work.", "Well-executed set overall."],
        .spartanWarrior: ["A strong set, warrior!", "The battle goes well!"]
    ]

    private static let averageSetLines: [VoicePack: [String]] = [
        .esportAnnouncer: ["Set done. Time to level up!", "Set complete. Let's clean it up next round!"],
        .soberCoach: ["Set complete. Focus on form for the next one.", "Room for improvement. Stay present."],
        .spartanWarrior: ["The set is done. Sharpen your blade!", "Rest now, fight harder next round!"]
    ]

    static func perfectSet(for pack: VoicePack) -> String {
        perfectSetLines[pack]?.randomElement() ?? "Perfect set!"
    }

    static func goodSet(for pack: VoicePack) -> String {
        goodSetLines[pack]?.randomElement() ?? "Good set!"
    }

    static func averageSet(for pack: VoicePack) -> String {
        averageSetLines[pack]?.randomElement() ?? "Set complete."
    }

    // MARK: - Rank Up

    private static let rankUpLines: [VoicePack: [String]] = [
        .esportAnnouncer: ["RANK UP! Welcome to {TIER}!", "PROMOTED! You've reached {TIER}! Let's go!"],
        .soberCoach: ["Promotion achieved. You are now {TIER}.", "Rank up to {TIER}. Well deserved."],
        .spartanWarrior: ["RANK UP! You have ascended to {TIER}!", "The arena crowns you {TIER}!"]
    ]

    static func rankUp(for pack: VoicePack) -> String {
        rankUpLines[pack]?.randomElement() ?? "RANK UP! Welcome to {TIER}!"
    }

    // MARK: - Safety: Major

    private static let majorSafetyLines: [VoicePack: [String: [String]]] = [
        .esportAnnouncer: [
            "Back Rounding": ["Watch your back! Dangerous rounding detected!", "Back rounding! Brace your core!"],
            "Excessive Lean": ["Too much lean! Risk of injury!", "Excessive forward lean! Pull back!"],
            "_default": ["Form breakdown! Fix it now!", "Critical form issue! Adjust immediately!"]
        ],
        .soberCoach: [
            "Back Rounding": ["Spinal flexion detected. Brace and reset.", "Back is rounding. Reduce load or fix position."],
            "Excessive Lean": ["Excessive trunk lean. Check your balance.", "Too much forward lean. Re-center."],
            "_default": ["Major form deviation. Please correct.", "Form issue detected. Prioritize safety."]
        ],
        .spartanWarrior: [
            "Back Rounding": ["Your back betrays you! Stand tall, warrior!", "The spine buckles! Brace yourself!"],
            "Excessive Lean": ["You lean like a falling tower! Stand firm!", "Regain your balance, soldier!"],
            "_default": ["Your form crumbles! Fight with discipline!", "A warrior does not break form!"]
        ]
    ]

    // MARK: - Safety: Moderate

    private static let moderateSafetyLines: [VoicePack: [String: [String]]] = [
        .esportAnnouncer: [
            "Knee Cave": ["Watch those knees! Push them out!", "Knees caving in! Stay wide!"],
            "Elbow Flare": ["Elbows flaring! Tuck them in!", "Control those elbows!"],
            "Kipping": ["Kipping detected! Strict reps only!", "No kipping! Clean reps!"],
            "_default": ["Minor form slip! Tighten up!", "Small adjustment needed!"]
        ],
        .soberCoach: [
            "Knee Cave": ["Knee valgus detected. Push knees over toes.", "Knees tracking inward. Correct alignment."],
            "Elbow Flare": ["Elbow flare noted. Tuck to 45 degrees.", "Elbows drifting wide. Maintain tuck."],
            "Kipping": ["Momentum detected. Use strict form.", "Control the eccentric. No swinging."],
            "_default": ["Minor form deviation. Make an adjustment.", "Small correction needed."]
        ],
        .spartanWarrior: [
            "Knee Cave": ["Knees! A Spartan stands wide!", "Your knees weaken! Push outward!"],
            "Elbow Flare": ["Elbows! Control your weapons!", "Tuck your elbows, warrior!"],
            "Kipping": ["No swinging! Fight with honor!", "Discipline! Strict reps only!"],
            "_default": ["Tighten your form, soldier!", "A small flaw. Correct it!"]
        ]
    ]

    static func majorSafety(for pack: VoicePack, issueName: String) -> String {
        guard let packLines = majorSafetyLines[pack] else { return "Form issue detected!" }
        let lines = packLines[issueName] ?? packLines["_default"] ?? ["Form issue detected!"]
        return lines.randomElement() ?? "Form issue detected!"
    }

    static func moderateSafety(for pack: VoicePack, issueName: String) -> String {
        guard let packLines = moderateSafetyLines[pack] else { return "Adjust your form." }
        let lines = packLines[issueName] ?? packLines["_default"] ?? ["Adjust your form."]
        return lines.randomElement() ?? "Adjust your form."
    }

    // MARK: - Session Start

    private static let sessionStartLines: [VoicePack: [String]] = [
        .esportAnnouncer: ["Welcome to the arena! Let's get this W!", "Game time! Show me what you've got!"],
        .soberCoach: ["Session starting. Focus on quality.", "Let's begin. Controlled reps, good form."],
        .spartanWarrior: ["Warriors! To the arena!", "Prepare for battle! Tonight we train!"]
    ]

    static func sessionStart(for pack: VoicePack) -> String {
        sessionStartLines[pack]?.randomElement() ?? "Let's go!"
    }

    // MARK: - Session End

    private static let sessionEndLines: [VoicePack: [String]] = [
        .esportAnnouncer: ["GG! {XP} XP earned, {LP} LP gained! See you next match!", "Session over! {XP} XP banked! What a performance!"],
        .soberCoach: ["Session complete. {XP} XP earned, {LP} LP gained. Good work.", "Training done. {XP} experience points logged."],
        .spartanWarrior: ["The battle is won! {XP} glory points earned! Rest now, warrior!", "Victory! {LP} honor points claimed! Sparta salutes you!"]
    ]

    static func sessionEnd(for pack: VoicePack) -> String {
        sessionEndLines[pack]?.randomElement() ?? "Session complete! {XP} XP earned!"
    }

    // MARK: - Personal Record

    private static let personalRecordLines: [VoicePack: [String]] = [
        .esportAnnouncer: ["NEW PERSONAL RECORD! You just leveled up!", "P.R. SMASHED! That's a new best!"],
        .soberCoach: ["Personal record achieved. Excellent progression.", "New personal best. Measurable improvement."],
        .spartanWarrior: ["A NEW RECORD! The legends will sing of this!", "You have surpassed yourself, warrior!"]
    ]

    static func personalRecord(for pack: VoicePack) -> String {
        personalRecordLines[pack]?.randomElement() ?? "New personal record!"
    }

    // MARK: - Auto-Stop

    private static let autoStopLines: [VoicePack: [String]] = [
        .esportAnnouncer: ["Velocity drop detected! Auto-stop triggered. Smart play!", "Fatigue limit reached! Set auto-completed!"],
        .soberCoach: ["Velocity loss exceeds threshold. Set terminated for safety.", "Auto-stop engaged. Recovery recommended."],
        .spartanWarrior: ["Your strength wanes! The set ends here, warrior!", "Even Spartans must rest! Auto-stop!"]
    ]

    static func autoStop(for pack: VoicePack) -> String {
        autoStopLines[pack]?.randomElement() ?? "Auto-stop triggered."
    }
}
