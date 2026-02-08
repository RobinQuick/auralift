import Foundation

// MARK: - PersonaMode

/// Selectable voice/coaching personality that replaces the old VoicePack system.
enum PersonaMode: String, CaseIterable {
    case spartan = "spartan"
    case analyst = "analyst"
    case mentor = "mentor"

    var displayName: String {
        switch self {
        case .spartan: return "SPARTAN"
        case .analyst: return "ANALYST"
        case .mentor:  return "MENTOR"
        }
    }

    var description: String {
        switch self {
        case .spartan: return "Aggressive, short commands. No excuses."
        case .analyst: return "Data-driven readouts. Numbers speak."
        case .mentor:  return "Encouraging guidance. Build confidence."
        }
    }

    var iconName: String {
        switch self {
        case .spartan: return "shield.checkered"
        case .analyst: return "chart.bar.xaxis"
        case .mentor:  return "hand.thumbsup.fill"
        }
    }

    var voiceConfig: VoiceConfig {
        switch self {
        case .spartan: return .spartanWarrior
        case .analyst: return .soberCoach
        case .mentor:  return .esportAnnouncer
        }
    }
}

// MARK: - PersonaEngine

/// Manages voice persona selection and stealth mode logic.
/// Stealth mode hides weight/calories for 7 days when triggered by excessive logging.
final class PersonaEngine {

    // MARK: - Persona

    var currentPersona: PersonaMode {
        didSet {
            UserDefaults.standard.set(currentPersona.rawValue, forKey: "persona.mode")
        }
    }

    // MARK: - Stealth Mode

    /// When true, hide weight and calorie numbers from the UI for 7 days.
    var isStealthMode: Bool {
        guard let stealthStart = UserDefaults.standard.object(forKey: "persona.stealthStart") as? Date else {
            return false
        }
        let daysSinceStart = Calendar.current.dateComponents([.day], from: stealthStart, to: Date()).day ?? 0
        return daysSinceStart < 7
    }

    // MARK: - Init

    init() {
        let saved = UserDefaults.standard.string(forKey: "persona.mode") ?? ""
        self.currentPersona = PersonaMode(rawValue: saved) ?? .spartan
    }

    // MARK: - Voice Lines

    /// Returns a contextual voice line for the given event based on the active persona.
    func lineFor(event: PersonaEvent) -> String {
        let lines = PersonaLines.lines(for: currentPersona, event: event)
        return lines.randomElement() ?? event.fallback
    }

    // MARK: - Stealth Check

    /// If the user has logged more than 5 times today, activate stealth mode.
    func shouldEnterStealthMode(dailyLogCount: Int) -> Bool {
        if dailyLogCount > 5 {
            if !isStealthMode {
                UserDefaults.standard.set(Date(), forKey: "persona.stealthStart")
            }
            return true
        }
        return false
    }

    /// Manually exit stealth mode.
    func exitStealthMode() {
        UserDefaults.standard.removeObject(forKey: "persona.stealthStart")
    }
}

// MARK: - PersonaEvent

/// Events that trigger persona-specific voice lines.
enum PersonaEvent {
    case firstRep
    case perfectRep
    case excellentRep
    case comboMilestone(count: Int)
    case perfectSet
    case goodSet
    case averageSet
    case rankUp(tierName: String)
    case sessionStart
    case sessionEnd(xp: Int32, lp: Int32)
    case personalRecord
    case autoStop
    case majorSafety(issueName: String)
    case moderateSafety(issueName: String)

    var fallback: String {
        switch self {
        case .firstRep: return "Go."
        case .perfectRep: return "Perfect."
        case .excellentRep: return "Good."
        case .comboMilestone: return "Streak."
        case .perfectSet: return "Flawless set."
        case .goodSet: return "Solid set."
        case .averageSet: return "Set done."
        case .rankUp: return "Rank up."
        case .sessionStart: return "Begin."
        case .sessionEnd: return "Done."
        case .personalRecord: return "New record."
        case .autoStop: return "Auto-stop."
        case .majorSafety: return "Fix your form."
        case .moderateSafety: return "Adjust."
        }
    }
}

