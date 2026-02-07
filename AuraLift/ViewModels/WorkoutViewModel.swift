import Foundation
import CoreData
import SwiftUI
import Combine

// MARK: - SetSummary

/// Lightweight summary of a completed set for display in the HUD and SetTrackerView.
struct SetSummary: Identifiable {
    let id = UUID()
    let setNumber: Int
    let reps: Int
    let weightKg: Double
    let averageFormScore: Double
    let averageVelocity: Double
    let peakVelocity: Double
    let velocityLossPercent: Double
    let romDegrees: Double
    let barPathDeviation: Double
    let eccentricDuration: TimeInterval
    let concentricDuration: TimeInterval
    let rpe: Double
    let xpEarned: Int32
    let autoStopped: Bool
    let velocityZone: VelocityZone
}

// MARK: - WorkoutViewModel

@MainActor
class WorkoutViewModel: ObservableObject {

    // MARK: - Session State

    @Published var isSessionActive: Bool = false
    @Published var showExercisePicker: Bool = false
    @Published var showSessionSummary: Bool = false

    // MARK: - Exercise State

    @Published var selectedExercise: Exercise?
    @Published var currentExerciseName: String = ""

    // MARK: - Set State

    @Published var currentSetNumber: Int = 1
    @Published var currentWeight: Double = 0
    @Published var completedSets: [SetSummary] = []

    // MARK: - Rep State (forwarded from RepCounter)

    @Published var repCount: Int = 0
    @Published var currentFormScore: Double = 0
    @Published var currentROM: Double = 0
    @Published var currentPhase: RepPhase = .idle
    @Published var activeFormIssues: [FormIssue] = []

    // MARK: - Velocity State (forwarded from VBTService)

    @Published var currentVelocity: Double = 0
    @Published var currentConcentricVelocity: Double = 0
    @Published var velocityLossPercent: Double = 0
    @Published var shouldAutoStop: Bool = false
    @Published var estimatedRIR: Int? = nil

    // MARK: - Session Aggregates

    @Published var sessionVolume: Double = 0
    @Published var sessionXP: Int32 = 0
    @Published var comboCount: Int = 0
    @Published var averageFormScore: Double = 0
    @Published var sessionPeakVelocity: Double = 0

    // MARK: - Pipeline Objects

    let cameraManager: CameraManager
    let poseAnalysisManager: PoseAnalysisManager
    let frameProcessor: FrameProcessor
    let formAnalyzer: FormAnalyzer
    let repCounter: RepCounter
    let vbtService: VBTService
    let rpeCalculator: RPECalculator
    let rankingEngine: RankingEngine

    // MARK: - Audio Pipeline

    let audioManager: AudioManager
    let hapticManager: HapticManager
    let announcerService: AnnouncerService
    let bpmSyncEngine: BPMSyncEngine

    // MARK: - Ghost Mode

    let ghostModeManager: GhostModeManager
    @Published var ghostPoseFrame: PoseFrame?
    @Published var isGhostModeEnabled: Bool = false
    @Published var lpParticles: [LPParticle] = []

    // MARK: - Ranking State

    @Published var workoutLP: Int32 = 0
    @Published var promotionStatus: PromotionStatus?

    // MARK: - Premium Gating

    private let premiumManager = PremiumManager.shared
    @Published var showPaywall: Bool = false

    var canAccessVBT: Bool { premiumManager.isPro }
    var canAccessGhostMode: Bool { premiumManager.isPro }

    // MARK: - CoreData

    private let context: NSManagedObjectContext
    private var currentSession: WorkoutSession?

    // MARK: - Combine

    private var cancellables = Set<AnyCancellable>()
    private var repEventsThisSet: [RepEvent] = []
    private var allFormScores: [Double] = []

    // MARK: - Init

