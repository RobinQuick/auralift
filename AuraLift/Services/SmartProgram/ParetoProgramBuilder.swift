import Foundation
import CoreData

// MARK: - ParetoProgramBuilder

/// Generates 12-week periodized programs using Pareto (20/80) volume allocation.
/// Priority muscles get ~60% of weekly sets, maintenance muscles get ~40%.
final class ParetoProgramBuilder {

    // MARK: - Volume Config

    private struct VolumeConfig {
        let totalWeeklySets: Int
        let prioritySetsRatio: Double // ~0.60
        let maxSessionMinutes: Int

        static let fullBody3 = VolumeConfig(totalWeeklySets: 18, prioritySetsRatio: 0.60, maxSessionMinutes: 60)
        static let upperLower4 = VolumeConfig(totalWeeklySets: 24, prioritySetsRatio: 0.60, maxSessionMinutes: 60)
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

        // Select exercises for priority and maintenance muscles
        let priorityExercises = selectExercises(
            for: aestheticGoal.priorityMuscles,
            priority: true,
            gymProfile: gymProfile,
            morphotype: morphotype,
            measurements: measurements,
            sex: sex,
            context: context
        )
        let maintenanceExercises = selectExercises(
            for: aestheticGoal.maintenanceMuscles,
            priority: false,
            gymProfile: gymProfile,
            morphotype: morphotype,
            measurements: measurements,
            sex: sex,
            context: context
        )

        // Build 12 weeks
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
                userProfile: userProfile,
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
        morphotype: Morphotype?,
        measurements: SegmentMeasurements?,
        sex: String,
        context: NSManagedObjectContext
    ) -> [Exercise] {
        let equipment = gymProfile.equipmentList
        var result: [Exercise] = []

        for muscle in muscles {
            let request = NSFetchRequest<Exercise>(entityName: "Exercise")
            request.predicate = NSPredicate(format: "primaryMuscle ==[c] %@", muscle)
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            guard let candidates = try? context.fetch(request), !candidates.isEmpty else {
                continue
            }

            // Filter by available equipment
            let available = candidates.filter { ex in
                guard let eqType = ex.equipmentType else { return true }
                return equipment.isEmpty || equipment.contains(eqType)
            }

            guard var chosen = available.first ?? candidates.first else { continue }

            // Apply morpho-swap if applicable
            if let morpho = morphotype, let measures = measurements {
                if let swapped = morphoSwap(
                    exercise: chosen,
                    morphotype: morpho,
                    measurements: measures,
                    sex: sex,
                    availableEquipment: equipment,
                    context: context
                ) {
                    chosen = swapped
                }
            }

            result.append(chosen)

            // For priority muscles, add a second exercise if available (stretch position preferred)
            if priority, available.count > 1 {
                let second = available.first { $0.id != chosen.id && $0.stretchPositionBonus } ??
                             available.first { $0.id != chosen.id }
                if let second {
                    result.append(second)
                }
            }
        }

        return result
    }

    // MARK: - Morpho Swap

