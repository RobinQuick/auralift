import Foundation
import CoreData

// MARK: - ParetoProgramBuilder

/// Generates 12-week periodized programs using strict Pareto (80/20) volume allocation.
/// Priority muscles get ~80% of weekly sets, maintenance muscles get ~20%.
/// Applies anti-bullshit filtering, machine intelligence, and morpho-specific swaps.
final class ParetoProgramBuilder {

    // MARK: - Volume Config

    private struct VolumeConfig {
        let totalWeeklySets: Int
        let prioritySetsRatio: Double // 0.80 = Pareto 80/20
        let maxSessionMinutes: Int

        static let fullBody3 = VolumeConfig(totalWeeklySets: 18, prioritySetsRatio: 0.80, maxSessionMinutes: 60)
        static let upperLower4 = VolumeConfig(totalWeeklySets: 24, prioritySetsRatio: 0.80, maxSessionMinutes: 60)
    }

    // MARK: - Morpho Context

    /// Passed through exercise selection and Why message generation.
    struct MorphoContext {
        let morphotype: Morphotype?
        let measurements: SegmentMeasurements?
        let sex: String
        let goal: AestheticGoal
    }

    // MARK: - Generate Program

    func generateProgram(
        frequency: ProgramFrequency,
        aestheticGoal: AestheticGoal,
        gymProfile: GymProfile,
        userProfile: UserProfile,
        morphotype: Morphotype?,
        measurements: SegmentMeasurements?,
        context: NSManagedObjectContext
    ) -> TrainingProgram {
        let program = TrainingProgram(context: context)
        program.name = "\(aestheticGoal.displayName) — \(frequency.displayName)"
        program.frequency = frequency.rawValue
        program.aestheticGoal = aestheticGoal.rawValue
        program.gymProfileId = gymProfile.id
        program.morphotypeAtCreation = morphotype?.rawValue
        program.userProfile = userProfile
        program.startDate = nextMonday()
        program.endDate = Calendar.current.date(byAdding: .weekOfYear, value: 12, to: program.startDate)

        let config = frequency == .fullBody3 ? VolumeConfig.fullBody3 : VolumeConfig.upperLower4
        let sex = userProfile.biologicalSex ?? "male"
        let morphoCtx = MorphoContext(morphotype: morphotype, measurements: measurements, sex: sex, goal: aestheticGoal)

        let priorityExercises = selectExercises(
            for: aestheticGoal.priorityMuscles,
            priority: true,
            gymProfile: gymProfile,
            morphoCtx: morphoCtx,
            context: context
        )
        let maintenanceExercises = selectExercises(
            for: aestheticGoal.maintenanceMuscles,
            priority: false,
            gymProfile: gymProfile,
            morphoCtx: morphoCtx,
            context: context
        )

        let weeksMutable = NSMutableOrderedSet()
        for weekNum in 1...12 {
            let weekType = ProgramWeekType.type(for: weekNum)
            let week = buildWeek(
                weekNumber: weekNum,
                weekType: weekType,
                frequency: frequency,
                priorityExercises: priorityExercises,
                maintenanceExercises: maintenanceExercises,
                config: config,
                startDate: program.startDate,
                morphoCtx: morphoCtx,
                context: context
            )
            week.trainingProgram = program
            weeksMutable.add(week)
        }
        program.weeks = weeksMutable

        return program
    }

    // MARK: - Exercise Selection