    init(context: NSManagedObjectContext) {
        self.context = context

        // Create pipeline
        let camera = CameraManager()
        let pose = PoseAnalysisManager()
        let processor = FrameProcessor(cameraManager: camera, poseAnalysisManager: pose)
        let analyzer = FormAnalyzer()
        let vbt = VBTService()
        let rpe = RPECalculator()
        let ranking = RankingEngine()
        let counter = RepCounter(formAnalyzer: analyzer, vbtService: vbt)

        self.cameraManager = camera
        self.poseAnalysisManager = pose
        self.frameProcessor = processor
        self.formAnalyzer = analyzer
        self.vbtService = vbt
        self.rpeCalculator = rpe
        self.rankingEngine = ranking
        self.repCounter = counter

        // Create audio pipeline
        let audio = AudioManager()
        let haptic = HapticManager()
        let announcer = AnnouncerService(audioManager: audio, hapticManager: haptic)
        let bpm = BPMSyncEngine()

        self.audioManager = audio
        self.hapticManager = haptic
        self.announcerService = announcer
        self.bpmSyncEngine = bpm

        // Create ghost mode pipeline
        self.ghostModeManager = GhostModeManager()

        setupSubscriptions()
        setupRepCallback()
        calibrateVBT()
    }

    // MARK: - Subscriptions

