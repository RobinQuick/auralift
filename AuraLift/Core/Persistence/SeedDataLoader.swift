import Foundation
import CoreData

/// Handles loading seed data into CoreData on first launch.
struct SeedDataLoader {
    private static let seedKey = "com.aurea.seedDataLoaded"

    private static let machinesSeedKey = "com.aurea.machineSeedDataLoaded"
    private static let seasonSeedKey = "com.aurea.seasonInitialized"

    /// Load exercise database if not already loaded.
    static func loadIfNeeded(into context: NSManagedObjectContext) {
        let needsExercises = !UserDefaults.standard.bool(forKey: seedKey)
        let needsMachines = !UserDefaults.standard.bool(forKey: machinesSeedKey)
        let needsSeason = !UserDefaults.standard.bool(forKey: seasonSeedKey)

        if needsExercises {
            loadExercises(into: context)
            loadMuscleGroups(into: context)
            createDefaultProfile(into: context)
        }

        if needsMachines {
            loadMachineExercises(into: context)
        }

        if needsSeason {
            initializeSeason(into: context)
        }

        do {
            try context.save()
            // Only mark as loaded AFTER successful save
            if needsExercises {
                UserDefaults.standard.set(true, forKey: seedKey)
            }
            if needsMachines {
                UserDefaults.standard.set(true, forKey: machinesSeedKey)
            }
            if needsSeason {
                UserDefaults.standard.set(true, forKey: seasonSeedKey)
            }
        } catch {
            context.rollback()
        }
    }

    /// Load preview data for SwiftUI previews.
    static func loadPreviewData(into context: NSManagedObjectContext) {
        loadExercises(into: context)
        loadMuscleGroups(into: context)
        loadMachineExercises(into: context)
        createDefaultProfile(into: context)
        initializeSeason(into: context)
        try? context.save()
    }

    // MARK: - Default Profile

    private static func createDefaultProfile(into context: NSManagedObjectContext) {
        let profile = NSEntityDescription.insertNewObject(forEntityName: "UserProfile", into: context)
        profile.setValue(UUID(), forKey: "id")
        profile.setValue("Athlete", forKey: "username")
        profile.setValue("iron", forKey: "currentRankTier")
        profile.setValue(Int32(0), forKey: "currentLP")
        profile.setValue(Int64(0), forKey: "totalXP")
        profile.setValue(Date(), forKey: "createdAt")
        profile.setValue(Date(), forKey: "updatedAt")
    }

    // MARK: - Season Progress

    private static func initializeSeason(into context: NSManagedObjectContext) {
        // Only create if none exists
        let checkRequest = NSFetchRequest<NSManagedObject>(entityName: "SeasonProgress")
        checkRequest.fetchLimit = 1
        if let existing = try? context.fetch(checkRequest), !existing.isEmpty { return }

        let season = NSEntityDescription.insertNewObject(forEntityName: "SeasonProgress", into: context)
        season.setValue(UUID(), forKey: "id")
        season.setValue("season_0_alpha", forKey: "seasonId")
        season.setValue(Int64(0), forKey: "userXP")
        season.setValue(Int16(1), forKey: "currentLevel")
        season.setValue("", forKey: "claimedRewards")
        season.setValue(Date(), forKey: "lastUpdated")

        // Link to default user profile
        let profileRequest = NSFetchRequest<NSManagedObject>(entityName: "UserProfile")
        profileRequest.fetchLimit = 1
        if let profile = try? context.fetch(profileRequest).first {
            season.setValue(profile, forKey: "userProfile")
        }
    }

    // MARK: - Muscle Groups

    private static func loadMuscleGroups(into context: NSManagedObjectContext) {
        let groups: [(name: String, region: String)] = [
            ("Quadriceps", "lower"),
            ("Hamstrings", "lower"),
            ("Glute Max", "lower"),
            ("Glute Med", "lower"),
            ("Calves", "lower"),
            ("Adductors", "lower"),
            ("Upper Chest", "upper"),
            ("Lower Chest", "upper"),
            ("Front Delts", "upper"),
            ("Side Delts", "upper"),
            ("Rear Delts", "upper"),
            ("Upper Lats", "upper"),
            ("Lower Lats", "upper"),
            ("Upper Traps", "upper"),
            ("Mid Traps", "upper"),
            ("Rhomboids", "upper"),
            ("Biceps (Long Head)", "upper"),
            ("Biceps (Short Head)", "upper"),
            ("Triceps (Long Head)", "upper"),
            ("Triceps (Lateral)", "upper"),
            ("Forearms", "upper"),
            ("Abs", "core"),
            ("Obliques", "core"),
            ("Erector Spinae", "core"),
        ]

        for group in groups {
            let entity = NSEntityDescription.insertNewObject(forEntityName: "MuscleGroup", into: context)
            entity.setValue(UUID(), forKey: "id")
            entity.setValue(group.name, forKey: "name")
            entity.setValue(group.region, forKey: "bodyRegion")
            entity.setValue(100.0, forKey: "currentRecoveryScore")
            entity.setValue(Int16(0), forKey: "weeklyVolumeSets")
        }
    }