// MARK: - PersonaLines

/// Static voice line tables for each persona and event category.
enum PersonaLines {

    static func lines(for persona: PersonaMode, event: PersonaEvent) -> [String] {
        switch event {
        case .firstRep:
            return firstRepLines[persona] ?? []
        case .perfectRep:
            return perfectRepLines[persona] ?? []
        case .excellentRep:
            return excellentRepLines[persona] ?? []
        case .comboMilestone(let count):
            return comboLines(for: persona, count: count)
        case .perfectSet:
            return perfectSetLines[persona] ?? []
        case .goodSet:
            return goodSetLines[persona] ?? []
        case .averageSet:
            return averageSetLines[persona] ?? []
        case .rankUp(let tierName):
            return (rankUpLines[persona] ?? []).map { $0.replacingOccurrences(of: "{TIER}", with: tierName) }
        case .sessionStart:
            return sessionStartLines[persona] ?? []
        case .sessionEnd(let xp, let lp):
            return (sessionEndLines[persona] ?? []).map {
                $0.replacingOccurrences(of: "{XP}", with: "\(xp)")
                  .replacingOccurrences(of: "{LP}", with: "\(lp)")
            }
        case .personalRecord:
            return personalRecordLines[persona] ?? []
        case .autoStop:
            return autoStopLines[persona] ?? []
        case .majorSafety(let issue):
            return safetyLines(for: persona, issue: issue, major: true)
        case .moderateSafety(let issue):
            return safetyLines(for: persona, issue: issue, major: false)
        }
    }

    // MARK: - First Rep

    private static let firstRepLines: [PersonaMode: [String]] = [
        .spartan: ["Move.", "First strike.", "Go."],
        .analyst: ["Rep one logged. Baseline set.", "First data point captured.", "Tracking initiated."],
        .mentor:  ["Great start! Keep that energy.", "First rep — you've got this!", "Let's build from here."]
    ]

    // MARK: - Perfect Rep

    private static let perfectRepLines: [PersonaMode: [String]] = [
        .spartan: ["Flawless.", "Again.", "That's the standard."],
        .analyst: ["Form score: maximum. Textbook execution.", "Optimal range. Peak mechanics.", "Perfect biomechanics registered."],
        .mentor:  ["Beautiful form! That's exactly right.", "Incredible rep! Keep it up!", "You're in the zone — perfect!"]
    ]

    // MARK: - Excellent Rep

    private static let excellentRepLines: [PersonaMode: [String]] = [
        .spartan: ["Solid.", "Good.", "Continue."],
        .analyst: ["Above threshold. Solid rep.", "Good velocity and form.", "Clean data point."],
        .mentor:  ["Nice one! Feeling strong.", "Solid rep, keep going!", "That's great work."]
    ]

    // MARK: - Combo

    private static func comboLines(for persona: PersonaMode, count: Int) -> [String] {
        let tier: String
        if count >= 20 { tier = "legendary" }
        else if count >= 10 { tier = "elite" }
        else if count >= 5 { tier = "strong" }
        else { tier = "building" }

        switch persona {
        case .spartan:
            switch tier {
            case "legendary": return ["Unstoppable.", "Domination."]
            case "elite":     return ["Relentless.", "No mercy."]
            case "strong":    return ["Keep going.", "More."]
            default:          return ["Building.", "Stack them."]
            }
        case .analyst:
            return ["\(count)-rep streak. Consistency at \(tier) level.", "Combo x\(count). Statistical outlier."]
        case .mentor:
            switch tier {
            case "legendary": return ["Twenty perfect reps! You're incredible!", "This is legendary consistency!"]
            case "elite":     return ["Amazing streak! You're on fire!", "Elite consistency — be proud!"]
            case "strong":    return ["Five in a row! Keep this energy!", "Great streak building!"]
            default:          return ["Combo starting! Let's keep it rolling!", "You're finding your rhythm!"]
            }
        }
    }

    // MARK: - Set Complete