    func selectExercises(
        for muscles: [String],
        priority: Bool,
        gymProfile: GymProfile,
        morphoCtx: MorphoContext,
        context: NSManagedObjectContext
    ) -> [Exercise] {
        let equipment = gymProfile.equipmentList
        let brands = gymProfile.brandList
        let isHomeGym = isHomeGymOnly(equipment: equipment)
        var result: [Exercise] = []

        for muscle in muscles {
            let request = NSFetchRequest<Exercise>(entityName: "Exercise")
            request.predicate = NSPredicate(format: "primaryMuscle ==[c] %@", muscle)
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            guard let candidates = try? context.fetch(request), !candidates.isEmpty else {
                continue
            }

            // Step 1: Anti-bullshit filter
            let filtered = applyAntiBullshitFilter(
                candidates: candidates,
                goal: morphoCtx.goal,
                sex: morphoCtx.sex,
                morphotype: morphoCtx.morphotype
            )
            guard !filtered.isEmpty else { continue }

            // Step 2: Filter by available equipment
            let available = filtered.filter { ex in
                guard let eqType = ex.equipmentType else { return true }
                return equipment.isEmpty || equipment.contains(eqType)
            }
            guard !available.isEmpty else {
                // Fallback: take first filtered candidate
                if let first = filtered.first { result.append(first) }
                continue
            }

            // Step 3: Machine intelligence — prefer branded machine if available
            var chosen: Exercise
            if let machineMatch = findBrandedMachine(
                candidates: available,
                brands: brands,
                muscle: muscle,
                context: context
            ) {
                chosen = machineMatch
            } else if isHomeGym {
                // Home gym: prefer dumbbell exercises
                chosen = available.first { $0.equipmentType == "dumbbell" } ?? available[0]
            } else {
                chosen = available[0]
            }

            // Step 4: Morpho-swap
            if let morpho = morphoCtx.morphotype, let measures = morphoCtx.measurements {
                if let swapped = morphoSwap(
                    exercise: chosen,
                    morphotype: morpho,
                    measurements: measures,
                    sex: morphoCtx.sex,
                    availableEquipment: equipment,
                    brands: brands,
                    context: context
                ) {
                    chosen = swapped
                }
            }

            result.append(chosen)

            // Priority muscles: add a second exercise (stretch position preferred)
            if priority, available.count > 1 {
                let second = available.first { $0.id != chosen.id && $0.stretchPositionBonus } ??
                             available.first { $0.id != chosen.id }
                if let second { result.append(second) }
            }
        }

        return result
    }

    // MARK: - Anti-Bullshit Filter

    /// Removes useless exercises that waste time. Female-specific: ban heavy
    /// oblique/rotation work (thickens waist) — prefer Vacuum and planking.
    private func applyAntiBullshitFilter(
        candidates: [Exercise],
        goal: AestheticGoal,
        sex: String,
        morphotype: Morphotype?
    ) -> [Exercise] {
        let banned = goal.bannedExercises
        let isFemale = sex.lowercased() == "female"

        return candidates.filter { ex in
            let name = ex.name.lowercased()

            // Global banned list (shrugs, forearm isolation, etc.)
            for ban in banned {
                if name.contains(ban.lowercased()) { return false }
            }

            // Female-specific: ban heavy oblique/rotation movements
            if isFemale {
                let waistThickeners = ["oblique", "rotation", "woodchop", "side bend"]
                for term in waistThickeners {
                    if name.contains(term) { return false }
                }
            }

            return true
        }
    }

    // MARK: - Machine Intelligence

    /// If a branded machine (e.g. Pure Kraft Shoulder Press) targets the same muscle,
    /// prefer it over the barbell equivalent (better force curve, guided motion).
    private func findBrandedMachine(
        candidates: [Exercise],
        brands: [String],
        muscle: String,
        context: NSManagedObjectContext
    ) -> Exercise? {
        guard !brands.isEmpty else { return nil }

        // Look for machine exercises that have a linked MachineSpec with a matching brand
        for candidate in candidates {
            guard candidate.equipmentType == "machine" else { continue }

            // Check if this exercise has a MachineSpec with one of our gym's brands
            let specRequest = NSFetchRequest<NSManagedObject>(entityName: "MachineSpec")
            specRequest.predicate = NSPredicate(format: "exercise == %@", candidate)
            specRequest.fetchLimit = 1

            guard let spec = try? context.fetch(specRequest).first,
                  let brand = spec.value(forKey: "brand") as? String,
                  brands.contains(where: { $0.lowercased() == brand.lowercased() }) else {
                continue
            }

            return candidate
        }

        return nil
    }

    // MARK: - Morpho Swap

