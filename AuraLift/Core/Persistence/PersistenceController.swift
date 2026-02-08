import CoreData

/// Manages the CoreData stack for AuraLift.
/// Builds the entire schema programmatically since we don't use .xcdatamodeld files.
struct PersistenceController {
    static let shared = PersistenceController()

    /// In-memory store for SwiftUI previews and testing
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        // Add sample data for previews
        SeedDataLoader.loadPreviewData(into: context)
        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = Self.buildManagedObjectModel()
        container = NSPersistentContainer(name: "AuraLift", managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("CoreData failed to load: \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Programmatic Model Builder

    static func buildManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // Create all entity descriptions
        let userProfileEntity = buildUserProfileEntity()
        let morphoScanEntity = buildMorphoScanEntity()
        let exerciseEntity = buildExerciseEntity()
        let machineSpecEntity = buildMachineSpecEntity()
        let workoutSessionEntity = buildWorkoutSessionEntity()
        let workoutSetEntity = buildWorkoutSetEntity()
        let rankingRecordEntity = buildRankingRecordEntity()
        let muscleGroupEntity = buildMuscleGroupEntity()
        let recoverySnapshotEntity = buildRecoverySnapshotEntity()
        let nutritionLogEntity = buildNutritionLogEntity()
        let scienceInsightEntity = buildScienceInsightEntity()
        let guildMembershipEntity = buildGuildMembershipEntity()
        let seasonProgressEntity = buildSeasonProgressEntity()

        // Phase 12: Smart Program entities
        let gymProfileEntity = buildGymProfileEntity()
        let trainingProgramEntity = buildTrainingProgramEntity()
        let programWeekEntity = buildProgramWeekEntity()
        let programDayEntity = buildProgramDayEntity()
        let programExerciseEntity = buildProgramExerciseEntity()

        // Wire up relationships
        wireRelationships(
            userProfile: userProfileEntity,
            morphoScan: morphoScanEntity,
            exercise: exerciseEntity,
            machineSpec: machineSpecEntity,
            workoutSession: workoutSessionEntity,
            workoutSet: workoutSetEntity,
            rankingRecord: rankingRecordEntity,
            muscleGroup: muscleGroupEntity,
            recoverySnapshot: recoverySnapshotEntity,
            nutritionLog: nutritionLogEntity,
            guildMembership: guildMembershipEntity,
            seasonProgress: seasonProgressEntity
        )

        // Phase 12: Wire smart program relationships
        wireSmartProgramRelationships(
            userProfile: userProfileEntity,
            exercise: exerciseEntity,
            gymProfile: gymProfileEntity,
            trainingProgram: trainingProgramEntity,
            programWeek: programWeekEntity,
            programDay: programDayEntity,
            programExercise: programExerciseEntity
        )

        model.entities = [
            userProfileEntity,
            morphoScanEntity,
            exerciseEntity,
            machineSpecEntity,
            workoutSessionEntity,
            workoutSetEntity,
            rankingRecordEntity,
            muscleGroupEntity,
            recoverySnapshotEntity,
            nutritionLogEntity,
            scienceInsightEntity,
            guildMembershipEntity,
            seasonProgressEntity,
            gymProfileEntity,
            trainingProgramEntity,
            programWeekEntity,
            programDayEntity,
            programExerciseEntity
        ]

        return model
    }

    // MARK: - Entity Builders

    private static func buildUserProfileEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "UserProfile"
        entity.managedObjectClassName = "UserProfile"
        entity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("username", .stringAttributeType, optional: false),
            attribute("email", .stringAttributeType),
            attribute("dateOfBirth", .dateAttributeType),
            attribute("biologicalSex", .stringAttributeType),
            attribute("heightCm", .doubleAttributeType),
            attribute("weightKg", .doubleAttributeType),
            attribute("bodyFatPercentage", .doubleAttributeType),
            attribute("currentRankTier", .stringAttributeType, defaultValue: "iron"),
            attribute("currentLP", .integer32AttributeType, defaultValue: Int32(0)),
            attribute("totalXP", .integer64AttributeType, defaultValue: Int64(0)),
            attribute("createdAt", .dateAttributeType, optional: false),
            attribute("updatedAt", .dateAttributeType, optional: false),
        ]
        return entity
    }

    private static func buildMorphoScanEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "MorphoScan"
        entity.managedObjectClassName = "MorphoScan"
        entity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("scanDate", .dateAttributeType, optional: false),
            attribute("torsoLength", .doubleAttributeType),
            attribute("femurLength", .doubleAttributeType),
            attribute("tibiaLength", .doubleAttributeType),
            attribute("humerusLength", .doubleAttributeType),
            attribute("forearmLength", .doubleAttributeType),
            attribute("shoulderWidth", .doubleAttributeType),
            attribute("hipWidth", .doubleAttributeType),
            attribute("armSpan", .doubleAttributeType),
            attribute("femurToTorsoRatio", .doubleAttributeType),
            attribute("tibiaToFemurRatio", .doubleAttributeType),
            attribute("humerusToTorsoRatio", .doubleAttributeType),
            attribute("rawPoseData", .binaryDataAttributeType),
            attribute("estimatedHeightCm", .doubleAttributeType, defaultValue: 0.0),
            attribute("bodyFatEstimate", .doubleAttributeType, defaultValue: 0.0),
            attribute("goldenRatioScore", .doubleAttributeType, defaultValue: 0.0),
            attribute("waistEstimate", .doubleAttributeType, defaultValue: 0.0),
        ]
        return entity
    }

    private static func buildExerciseEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Exercise"
        entity.managedObjectClassName = "Exercise"
        entity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("name", .stringAttributeType, optional: false),
            attribute("category", .stringAttributeType),
            attribute("primaryMuscle", .stringAttributeType),
            attribute("secondaryMuscles", .stringAttributeType),
            attribute("equipmentType", .stringAttributeType),
            attribute("defaultTempoConcentric", .doubleAttributeType, defaultValue: 1.0),
            attribute("defaultTempoEccentric", .doubleAttributeType, defaultValue: 3.0),
            attribute("defaultTempoPause", .doubleAttributeType, defaultValue: 0.5),
            attribute("biomechanicalNotes", .stringAttributeType),
            attribute("stretchPositionBonus", .booleanAttributeType, defaultValue: false),
            attribute("riskLevel", .stringAttributeType, defaultValue: "optimal"),
            attribute("isCustom", .booleanAttributeType, defaultValue: false),
        ]
        return entity
    }

    private static func buildMachineSpecEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "MachineSpec"
        entity.managedObjectClassName = "MachineSpec"
        entity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("machineName", .stringAttributeType, optional: false),
            attribute("manufacturer", .stringAttributeType),
            attribute("machineType", .stringAttributeType),
            attribute("cablePositionHigh", .booleanAttributeType, defaultValue: false),
            attribute("cablePositionMid", .booleanAttributeType, defaultValue: false),
            attribute("cablePositionLow", .booleanAttributeType, defaultValue: false),
            attribute("seatAdjustable", .booleanAttributeType, defaultValue: false),
            attribute("padAdjustable", .booleanAttributeType, defaultValue: false),
            attribute("weightStackMin", .doubleAttributeType),
            attribute("weightStackMax", .doubleAttributeType),
            attribute("weightIncrement", .doubleAttributeType),
            attribute("camProfileNotes", .stringAttributeType),
            attribute("setupInstructions", .stringAttributeType),
            attribute("resistanceProfile", .stringAttributeType, defaultValue: "linear"),
            attribute("startingResistance", .doubleAttributeType, defaultValue: 0.0),
        ]
        return entity
    }

    private static func buildWorkoutSessionEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "WorkoutSession"
        entity.managedObjectClassName = "WorkoutSession"
        entity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("startTime", .dateAttributeType, optional: false),
            attribute("endTime", .dateAttributeType),
            attribute("totalVolume", .doubleAttributeType),
            attribute("totalXPEarned", .integer32AttributeType, defaultValue: Int32(0)),
            attribute("lpChange", .integer32AttributeType, defaultValue: Int32(0)),
            attribute("averageFormScore", .doubleAttributeType),
            attribute("comboMultiplier", .doubleAttributeType, defaultValue: 1.0),
            attribute("peakVelocity", .doubleAttributeType),
            attribute("sessionNotes", .stringAttributeType),
        ]
        return entity
    }

    private static func buildWorkoutSetEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "WorkoutSet"
        entity.managedObjectClassName = "WorkoutSet"
        entity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("setNumber", .integer16AttributeType),
            attribute("reps", .integer16AttributeType),
            attribute("weightKg", .doubleAttributeType),
            attribute("averageConcentricVelocity", .doubleAttributeType),
            attribute("peakConcentricVelocity", .doubleAttributeType),
            attribute("velocityLossPercent", .doubleAttributeType),
            attribute("autoStopped", .booleanAttributeType, defaultValue: false),
            attribute("formScore", .doubleAttributeType),
            attribute("barPathDeviation", .doubleAttributeType),
            attribute("romDegrees", .doubleAttributeType),
            attribute("tempoActualConcentric", .doubleAttributeType),
            attribute("tempoActualEccentric", .doubleAttributeType),
            attribute("rpe", .doubleAttributeType),
            attribute("xpEarned", .integer32AttributeType, defaultValue: Int32(0)),
            attribute("comboTag", .stringAttributeType),
            attribute("timestamp", .dateAttributeType),
        ]
        return entity
    }

    private static func buildRankingRecordEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "RankingRecord"
        entity.managedObjectClassName = "RankingRecord"
        entity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("recordDate", .dateAttributeType, optional: false),
            attribute("tier", .stringAttributeType),
            attribute("lpAtRecord", .integer32AttributeType),
            attribute("strengthToWeightRatio", .doubleAttributeType),
            attribute("formQualityAverage", .doubleAttributeType),
            attribute("velocityScore", .doubleAttributeType),
        ]
        return entity
    }

    private static func buildMuscleGroupEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "MuscleGroup"
        entity.managedObjectClassName = "MuscleGroup"
        entity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("name", .stringAttributeType, optional: false),
            attribute("bodyRegion", .stringAttributeType),
            attribute("currentRecoveryScore", .doubleAttributeType, defaultValue: 100.0),
            attribute("weeklyVolumeSets", .integer16AttributeType, defaultValue: Int16(0)),
            attribute("lastTrainedDate", .dateAttributeType),
        ]
        return entity
    }

    private static func buildRecoverySnapshotEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "RecoverySnapshot"
        entity.managedObjectClassName = "RecoverySnapshot"
        entity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("snapshotDate", .dateAttributeType, optional: false),
            attribute("hrvValue", .doubleAttributeType),
            attribute("sleepHours", .doubleAttributeType),
            attribute("sleepQualityScore", .doubleAttributeType),
            attribute("restingHeartRate", .doubleAttributeType),
            attribute("activeEnergyBurned", .doubleAttributeType),
            attribute("cyclePhase", .stringAttributeType),
            attribute("overallReadiness", .doubleAttributeType),
        ]
        return entity
    }

    private static func buildNutritionLogEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "NutritionLog"
        entity.managedObjectClassName = "NutritionLog"
        entity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("logDate", .dateAttributeType, optional: false),
            attribute("targetCalories", .doubleAttributeType),
            attribute("actualCalories", .doubleAttributeType),
            attribute("proteinGrams", .doubleAttributeType),
            attribute("carbsGrams", .doubleAttributeType),
            attribute("fatGrams", .doubleAttributeType),
            attribute("waterLiters", .doubleAttributeType),
            attribute("creatineGrams", .doubleAttributeType),
            attribute("wheyProteinGrams", .doubleAttributeType),
        ]
        return entity
    }

    private static func buildScienceInsightEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "ScienceInsight"
        entity.managedObjectClassName = "ScienceInsight"
        entity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("fetchDate", .dateAttributeType, optional: false),
            attribute("topic", .stringAttributeType),
            attribute("source", .stringAttributeType),
            attribute("summary", .stringAttributeType),
            attribute("recommendedTempoChange", .stringAttributeType),
            attribute("recommendedRestChange", .stringAttributeType),
            attribute("appliedToExercises", .stringAttributeType),
            attribute("isActive", .booleanAttributeType, defaultValue: true),
        ]
        return entity
    }

    private static func buildGuildMembershipEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "GuildMembership"
        entity.managedObjectClassName = "GuildMembership"
        entity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("guildName", .stringAttributeType, optional: false),
            attribute("guildTag", .stringAttributeType),
            attribute("joinDate", .dateAttributeType, optional: false),
            attribute("role", .stringAttributeType, defaultValue: "member"),
            attribute("guildWarWins", .integer32AttributeType, defaultValue: Int32(0)),
            attribute("guildWarLosses", .integer32AttributeType, defaultValue: Int32(0)),
        ]
        return entity
    }

    private static func buildSeasonProgressEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "SeasonProgress"
        entity.managedObjectClassName = "SeasonProgress"
        entity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("seasonId", .stringAttributeType, optional: false),
            attribute("userXP", .integer64AttributeType, defaultValue: Int64(0)),
            attribute("currentLevel", .integer16AttributeType, defaultValue: Int16(1)),
            attribute("claimedRewards", .stringAttributeType, defaultValue: ""),
            attribute("lastUpdated", .dateAttributeType, optional: false),
        ]
        return entity
    }

    // MARK: - Relationship Wiring

    private static func wireRelationships(
        userProfile: NSEntityDescription,
        morphoScan: NSEntityDescription,
        exercise: NSEntityDescription,
        machineSpec: NSEntityDescription,
        workoutSession: NSEntityDescription,
        workoutSet: NSEntityDescription,
        rankingRecord: NSEntityDescription,
        muscleGroup: NSEntityDescription,
        recoverySnapshot: NSEntityDescription,
        nutritionLog: NSEntityDescription,
        guildMembership: NSEntityDescription,
        seasonProgress: NSEntityDescription
    ) {
        // UserProfile ↔ MorphoScan (one-to-many)
        let userToMorpho = relationship("morphoScans", destination: morphoScan, toMany: true)
        let morphoToUser = relationship("userProfile", destination: userProfile)
        userToMorpho.inverseRelationship = morphoToUser
        morphoToUser.inverseRelationship = userToMorpho

        // UserProfile ↔ WorkoutSession (one-to-many)
        let userToSessions = relationship("workoutSessions", destination: workoutSession, toMany: true)
        let sessionToUser = relationship("userProfile", destination: userProfile)
        userToSessions.inverseRelationship = sessionToUser
        sessionToUser.inverseRelationship = userToSessions

        // UserProfile ↔ RankingRecord (one-to-many)
        let userToRankings = relationship("rankingRecords", destination: rankingRecord, toMany: true)
        let rankingToUser = relationship("userProfile", destination: userProfile)
        userToRankings.inverseRelationship = rankingToUser
        rankingToUser.inverseRelationship = userToRankings

        // UserProfile ↔ RecoverySnapshot (one-to-many)
        let userToRecovery = relationship("recoverySnapshots", destination: recoverySnapshot, toMany: true)
        let recoveryToUser = relationship("userProfile", destination: userProfile)
        userToRecovery.inverseRelationship = recoveryToUser
        recoveryToUser.inverseRelationship = userToRecovery

        // UserProfile ↔ NutritionLog (one-to-many)
        let userToNutrition = relationship("nutritionLogs", destination: nutritionLog, toMany: true)
        let nutritionToUser = relationship("userProfile", destination: userProfile)
        userToNutrition.inverseRelationship = nutritionToUser
        nutritionToUser.inverseRelationship = userToNutrition

        // UserProfile ↔ GuildMembership (one-to-one, optional)
        let userToGuild = relationship("guildMembership", destination: guildMembership, optional: true)
        let guildToUser = relationship("userProfile", destination: userProfile)
        userToGuild.inverseRelationship = guildToUser
        guildToUser.inverseRelationship = userToGuild

        // Exercise ↔ MachineSpec (one-to-one, optional)
        let exerciseToMachine = relationship("machineSpec", destination: machineSpec, optional: true)
        let machineToExercise = relationship("exercise", destination: exercise)
        exerciseToMachine.inverseRelationship = machineToExercise
        machineToExercise.inverseRelationship = exerciseToMachine

        // Exercise ↔ WorkoutSet (one-to-many)
        let exerciseToSets = relationship("workoutSets", destination: workoutSet, toMany: true)
        let setToExercise = relationship("exercise", destination: exercise)
        exerciseToSets.inverseRelationship = setToExercise
        setToExercise.inverseRelationship = exerciseToSets

        // Exercise ↔ MuscleGroup (many-to-many)
        let exerciseToMuscles = relationship("muscleGroups", destination: muscleGroup, toMany: true)
        let muscleToExercises = relationship("exercises", destination: exercise, toMany: true)
        exerciseToMuscles.inverseRelationship = muscleToExercises
        muscleToExercises.inverseRelationship = exerciseToMuscles

        // WorkoutSession ↔ WorkoutSet (one-to-many, ordered)
        let sessionToSets = relationship("workoutSets", destination: workoutSet, toMany: true, ordered: true)
        let setToSession = relationship("workoutSession", destination: workoutSession)
        sessionToSets.inverseRelationship = setToSession
        setToSession.inverseRelationship = sessionToSets

        // MuscleGroup ↔ RecoverySnapshot (one-to-many)
        let muscleToRecovery = relationship("recoverySnapshots", destination: recoverySnapshot, toMany: true)
        let recoveryToMuscle = relationship("muscleGroup", destination: muscleGroup, optional: true)
        muscleToRecovery.inverseRelationship = recoveryToMuscle
        recoveryToMuscle.inverseRelationship = muscleToRecovery

        // UserProfile ↔ SeasonProgress (one-to-one, optional)
        let userToSeason = relationship("seasonProgress", destination: seasonProgress, optional: true)
        let seasonToUser = relationship("userProfile", destination: userProfile)
        userToSeason.inverseRelationship = seasonToUser
        seasonToUser.inverseRelationship = userToSeason

        // Assign relationships to entities
        userProfile.properties += [userToMorpho, userToSessions, userToRankings, userToRecovery, userToNutrition, userToGuild, userToSeason]
        morphoScan.properties += [morphoToUser]
        exercise.properties += [exerciseToMachine, exerciseToSets, exerciseToMuscles]
        machineSpec.properties += [machineToExercise]
        workoutSession.properties += [sessionToUser, sessionToSets]
        workoutSet.properties += [setToExercise, setToSession]
        rankingRecord.properties += [rankingToUser]
        muscleGroup.properties += [muscleToExercises, muscleToRecovery]
        recoverySnapshot.properties += [recoveryToUser, recoveryToMuscle]
        nutritionLog.properties += [nutritionToUser]
        guildMembership.properties += [guildToUser]
        seasonProgress.properties += [seasonToUser]
    }

    // MARK: - Phase 12: Smart Program Entity Builders

    private static func buildGymProfileEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "GymProfile"
        entity.managedObjectClassName = "GymProfile"
        entity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("name", .stringAttributeType, optional: false),
            attribute("availableEquipment", .stringAttributeType, defaultValue: ""),
            attribute("availableBrands", .stringAttributeType, defaultValue: ""),
            attribute("isActive", .booleanAttributeType, defaultValue: true),
        ]
        return entity
    }

    private static func buildTrainingProgramEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "TrainingProgram"
        entity.managedObjectClassName = "TrainingProgram"
        entity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("name", .stringAttributeType, optional: false),
            attribute("startDate", .dateAttributeType, optional: false),
            attribute("endDate", .dateAttributeType),
            attribute("weekCount", .integer16AttributeType, defaultValue: Int16(12)),
            attribute("frequency", .stringAttributeType, defaultValue: "full_body_3"),
            attribute("aestheticGoal", .stringAttributeType, defaultValue: "greek_male"),
            attribute("gymProfileId", .UUIDAttributeType),
            attribute("morphotypeAtCreation", .stringAttributeType),
            attribute("isActive", .booleanAttributeType, defaultValue: true),
        ]
        return entity
    }

    private static func buildProgramWeekEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "ProgramWeek"
        entity.managedObjectClassName = "ProgramWeek"
        entity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("weekNumber", .integer16AttributeType, defaultValue: Int16(1)),
            attribute("weekType", .stringAttributeType, defaultValue: "normal"),
            attribute("volumeModifier", .doubleAttributeType, defaultValue: 1.0),
            attribute("intensityModifier", .doubleAttributeType, defaultValue: 1.0),
            attribute("overloadNotes", .stringAttributeType),
            attribute("isComplete", .booleanAttributeType, defaultValue: false),
        ]
        return entity
    }

    private static func buildProgramDayEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "ProgramDay"
        entity.managedObjectClassName = "ProgramDay"
        entity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("dayIndex", .integer16AttributeType, defaultValue: Int16(0)),
            attribute("dayLabel", .stringAttributeType, defaultValue: ""),
            attribute("scheduledDate", .dateAttributeType),
            attribute("isRestDay", .booleanAttributeType, defaultValue: false),
            attribute("isCompleted", .booleanAttributeType, defaultValue: false),
            attribute("completedSessionId", .UUIDAttributeType),
            attribute("estimatedDurationMinutes", .integer16AttributeType, defaultValue: Int16(0)),
            attribute("recoveryFocus", .stringAttributeType),
        ]
        return entity
    }

    private static func buildProgramExerciseEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "ProgramExercise"
        entity.managedObjectClassName = "ProgramExercise"
        entity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("exerciseOrder", .integer16AttributeType, defaultValue: Int16(0)),
            attribute("targetSets", .integer16AttributeType, defaultValue: Int16(3)),
            attribute("targetReps", .stringAttributeType, defaultValue: "8-12"),
            attribute("targetWeightKg", .doubleAttributeType, defaultValue: 0.0),
            attribute("targetRPE", .doubleAttributeType, defaultValue: 7.0),
            attribute("targetVelocityZone", .stringAttributeType),
            attribute("restSeconds", .integer16AttributeType, defaultValue: Int16(90)),
            attribute("tempoDescription", .stringAttributeType),
            attribute("whyMessage", .stringAttributeType),
            attribute("priorityReason", .stringAttributeType),
            attribute("isCompleted", .booleanAttributeType, defaultValue: false),
            attribute("actualWeightKg", .doubleAttributeType, defaultValue: 0.0),
            attribute("actualReps", .integer16AttributeType, defaultValue: Int16(0)),
            attribute("actualRPE", .doubleAttributeType, defaultValue: 0.0),
        ]
        return entity
    }

    // MARK: - Phase 12: Smart Program Relationship Wiring

    private static func wireSmartProgramRelationships(
        userProfile: NSEntityDescription,
        exercise: NSEntityDescription,
        gymProfile: NSEntityDescription,
        trainingProgram: NSEntityDescription,
        programWeek: NSEntityDescription,
        programDay: NSEntityDescription,
        programExercise: NSEntityDescription
    ) {
        // UserProfile ↔ GymProfile (one-to-many)
        let userToGyms = relationship("gymProfiles", destination: gymProfile, toMany: true)
        let gymToUser = relationship("userProfile", destination: userProfile)
        userToGyms.inverseRelationship = gymToUser
        gymToUser.inverseRelationship = userToGyms

        // UserProfile ↔ TrainingProgram (one-to-many)
        let userToPrograms = relationship("trainingPrograms", destination: trainingProgram, toMany: true)
        let programToUser = relationship("userProfile", destination: userProfile)
        userToPrograms.inverseRelationship = programToUser
        programToUser.inverseRelationship = userToPrograms

        // TrainingProgram ↔ ProgramWeek (one-to-many, ordered, cascade)
        let programToWeeks = relationship("weeks", destination: programWeek, toMany: true, ordered: true)
        let weekToProgram = relationship("trainingProgram", destination: trainingProgram)
        programToWeeks.inverseRelationship = weekToProgram
        weekToProgram.inverseRelationship = programToWeeks

        // ProgramWeek ↔ ProgramDay (one-to-many, ordered, cascade)
        let weekToDays = relationship("days", destination: programDay, toMany: true, ordered: true)
        let dayToWeek = relationship("programWeek", destination: programWeek)
        weekToDays.inverseRelationship = dayToWeek
        dayToWeek.inverseRelationship = weekToDays

        // ProgramDay ↔ ProgramExercise (one-to-many, ordered, cascade)
        let dayToExercises = relationship("exercises", destination: programExercise, toMany: true, ordered: true)
        let exerciseToDay = relationship("programDay", destination: programDay)
        dayToExercises.inverseRelationship = exerciseToDay
        exerciseToDay.inverseRelationship = dayToExercises

        // ProgramExercise → Exercise (many-to-one)
        let progExToExercise = relationship("exercise", destination: exercise, optional: true)
        let exerciseToProgExs = relationship("programExercises", destination: programExercise, toMany: true)
        progExToExercise.inverseRelationship = exerciseToProgExs
        exerciseToProgExs.inverseRelationship = progExToExercise

        // Assign relationships to entities
        userProfile.properties += [userToGyms, userToPrograms]
        gymProfile.properties += [gymToUser]
        trainingProgram.properties += [programToUser, programToWeeks]
        programWeek.properties += [weekToProgram, weekToDays]
        programDay.properties += [dayToWeek, dayToExercises]
        programExercise.properties += [exerciseToDay, progExToExercise]
        exercise.properties += [exerciseToProgExs]
    }

    // MARK: - Helpers

    private static func attribute(
        _ name: String,
        _ type: NSAttributeType,
        optional: Bool = true,
        defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let attr = NSAttributeDescription()
        attr.name = name
        attr.attributeType = type
        attr.isOptional = optional
        if let defaultValue = defaultValue {
            attr.defaultValue = defaultValue
        }
        return attr
    }

    private static func relationship(
        _ name: String,
        destination: NSEntityDescription,
        toMany: Bool = false,
        optional: Bool = false,
        ordered: Bool = false
    ) -> NSRelationshipDescription {
        let rel = NSRelationshipDescription()
        rel.name = name
        rel.destinationEntity = destination
        rel.isOptional = optional
        rel.isOrdered = ordered
        if toMany {
            rel.maxCount = 0 // unlimited
            rel.minCount = 0
        } else {
            rel.maxCount = 1
            rel.minCount = optional ? 0 : 1
        }
        rel.deleteRule = toMany ? .cascadeDeleteRule : .nullifyDeleteRule
        return rel
    }
}