    private static let perfectSetLines: [PersonaMode: [String]] = [
        .spartan: ["Set: perfect. Next.", "Flawless execution. Rest."],
        .analyst: ["Set complete. Form score above 95th percentile.", "Excellent set quality. All metrics optimal."],
        .mentor:  ["What an amazing set! You crushed it!", "Flawless set! Take a well-earned rest."]
    ]

    private static let goodSetLines: [PersonaMode: [String]] = [
        .spartan: ["Done. Improve next set.", "Adequate. Push harder."],
        .analyst: ["Set logged. Form above average.", "Solid set. Metrics within target range."],
        .mentor:  ["Good set! Nice work out there.", "Solid effort! Let's build on that."]
    ]

    private static let averageSetLines: [PersonaMode: [String]] = [
        .spartan: ["Weak. Fix it.", "Not enough. Again."],
        .analyst: ["Set complete. Form below target. Focus on technique.", "Suboptimal metrics. Adjust next set."],
        .mentor:  ["Set done! Next one will be even better.", "You finished it — that's what matters. Let's improve."]
    ]

    // MARK: - Rank Up

    private static let rankUpLines: [PersonaMode: [String]] = [
        .spartan: ["Rank: {TIER}. Earn the next.", "{TIER} achieved. Keep climbing."],
        .analyst: ["Promotion confirmed: {TIER}. LP threshold exceeded.", "New tier: {TIER}. Statistical milestone reached."],
        .mentor:  ["Congratulations! Welcome to {TIER}! You've earned this!", "Amazing progress! You're now {TIER}!"]
    ]

    // MARK: - Session

    private static let sessionStartLines: [PersonaMode: [String]] = [
        .spartan: ["Begin.", "No excuses. Start.", "Execute."],
        .analyst: ["Session initiated. All systems tracking.", "Recording started. Metrics online."],
        .mentor:  ["Let's have a great session! You've got this!", "Ready? Let's make today count!"]
    ]

    private static let sessionEndLines: [PersonaMode: [String]] = [
        .spartan: ["Done. {XP} XP. {LP} LP. Dismissed.", "Session over. Results earned."],
        .analyst: ["Session complete. {XP} XP, {LP} LP recorded. Full report available.", "All data logged. {XP} XP earned."],
        .mentor:  ["Awesome session! {XP} XP earned and {LP} LP gained! Rest up!", "You did amazing today! {XP} XP in the bank!"]
    ]

    // MARK: - Personal Record

    private static let personalRecordLines: [PersonaMode: [String]] = [
        .spartan: ["New record. Don't stop.", "Record broken. Set a higher bar."],
        .analyst: ["Personal record achieved. New baseline established.", "New PR logged. Historical data updated."],
        .mentor:  ["NEW PERSONAL RECORD! I'm so proud of you!", "You just beat your best! Incredible!"]
    ]

    // MARK: - Auto-Stop

    private static let autoStopLines: [PersonaMode: [String]] = [
        .spartan: ["Stop. Velocity gone. Rest.", "Fatigue limit. Set over."],
        .analyst: ["Velocity loss exceeds 20%. Auto-stop engaged for safety.", "Fatigue threshold reached. Set terminated."],
        .mentor:  ["Smart stop — your body is telling you to rest. Great discipline!", "Auto-stop activated. Recovery is part of the process."]
    ]

    // MARK: - Safety

    private static func safetyLines(for persona: PersonaMode, issue: String, major: Bool) -> [String] {
        switch persona {
        case .spartan:
            return major
                ? ["Form breakdown. Fix it now.", "\(issue)! Correct immediately."]
                : ["Tighten up.", "Minor flaw. Fix it."]
        case .analyst:
            return major
                ? ["\(issue) detected. Deviation exceeds safe threshold. Correct immediately.", "Major form deviation: \(issue). Reduce load or reset."]
                : ["Minor \(issue) detected. Adjust alignment.", "Form deviation noted. Small correction needed."]
        case .mentor:
            return major
                ? ["Watch out — \(issue) detected! Let's fix that to stay safe.", "I see \(issue) — please adjust before continuing."]
                : ["Small adjustment needed — \(issue). You can fix that!", "Just a minor thing — watch your \(issue)."]
        }
    }
}