    func morphoSwap(
        exercise: Exercise,
        morphotype: Morphotype,
        measurements: SegmentMeasurements,
        sex: String,
        availableEquipment: [String],
        brands: [String],
        context: NSManagedObjectContext
    ) -> Exercise? {
        let name = exercise.name.lowercased()

        // Long arms → ban Barbell Bench → DB Bench (better amplitude + safety)
        if (morphotype == .longArms || morphotype == .longLimbed),
           name.contains("barbell bench") || (name.contains("bench press") && !name.contains("dumbbell")) {
            return findAlternative(
                primaryMuscle: exercise.primaryMuscle ?? "Chest",
                preferredEquipment: ["dumbbell", "machine"],
                preferredNames: ["dumbbell bench", "db bench", "incline db"],
                availableEquipment: availableEquipment,
                excluding: exercise.id,
                context: context
            )
        }

        // Long arms → Military Press barbell is risky → prefer DB OHP or machine
        if (morphotype == .longArms || morphotype == .longLimbed),
           name.contains("military press") || name.contains("overhead press barbell") {
            return findAlternative(
                primaryMuscle: exercise.primaryMuscle ?? "Shoulders",
                preferredEquipment: ["dumbbell", "machine"],
                preferredNames: ["dumbbell shoulder", "db overhead", "shoulder press machine"],
                availableEquipment: availableEquipment,
                excluding: exercise.id,
                context: context
            )
        }

        // Long femurs → ban full Back Squat → Leg Press or Bulgarian Split Squat
        // AureaBrain threshold: 0.85 for strict ban (via evaluateMorphoConstraints)
        if morphotype == .longLimbed || measurements.femurToTorsoRatio > 0.85,
           name.contains("back squat") || name == "squat" {
            return findAlternative(
                primaryMuscle: exercise.primaryMuscle ?? "Quads",
                preferredEquipment: ["machine", "dumbbell"],
                preferredNames: ["leg press", "bulgarian", "split squat", "front squat"],
                availableEquipment: availableEquipment,
                excluding: exercise.id,
                context: context
            )
        }

        // Short torso → Heavy Squat → Hip Thrust / RDL priority
        if morphotype == .shortTorso,
           name.contains("squat") && !name.contains("front") && !name.contains("split") {
            return findAlternative(
                primaryMuscle: "Glutes",
                preferredEquipment: availableEquipment,
                preferredNames: ["hip thrust", "rdl", "romanian"],
                availableEquipment: availableEquipment,
                excluding: exercise.id,
                context: context
            )
        }

        // Long torso → Deadlift with high injury risk → Trap Bar or RDL
        if morphotype == .longTorso,
           name.contains("deadlift") && !name.contains("romanian") && !name.contains("rdl") {
            return findAlternative(
                primaryMuscle: exercise.primaryMuscle ?? "Hamstrings",
                preferredEquipment: availableEquipment,
                preferredNames: ["trap bar", "rdl", "romanian deadlift"],
                availableEquipment: availableEquipment,
                excluding: exercise.id,
                context: context
            )
        }

        // Short arms → Dips can be awkward → prefer Machine Chest Press
        if morphotype == .shortArms,
           name.contains("dip") {
            return findAlternative(
                primaryMuscle: exercise.primaryMuscle ?? "Chest",
                preferredEquipment: ["machine", "cable"],
                preferredNames: ["chest press", "cable fly"],
                availableEquipment: availableEquipment,
                excluding: exercise.id,
                context: context
            )
        }

        return nil
    }

    // MARK: - Week Builder