    // MARK: - Exercise Database

    private static func loadExercises(into context: NSManagedObjectContext) {
        let exercises = ExerciseSeedData.allExercises

        for data in exercises {
            let exercise = NSEntityDescription.insertNewObject(forEntityName: "Exercise", into: context)
            exercise.setValue(UUID(), forKey: "id")
            exercise.setValue(data.name, forKey: "name")
            exercise.setValue(data.category, forKey: "category")
            exercise.setValue(data.primaryMuscle, forKey: "primaryMuscle")
            exercise.setValue(data.secondaryMuscles, forKey: "secondaryMuscles")
            exercise.setValue(data.equipmentType, forKey: "equipmentType")
            exercise.setValue(data.tempoConcentric, forKey: "defaultTempoConcentric")
            exercise.setValue(data.tempoEccentric, forKey: "defaultTempoEccentric")
            exercise.setValue(data.tempoPause, forKey: "defaultTempoPause")
            exercise.setValue(data.biomechanicalNotes, forKey: "biomechanicalNotes")
            exercise.setValue(data.stretchBonus, forKey: "stretchPositionBonus")
            exercise.setValue(data.riskLevel, forKey: "riskLevel")
            exercise.setValue(false, forKey: "isCustom")
        }
    }

    // MARK: - Machine Exercises

    private static func loadMachineExercises(into context: NSManagedObjectContext) {
        let machines = MachineSeedData.allMachineExercises

        for data in machines {
            // Create Exercise
            let exercise = NSEntityDescription.insertNewObject(forEntityName: "Exercise", into: context)
            exercise.setValue(UUID(), forKey: "id")
            exercise.setValue(data.exerciseName, forKey: "name")
            exercise.setValue(data.category, forKey: "category")
            exercise.setValue(data.primaryMuscle, forKey: "primaryMuscle")
            exercise.setValue(data.secondaryMuscles, forKey: "secondaryMuscles")
            exercise.setValue("machine", forKey: "equipmentType")
            exercise.setValue(data.tempoConcentric, forKey: "defaultTempoConcentric")
            exercise.setValue(data.tempoEccentric, forKey: "defaultTempoEccentric")
            exercise.setValue(data.tempoPause, forKey: "defaultTempoPause")
            exercise.setValue(data.biomechanicalNotes, forKey: "biomechanicalNotes")
            exercise.setValue(data.stretchBonus, forKey: "stretchPositionBonus")
            exercise.setValue("optimal", forKey: "riskLevel")
            exercise.setValue(false, forKey: "isCustom")

            // Create MachineSpec
            let machine = NSEntityDescription.insertNewObject(forEntityName: "MachineSpec", into: context)
            machine.setValue(UUID(), forKey: "id")
            machine.setValue(data.machineName, forKey: "machineName")
            machine.setValue(data.manufacturer, forKey: "manufacturer")
            machine.setValue(data.machineType, forKey: "machineType")
            machine.setValue(data.resistanceProfile, forKey: "resistanceProfile")
            machine.setValue(data.startingResistance, forKey: "startingResistance")
            machine.setValue(data.weightStackMin, forKey: "weightStackMin")
            machine.setValue(data.weightStackMax, forKey: "weightStackMax")
            machine.setValue(data.weightIncrement, forKey: "weightIncrement")
            machine.setValue(data.seatAdjustable, forKey: "seatAdjustable")
            machine.setValue(data.padAdjustable, forKey: "padAdjustable")
            machine.setValue(data.camProfileNotes, forKey: "camProfileNotes")
            machine.setValue(data.setupInstructions, forKey: "setupInstructions")

            // Link Exercise ↔ MachineSpec
            exercise.setValue(machine, forKey: "machineSpec")
            machine.setValue(exercise, forKey: "exercise")
        }
    }
}