    private func setupSubscriptions() {
        // Subscribe to pose frames and feed them through RepCounter
        poseAnalysisManager.$currentPoseFrame
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] frame in
                self?.handlePoseFrame(frame)
            }
            .store(in: &cancellables)

        // Forward RepCounter published state (using sink to avoid retain cycles)
        repCounter.$repCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in self?.repCount = count }
            .store(in: &cancellables)

        repCounter.$currentFormScore
            .receive(on: DispatchQueue.main)
            .sink { [weak self] score in self?.currentFormScore = score }
            .store(in: &cancellables)

        repCounter.$currentROM
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rom in self?.currentROM = rom }
            .store(in: &cancellables)

        repCounter.$currentPhase
            .receive(on: DispatchQueue.main)
            .sink { [weak self] phase in self?.currentPhase = phase }
            .store(in: &cancellables)

        repCounter.$activeFormIssues
            .receive(on: DispatchQueue.main)
            .sink { [weak self] issues in self?.activeFormIssues = issues }
            .store(in: &cancellables)

        // Forward VBTService published state
        vbtService.$currentVelocity
            .receive(on: DispatchQueue.main)
            .sink { [weak self] vel in self?.currentVelocity = vel }
            .store(in: &cancellables)

        vbtService.$currentConcentricVelocity
            .receive(on: DispatchQueue.main)
            .sink { [weak self] vel in self?.currentConcentricVelocity = vel }
            .store(in: &cancellables)

        // Forward ghost mode state (using sink to avoid retain cycles with assign(to:))
        ghostModeManager.$ghostPoseFrame
            .receive(on: DispatchQueue.main)
            .sink { [weak self] frame in
                self?.ghostPoseFrame = frame
            }
            .store(in: &cancellables)

        ghostModeManager.$isGhostModeEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.isGhostModeEnabled = enabled
            }
            .store(in: &cancellables)

        ghostModeManager.$lpParticles
            .receive(on: DispatchQueue.main)
            .sink { [weak self] particles in
                self?.lpParticles = particles
            }
            .store(in: &cancellables)

        // Safety alerts: announce major form issues immediately
        repCounter.$activeFormIssues
            .receive(on: DispatchQueue.main)
            .sink { [weak self] issues in
                guard let self else { return }
                for issue in issues where issue.severity == .major {
                    self.announcerService.handleEvent(.safetyAlert(issue: issue))
                }
            }
            .store(in: &cancellables)
    }

    private func setupRepCallback() {
        repCounter.onRepCompleted = { [weak self] event in
            DispatchQueue.main.async {
                self?.handleRepCompleted(event)
            }
        }
    }

    // MARK: - VBT Calibration

    private func calibrateVBT() {
        // Attempt to load user height from CoreData for VBT calibration
        let request = NSFetchRequest<NSManagedObject>(entityName: "UserProfile")
        request.fetchLimit = 1
        if let profile = try? context.fetch(request).first,
           let heightCm = profile.value(forKey: "heightCm") as? Double,
           heightCm > 0 {
            vbtService.calibrateDefault(userHeightCm: heightCm)
        }
    }

    // MARK: - Frame Processing

    private func handlePoseFrame(_ frame: PoseFrame) {
        guard selectedExercise != nil else { return }
        repCounter.processFrame(frame)

        // Update ghost overlay if enabled
        if ghostModeManager.isGhostModeEnabled {
            ghostModeManager.updateForPhase(currentPhase, anchorFrame: frame)
            ghostModeManager.cleanupExpiredParticles()
        }
    }

    // MARK: - Rep Completion

    private func handleRepCompleted(_ event: RepEvent) {
        repEventsThisSet.append(event)
        allFormScores.append(event.formScore)

        // Update combo
        if event.formScore >= 90 {
            comboCount += 1
        } else {
            comboCount = 0
        }

        // Update session average form score
        averageFormScore = allFormScores.reduce(0, +) / Double(allFormScores.count)

        // Update fatigue status from VBTService
        let fatigue = vbtService.fatigueStatus()
        velocityLossPercent = fatigue.velocityLossPercent
        shouldAutoStop = fatigue.shouldAutoStop
        estimatedRIR = rpeCalculator.estimateRIR(velocityLoss: fatigue.velocityLossPercent)

        // Update session peak velocity
        sessionPeakVelocity = vbtService.sessionPeakVelocity

        // Audio announcements
        announcerService.handleEvent(.repCompleted(
            formScore: event.formScore,
            velocity: event.meanConcentricVelocity,
            repNumber: event.repNumber
        ))

        if comboCount >= 3 {
            announcerService.handleEvent(.comboMilestone(count: comboCount))
        }

        // BPM tracking
        bpmSyncEngine.recordRepTimestamp()
        bpmSyncEngine.updateIntensity(velocityLossPercent: velocityLossPercent)

        // Auto-stop announcement
        if shouldAutoStop {
            announcerService.handleEvent(.velocityAutoStop)
        }

        // Spawn LP particle near root joint
        ghostModeManager.addLPParticle(
            value: Int32(event.repNumber) * 3,
            nearJoint: .root,
            frame: poseAnalysisManager.currentPoseFrame,
            viewSize: CGSize(width: 390, height: 844)
        )
    }

    // MARK: - Pipeline Lifecycle

    func initializePipeline() async {
        do {
            try await frameProcessor.initialize()
        } catch {
            // Permission denied or configuration failure handled by CameraManager published state
        }

        // Initialize audio pipeline (non-fatal if audio setup fails)
        try? await audioManager.initialize()
        try? await hapticManager.initialize()
        try? await announcerService.initialize()
        try? await bpmSyncEngine.initialize()

        // Initialize ghost mode pipeline
        try? await ghostModeManager.initialize()

        // Sync haptic enable state from AudioManager settings
        hapticManager.isEnabled = audioManager.hapticsEnabled
    }

    // MARK: - Session Control

    func startSession() {
        let session = WorkoutSession(context: context)
        currentSession = session

        isSessionActive = true
        currentSetNumber = 1
        completedSets = []
        sessionVolume = 0
        sessionXP = 0
        comboCount = 0
        averageFormScore = 0
        allFormScores = []
        repEventsThisSet = []
        velocityLossPercent = 0
        shouldAutoStop = false
        estimatedRIR = nil
        sessionPeakVelocity = 0
        workoutLP = 0
        promotionStatus = nil

        vbtService.resetForNewSession()
        frameProcessor.start()

        // Ghost mode
        ghostModeManager.stopGhostMode()

        // Audio
        bpmSyncEngine.reset()
        announcerService.handleEvent(.sessionStart)
    }

    func endSession() {
        frameProcessor.stop()
        ghostModeManager.stopGhostMode()

        // Finalize session in CoreData
        if let session = currentSession {
            session.endTime = Date()
            session.totalVolume = sessionVolume
            session.totalXPEarned = sessionXP
            session.averageFormScore = averageFormScore
            session.peakVelocity = sessionPeakVelocity

            do {
                try context.save()
            } catch {
                // Data remains in memory if save fails
            }
        }

        // Calculate LP and record ranking
        calculateAndRecordLP()

        // Cyber-Streak: record activity for today
        CyberStreakManager.shared.recordActivity()

        // Season XP: session XP + consistency bonus, multiplied by streak
        let consistencyBonus = calculateConsistencyBonus()
        let streakMultiplier = CyberStreakManager.shared.xpMultiplier
        let totalSeasonXP = Int64(Double(Int64(sessionXP) + consistencyBonus) * streakMultiplier)
        SeasonEngine.shared.addXP(totalSeasonXP, context: context)

        // Daily Quests: report workout stats
        let totalReps = completedSets.reduce(0) { $0 + $1.reps }
        DailyQuestManager.shared.recordWorkoutCompletion(
            totalVolume: sessionVolume,
            avgFormScore: averageFormScore,
            totalReps: totalReps,
            peakVelocity: sessionPeakVelocity,
            totalSets: completedSets.count,
            context: context
        )

        // Audio announcements
        if let promotion = promotionStatus, promotion.isPromoted, let newTier = promotion.newTier {
            announcerService.handleEvent(.rankUp(newTier: newTier))
        }
        announcerService.handleEvent(.sessionEnd(totalXP: sessionXP, totalLP: workoutLP))

        isSessionActive = false
        showSessionSummary = true
    }

    // MARK: - Consistency Bonus

    private func calculateConsistencyBonus() -> Int64 {
        let calendar = Calendar.current
        let now = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return 0 }

        let request = NSFetchRequest<WorkoutSession>(entityName: "WorkoutSession")
        request.predicate = NSPredicate(format: "startTime >= %@", weekAgo as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]

        guard let sessions = try? context.fetch(request) else { return 0 }

        // Count consecutive days with workouts (including today)
        var consecutiveDays = 0
        var checkDate = calendar.startOfDay(for: now)

        for _ in 0..<7 {
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: checkDate) ?? checkDate
            let hasSession = sessions.contains { session in
                guard let start = session.startTime else { return false }
                return start >= checkDate && start < dayEnd
            }
            if hasSession {
                consecutiveDays += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }

        return Int64(consecutiveDays) * 50
    }

    // MARK: - Ranking Integration

    private func calculateAndRecordLP() {
        guard !completedSets.isEmpty else { return }

        // Load user profile for bodyweight and biologicalSex
        let profileRequest = NSFetchRequest<UserProfile>(entityName: "UserProfile")
        profileRequest.fetchLimit = 1
        guard let profile = try? context.fetch(profileRequest).first,
              profile.weightKg > 0 else { return }

        let bodyweight = profile.weightKg
        let biologicalSex = profile.biologicalSex

        // Build set tuples for RankingEngine
        let setData: [(weight: Double, reps: Int, velocity: Double, formScore: Double)] =
            completedSets.map { set in
                (weight: set.weightKg,
                 reps: set.reps,
                 velocity: set.averageVelocity,
                 formScore: set.averageFormScore)
            }

        // Calculate LP
        let (totalLP, _) = rankingEngine.calculateWorkoutLP(
            sets: setData,
            bodyweight: bodyweight,
            biologicalSex: biologicalSex
        )
        workoutLP = totalLP

        // Determine new tier
        let currentTierString = profile.currentRankTier
        let currentTier = RankTier(rawValue: currentTierString) ?? .iron
        let newCumulativeLP = profile.currentLP + totalLP
        let newTier = rankingEngine.determineTier(totalLP: newCumulativeLP)

        // Process promotion series
        let promotion = rankingEngine.processPromotionSeries(
            workoutLP: totalLP,
            currentTier: currentTier,
            cumulativeLP: newCumulativeLP
        )
        promotionStatus = promotion

        let effectiveTier = promotion.isPromoted ? (promotion.newTier ?? newTier) : currentTier

        // Compute averages for snapshot
        let avgRatio = setData.map { $0.weight / bodyweight }.reduce(0, +) / max(1, Double(setData.count))
        let avgForm = setData.map(\.formScore).reduce(0, +) / max(1, Double(setData.count))
        let avgVelocity = setData.map(\.velocity).reduce(0, +) / max(1, Double(setData.count))

        // Update user profile
        profile.currentLP = newCumulativeLP
        profile.currentRankTier = effectiveTier.rawValue
        profile.updatedAt = Date()

        // Create ranking record
        let record = RankingRecord(context: context)
        record.id = UUID()
        record.recordDate = Date()
        record.tier = effectiveTier.rawValue
        record.lpAtRecord = newCumulativeLP
        record.strengthToWeightRatio = avgRatio
        record.formQualityAverage = avgForm
        record.velocityScore = avgVelocity
        record.userProfile = profile

        do {
            try context.save()
        } catch {
            context.rollback()
        }
    }

    // MARK: - Exercise Selection

    func selectExercise(_ exercise: Exercise) {
        selectedExercise = exercise
        currentExerciseName = exercise.name

        // Configure all services for this exercise
        formAnalyzer.configure(for: exercise.name)
        repCounter.configure(for: exercise.name)
        vbtService.configure(for: exercise.name)

        // Configure ghost mode with latest morpho data
        let segments = loadLatestSegmentMeasurements()
        ghostModeManager.startGhostMode(
            for: exercise.name,
            segments: segments,
            referenceFrame: poseAnalysisManager.currentPoseFrame
        )
    }

    // MARK: - Set Control

    func finishSet() {
        guard !repEventsThisSet.isEmpty else { return }

        let reps = repEventsThisSet.count
        let avgForm = repEventsThisSet.map(\.formScore).reduce(0, +) / Double(reps)
        let avgROM = repEventsThisSet.map(\.romDegrees).reduce(0, +) / Double(reps)
        let avgBarPath = repEventsThisSet.map(\.barPathDeviation).reduce(0, +) / Double(reps)
        let avgConcentricDuration = repEventsThisSet.map(\.concentricDuration).reduce(0, +) / Double(reps)
        let avgEccentricDuration = repEventsThisSet.map(\.eccentricDuration).reduce(0, +) / Double(reps)

        // Real velocity from VBTService (via RepEvent)
        let avgVelocity = repEventsThisSet.map(\.meanConcentricVelocity).reduce(0, +) / Double(reps)
        let peakVel = repEventsThisSet.map(\.peakConcentricVelocity).max() ?? 0

        // Fatigue metrics
        let fatigue = vbtService.fatigueStatus()
        let rpe = rpeCalculator.estimateRPE(
            velocityLoss: fatigue.velocityLossPercent,
            exerciseName: currentExerciseName
        )

        // Velocity zone from average velocity
        let zone = VelocityZone.from(velocity: avgVelocity)

        // Calculate XP: base 10/rep + form bonus + combo bonus
        let baseXP: Int32 = Int32(reps) * 10
        let formBonus: Int32 = avgForm >= 90 ? Int32(Double(baseXP) * 0.5) :
                               avgForm >= 70 ? Int32(Double(baseXP) * 0.2) : 0
        let comboBonus: Int32 = Int32(min(comboCount, 10)) * 5
        let setXP = baseXP + formBonus + comboBonus

        let summary = SetSummary(
            setNumber: currentSetNumber,
            reps: reps,
            weightKg: currentWeight,
            averageFormScore: avgForm,
            averageVelocity: avgVelocity,
            peakVelocity: peakVel,
            velocityLossPercent: fatigue.velocityLossPercent,
            romDegrees: avgROM,
            barPathDeviation: avgBarPath,
            eccentricDuration: avgEccentricDuration,
            concentricDuration: avgConcentricDuration,
            rpe: rpe,
            xpEarned: setXP,
            autoStopped: fatigue.shouldAutoStop,
            velocityZone: zone
        )
        completedSets.append(summary)

        // Announce set completion
        announcerService.handleEvent(.setCompleted(summary: summary))

        // Persist WorkoutSet to CoreData
        saveWorkoutSet(summary: summary, fatigue: fatigue, rpe: rpe, peakVel: peakVel)

        // Update session aggregates
        sessionVolume += Double(reps) * currentWeight
        sessionXP += setXP
        sessionPeakVelocity = vbtService.sessionPeakVelocity

        // Advance to next set
        currentSetNumber += 1
        repEventsThisSet = []
        velocityLossPercent = 0
        shouldAutoStop = false
        estimatedRIR = nil
        repCounter.reset()
        repCounter.configure(for: currentExerciseName)
        vbtService.resetForNewSet()
        vbtService.configure(for: currentExerciseName)
    }

    // MARK: - CoreData Persistence

    private func saveWorkoutSet(summary: SetSummary, fatigue: FatigueStatus, rpe: Double, peakVel: Double) {
        let workoutSet = WorkoutSet(context: context)
        workoutSet.setNumber = Int16(summary.setNumber)
        workoutSet.reps = Int16(summary.reps)
        workoutSet.weightKg = summary.weightKg
        workoutSet.formScore = summary.averageFormScore
        workoutSet.romDegrees = summary.romDegrees
        workoutSet.barPathDeviation = summary.barPathDeviation
        workoutSet.tempoActualConcentric = summary.concentricDuration
        workoutSet.tempoActualEccentric = summary.eccentricDuration
        workoutSet.averageConcentricVelocity = summary.averageVelocity
        workoutSet.peakConcentricVelocity = peakVel
        workoutSet.velocityLossPercent = fatigue.velocityLossPercent
        workoutSet.autoStopped = fatigue.shouldAutoStop
        workoutSet.rpe = rpe
        workoutSet.xpEarned = summary.xpEarned
        workoutSet.comboTag = comboCount >= 3 ? "x\(comboCount)" : nil

        // Relationships
        workoutSet.exercise = selectedExercise
        workoutSet.workoutSession = currentSession

        // Add to session's ordered set
        if let session = currentSession {
            let mutableSets = session.workoutSets?.mutableCopy() as? NSMutableOrderedSet ?? NSMutableOrderedSet()
            mutableSets.add(workoutSet)
            session.workoutSets = mutableSets
        }

        do {
            try context.save()
        } catch {
            // Data remains in memory if save fails
        }
    }

    // MARK: - Weight Input

    func setWeight(_ weight: Double) {
        currentWeight = weight
    }

    // MARK: - Ghost Mode

    func toggleGhostMode() {
        guard canAccessGhostMode else {
            showPaywall = true
            return
        }
        if ghostModeManager.isGhostModeEnabled {
            ghostModeManager.stopGhostMode()
        } else if !currentExerciseName.isEmpty {
            let segments = loadLatestSegmentMeasurements()
            ghostModeManager.startGhostMode(
                for: currentExerciseName,
                segments: segments,
                referenceFrame: poseAnalysisManager.currentPoseFrame
            )
        }
    }

    private func loadLatestSegmentMeasurements() -> SegmentMeasurements? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "MorphoScan")
        request.sortDescriptors = [NSSortDescriptor(key: "scanDate", ascending: false)]
        request.fetchLimit = 1

        guard let scan = try? context.fetch(request).first,
              let rawData = scan.value(forKey: "rawPoseData") as? Data,
              let heightCm = scan.value(forKey: "estimatedHeightCm") as? Double,
              heightCm > 0 else {
            return nil
        }

        // Deserialize pose data and recompute segments
        guard let dict = try? JSONSerialization.jsonObject(with: rawData) as? [String: [String: Double]] else {
            return nil
        }

        // Reconstruct averaged keypoints from stored data
        var keypoints: [JointName: CGPoint] = [:]
        for (jointRaw, coords) in dict {
            guard let joint = JointName(rawValue: jointRaw),
                  let x = coords["x"],
                  let y = coords["y"] else { continue }
            keypoints[joint] = CGPoint(x: x, y: y)
        }

        // Build a synthetic PoseFrame from stored data
        var poseKeypoints: [JointName: PoseKeypoint] = [:]
        for (joint, point) in keypoints {
            poseKeypoints[joint] = PoseKeypoint(joint: joint, position: point, confidence: 1.0)
        }
        let frame = PoseFrame(keypoints: poseKeypoints, timestamp: 0)

        let scanner = MorphoScannerService()
        return scanner.computeMeasurements(frames: [frame], heightCm: heightCm)
    }

    // MARK: - Dismiss Summary

    func dismissSummary() {
        showSessionSummary = false
        currentSession = nil
        selectedExercise = nil
        currentExerciseName = ""
        audioManager.stopAll()
        repCounter.onRepCompleted = nil
    }
}