    private func buildWeek(
        weekNumber: Int,
        weekType: ProgramWeekType,
        frequency: ProgramFrequency,
        priorityExercises: [Exercise],
        maintenanceExercises: [Exercise],
        config: VolumeConfig,
        startDate: Date,
        morphoCtx: MorphoContext,
        context: NSManagedObjectContext
    ) -> ProgramWeek {
        let week = ProgramWeek(context: context)
        week.weekNumber = Int16(weekNumber)
        week.weekType = weekType.rawValue
        week.volumeModifier = weekType.volumeModifier
        week.intensityModifier = weekType.intensityModifier

        let weekStart = Calendar.current.date(byAdding: .weekOfYear, value: weekNumber - 1, to: startDate) ?? startDate
        let daysMutable = NSMutableOrderedSet()

        for dayIdx in 0..<7 {
            let dayDate = Calendar.current.date(byAdding: .day, value: dayIdx, to: weekStart)
            let isTraining = frequency.trainingDayIndices.contains(dayIdx)
            let label = frequency.weekDayLabels[dayIdx]

            let day = ProgramDay(context: context)
            day.dayIndex = Int16(dayIdx)
            day.dayLabel = label
            day.scheduledDate = dayDate
            day.isRestDay = !isTraining
            day.programWeek = week

            if isTraining {
                let allocation = allocateExercisesForDay(
                    dayIndex: dayIdx,
                    frequency: frequency,
                    priorityExercises: priorityExercises,
                    maintenanceExercises: maintenanceExercises,
                    weekType: weekType,
                    config: config,
                    morphoCtx: morphoCtx,
                    context: context
                )
                let exMutable = NSMutableOrderedSet()
                for (order, progEx) in allocation.enumerated() {
                    progEx.exerciseOrder = Int16(order)
                    progEx.programDay = day
                    exMutable.add(progEx)
                }
                day.exercises = exMutable
                day.estimatedDurationMinutes = Int16(estimateSessionDuration(exercises: allocation))
            }

            daysMutable.add(day)
        }

        week.days = daysMutable
        return week
    }

    // MARK: - Volume Allocation

    private func allocateExercisesForDay(
        dayIndex: Int,
        frequency: ProgramFrequency,
        priorityExercises: [Exercise],
        maintenanceExercises: [Exercise],
        weekType: ProgramWeekType,
        config: VolumeConfig,
        morphoCtx: MorphoContext,
        context: NSManagedObjectContext
    ) -> [ProgramExercise] {
        var result: [ProgramExercise] = []
        let setsPerSession = Int(Double(config.totalWeeklySets) / Double(frequency.daysPerWeek) * weekType.volumeModifier)
        let prioritySets = Int(Double(setsPerSession) * config.prioritySetsRatio)
        let maintenanceSets = setsPerSession - prioritySets

        // Priority exercises: 80% of volume
        let pExercises = distributeForDay(dayIndex: dayIndex, exercises: priorityExercises, frequency: frequency)
        for exercise in pExercises {
            let setsEach = max(2, prioritySets / max(1, pExercises.count))
            let progEx = buildProgramExercise(
                exercise: exercise,
                sets: setsEach,
                weekType: weekType,
                isPriority: true,
                morphoCtx: morphoCtx,
                context: context
            )
            result.append(progEx)
        }

        // Maintenance exercises: 20% of volume
        let mExercises = distributeForDay(dayIndex: dayIndex, exercises: maintenanceExercises, frequency: frequency)
        for exercise in mExercises {
            let setsEach = max(2, maintenanceSets / max(1, mExercises.count))
            let progEx = buildProgramExercise(
                exercise: exercise,
                sets: setsEach,
                weekType: weekType,
                isPriority: false,
                morphoCtx: morphoCtx,
                context: context
            )
            result.append(progEx)
        }

        return result
    }

    private func distributeForDay(dayIndex: Int, exercises: [Exercise], frequency: ProgramFrequency) -> [Exercise] {
        guard !exercises.isEmpty else { return [] }

        switch frequency {
        case .fullBody3:
            let trainIdx = frequency.trainingDayIndices.firstIndex(of: dayIndex) ?? 0
            let perDay = max(1, exercises.count / 3)
            let start = trainIdx * perDay
            let end = min(start + perDay + 1, exercises.count)
            guard start < exercises.count else { return [exercises[0]] }
            return Array(exercises[start..<end])

        case .upperLower4:
            let trainIdx = frequency.trainingDayIndices.firstIndex(of: dayIndex) ?? 0
            let isUpper = trainIdx % 2 == 0
            let filtered = exercises.filter { ex in
                let muscle = (ex.primaryMuscle ?? "").lowercased()
                let upperMuscles = ["chest", "upper chest", "lats", "side delts", "rear delts",
                                    "traps", "biceps", "triceps", "upper back", "shoulders"]
                let isUpperMuscle = upperMuscles.contains { muscle.contains($0.lowercased()) }
                return isUpper ? isUpperMuscle : !isUpperMuscle
            }
            return filtered.isEmpty ? [exercises[0]] : filtered
        }
    }