    func morphoSwap(
        exercise: Exercise,
        morphotype: Morphotype,
        measurements: SegmentMeasurements,
        sex: String,
        availableEquipment: [String],
        context: NSManagedObjectContext
    ) -> Exercise? {
        let name = exercise.name.lowercased()

        // Long arms → Barbell Bench → DB Bench or converging machine
        if (morphotype == .longArms || morphotype == .longLimbed),
           name.contains("barbell bench") || name.contains("bench press") {
            return findAlternative(
                primaryMuscle: exercise.primaryMuscle ?? "Chest",
                preferredEquipment: ["dumbbell", "machine"],
                availableEquipment: availableEquipment,
                excluding: exercise.id,
                context: context
            )
        }

        // Short torso → Heavy Squat → Hip Thrust + RDL priority
        if morphotype == .shortTorso,
           name.contains("squat") && !name.contains("front") {
            return findAlternative(
                primaryMuscle: "Glutes",
                preferredEquipment: availableEquipment,
                availableEquipment: availableEquipment,
                excluding: exercise.id,
                context: context
            )
        }

        // Long femurs → Back Squat → Front Squat or Leg Press
        if morphotype == .longLimbed || (measurements.femurToTorsoRatio > 0.55),
           name.contains("back squat") || name == "squat" {
            return findAlternative(
                primaryMuscle: exercise.primaryMuscle ?? "Quads",
                preferredEquipment: ["machine", "barbell"],
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
        userProfile: UserProfile,
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
                    userProfile: userProfile,
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
        userProfile: UserProfile,
        context: NSManagedObjectContext
    ) -> [ProgramExercise] {
        var result: [ProgramExercise] = []
        let setsPerSession = Int(Double(config.totalWeeklySets) / Double(frequency.daysPerWeek) * weekType.volumeModifier)
        let prioritySets = Int(Double(setsPerSession) * config.prioritySetsRatio)
        let maintenanceSets = setsPerSession - prioritySets

        // Distribute priority exercises
        let pExercises = distributeForDay(dayIndex: dayIndex, exercises: priorityExercises, frequency: frequency)
        for exercise in pExercises {
            let setsEach = max(2, prioritySets / max(1, pExercises.count))
            let progEx = buildProgramExercise(
                exercise: exercise,
                sets: setsEach,
                weekType: weekType,
                isPriority: true,
                context: context
            )
            result.append(progEx)
        }

        // Distribute maintenance exercises
        let mExercises = distributeForDay(dayIndex: dayIndex, exercises: maintenanceExercises, frequency: frequency)
        for exercise in mExercises {
            let setsEach = max(2, maintenanceSets / max(1, mExercises.count))
            let progEx = buildProgramExercise(
                exercise: exercise,
                sets: setsEach,
                weekType: weekType,
                isPriority: false,
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
            // Full body: rotate through exercises across the 3 training days
            let trainIdx = frequency.trainingDayIndices.firstIndex(of: dayIndex) ?? 0
            let perDay = max(1, exercises.count / 3)
            let start = trainIdx * perDay
            let end = min(start + perDay + 1, exercises.count)
            guard start < exercises.count else { return [exercises[0]] }
            return Array(exercises[start..<end])

        case .upperLower4:
            // Upper/Lower: split by muscle region
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

        // Generate "Why" message
        progEx.whyMessage = generateWhyMessage(exercise: exercise, isPriority: isPriority, weekType: weekType)
        progEx.priorityReason = isPriority ? "Priority muscle for your aesthetic goal" : nil

        return progEx
    }

    private func generateWhyMessage(exercise: Exercise, isPriority: Bool, weekType: ProgramWeekType) -> String {
        let muscle = exercise.primaryMuscle ?? "this muscle"
        if isPriority {
            switch weekType {
            case .ramp:
                return "Ramp-up: learning the movement at lighter loads for \(muscle)."
            case .normal:
                return "Priority: \(muscle) gets extra volume for maximum growth."
            case .overload:
                return "Overload phase: pushing \(muscle) beyond normal capacity."
            case .deload:
                return "Recovery week: light work to maintain \(muscle) without fatigue."
            }
        }
        return "Maintenance volume for \(muscle) to preserve balance."
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

    private func findAlternative(
        primaryMuscle: String,
        preferredEquipment: [String],
        availableEquipment: [String],
        excluding: UUID,
        context: NSManagedObjectContext
    ) -> Exercise? {
        let request = NSFetchRequest<Exercise>(entityName: "Exercise")
        request.predicate = NSPredicate(format: "primaryMuscle ==[c] %@ AND id != %@", primaryMuscle, excluding as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        guard let candidates = try? context.fetch(request) else { return nil }

        // Prefer equipment match
        for eq in preferredEquipment {
            if let match = candidates.first(where: { $0.equipmentType == eq }) {
                return match
            }
        }

        // Fallback to anything available
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
        // weekday: 1=Sunday, 2=Monday, ...
        let daysUntilMonday = weekday == 2 ? 7 : ((9 - weekday) % 7)
        return calendar.date(byAdding: .day, value: daysUntilMonday, to: today) ?? today
    }
}