    // MARK: - Program Exercise Builder

    private func buildProgramExercise(
        exercise: Exercise,
        sets: Int,
        weekType: ProgramWeekType,
        isPriority: Bool,
        morphoCtx: MorphoContext,
        context: NSManagedObjectContext
    ) -> ProgramExercise {
        let progEx = ProgramExercise(context: context)
        progEx.exercise = exercise
        progEx.targetSets = Int16(sets)
        progEx.targetReps = isPriority ? "8-12" : "10-15"
        progEx.targetRPE = weekType == .deload ? 5.0 : (weekType == .ramp ? 6.5 : 7.5)
        progEx.targetVelocityZone = VelocityZone.strength.rawValue
        progEx.restSeconds = isPriority ? 120 : 90
        progEx.tempoDescription = weekType == .deload ? "4-1-2" : "3-1-2"

        // Morpho-specific "Why" message
        progEx.whyMessage = generateWhyMessage(
            exercise: exercise,
            isPriority: isPriority,
            weekType: weekType,
            morphoCtx: morphoCtx
        )
        progEx.priorityReason = isPriority ? priorityReason(for: exercise, goal: morphoCtx.goal) : nil

        return progEx
    }

    // MARK: - Morpho-Specific Why Messages

    private func generateWhyMessage(
        exercise: Exercise,
        isPriority: Bool,
        weekType: ProgramWeekType,
        morphoCtx: MorphoContext
    ) -> String {
        let muscle = exercise.primaryMuscle ?? "this muscle"
        let name = exercise.name
        let equipType = exercise.equipmentType ?? "bodyweight"

        // Build morpho-specific explanation
        var morphoNote = ""

        if let morpho = morphoCtx.morphotype, let measures = morphoCtx.measurements {
            morphoNote = morphoExplanation(
                exerciseName: name,
                equipmentType: equipType,
                muscle: muscle,
                morphotype: morpho,
                measurements: measures,
                sex: morphoCtx.sex
            )
        }

        // Phase-specific base message
        let phaseMessage: String
        if isPriority {
            switch weekType {
            case .ramp:
                phaseMessage = "\(muscle) is a priority. Ramp-up phase: learning the movement at lighter loads."
            case .normal:
                phaseMessage = "\(muscle) gets 80% volume priority — maximum growth stimulus."
            case .overload:
                phaseMessage = "Overload phase: pushing \(muscle) beyond normal capacity for adaptation."
            case .deload:
                phaseMessage = "Recovery week: light work to maintain \(muscle) without accumulating fatigue."
            }
        } else {
            phaseMessage = "Maintenance volume for \(muscle) — preserving balance with minimal sets (20%)."
        }

        if morphoNote.isEmpty {
            return phaseMessage
        }
        return "\(morphoNote) \(phaseMessage)"
    }

    /// Generates a morpho-specific explanation for why THIS exercise was chosen.
    private func morphoExplanation(
        exerciseName: String,
        equipmentType: String,
        muscle: String,
        morphotype: Morphotype,
        measurements: SegmentMeasurements,
        sex: String
    ) -> String {
        let name = exerciseName.lowercased()

        // DB Bench chosen because of long arms
        if (morphotype == .longArms || morphotype == .longLimbed),
           name.contains("dumbbell") && name.contains("bench") {
            return "Dumbbells chosen because your long arms get better chest stretch and safer range of motion than a barbell."
        }

        // Leg Press / Bulgarian chosen because of long femurs
        if measurements.femurToTorsoRatio > 0.55 {
            if name.contains("leg press") {
                return "Leg press selected because your long femurs make deep squats risky for your lower back."
            }
            if name.contains("bulgarian") || name.contains("split squat") {
                return "Bulgarian split squat chosen — your long femurs benefit from the unilateral stance and reduced spinal load."
            }
        }

        // Hip Thrust for short torso
        if morphotype == .shortTorso, name.contains("hip thrust") {
            return "Hip thrust prioritized — your short torso makes heavy squats less efficient for glute activation."
        }

        // Machine selected because brand is available
        if equipmentType == "machine" {
            return "Machine selected for its guided force curve — ideal for controlled hypertrophy."
        }

        // Wide clavicles + incline work
        if measurements.shoulderToHipRatio > 1.4, name.contains("incline") {
            return "Incline chosen because your wide clavicles benefit from upper chest focus to enhance the V-taper."
        }

        // Narrow hips + lateral raise
        if measurements.shoulderToHipRatio < 1.3, name.contains("lateral") {
            return "Lateral raises prioritized — widening your delts to improve your shoulder-to-hip ratio."
        }

        return ""
    }

    /// Returns a morpho-aware priority reason string.
    private func priorityReason(for exercise: Exercise, goal: AestheticGoal) -> String {
        let muscle = exercise.primaryMuscle ?? ""
        switch goal {
        case .greekMale:
            if muscle.lowercased().contains("delt") { return "V-taper: wide shoulders are the #1 Pareto lever." }
            if muscle.lowercased().contains("chest") { return "Upper chest creates the armored plate look." }
            if muscle.lowercased().contains("lat") { return "Lats widen your back for the V-taper silhouette." }
            return "Priority muscle for the Greek Statue aesthetic."
        case .hourglassFemale:
            if muscle.lowercased().contains("glute") { return "Glutes are the #1 driver of the hourglass shape." }
            if muscle.lowercased().contains("hamstring") { return "Hamstrings define the posterior curve." }
            if muscle.lowercased().contains("quad") { return "Quads create leg definition and balance." }
            return "Priority muscle for the Hourglass aesthetic."
        }
    }

    // MARK: - Session Duration Estimate

    func estimateSessionDuration(exercises: [ProgramExercise]) -> Int {
        var totalMinutes = 5 // Warm-up
        for ex in exercises {
            let sets = Int(ex.targetSets)
            let restSec = Int(ex.restSeconds)
            let setDuration = 45 // avg seconds per set (setup + execution)
            let exerciseMinutes = (sets * (setDuration + restSec)) / 60
            totalMinutes += exerciseMinutes
        }
        return min(totalMinutes, 60)
    }

    // MARK: - Helpers

    private func isHomeGymOnly(equipment: [String]) -> Bool {
        guard !equipment.isEmpty else { return false }
        let homeEquip: Set<String> = ["dumbbell", "band", "kettlebell", "bodyweight"]
        return equipment.allSatisfy { homeEquip.contains($0.lowercased()) }
    }

    private func findAlternative(
        primaryMuscle: String,
        preferredEquipment: [String],
        preferredNames: [String],
        availableEquipment: [String],
        excluding: UUID,
        context: NSManagedObjectContext
    ) -> Exercise? {
        let request = NSFetchRequest<Exercise>(entityName: "Exercise")
        request.predicate = NSPredicate(format: "primaryMuscle ==[c] %@ AND id != %@", primaryMuscle, excluding as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        guard let candidates = try? context.fetch(request) else { return nil }

        // First: try to match by preferred name keywords
        for preferred in preferredNames {
            if let match = candidates.first(where: {
                $0.name.lowercased().contains(preferred.lowercased()) &&
                (availableEquipment.isEmpty || availableEquipment.contains($0.equipmentType ?? ""))
            }) {
                return match
            }
        }

        // Second: match by preferred equipment type
        for eq in preferredEquipment {
            if let match = candidates.first(where: { $0.equipmentType == eq }) {
                return match
            }
        }

        // Fallback: anything available
        let available = candidates.filter { ex in
            guard let eqType = ex.equipmentType else { return true }
            return availableEquipment.isEmpty || availableEquipment.contains(eqType)
        }
        return available.first
    }

    private func nextMonday() -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysUntilMonday = weekday == 2 ? 7 : ((9 - weekday) % 7)
        return calendar.date(byAdding: .day, value: daysUntilMonday, to: today) ?? today
    }
}
