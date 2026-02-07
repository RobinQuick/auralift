import Foundation

/// Pre-loaded machine exercise catalog with brand-specific equipment specs.
/// Covers 5 premium brands with resistance profiles, tare weights, and morpho-based setup.
struct MachineSeedData {

    struct MachineExerciseData {
        let exerciseName: String
        let category: String
        let primaryMuscle: String
        let secondaryMuscles: String
        let tempoConcentric: Double
        let tempoEccentric: Double
        let tempoPause: Double
        let biomechanicalNotes: String
        let stretchBonus: Bool
        // Machine spec
        let machineName: String
        let manufacturer: String
        let machineType: String
        let resistanceProfile: String     // "ascending", "descending", "linear"
        let startingResistance: Double    // Tare weight (kg)
        let weightStackMin: Double
        let weightStackMax: Double
        let weightIncrement: Double
        let seatAdjustable: Bool
        let padAdjustable: Bool
        let camProfileNotes: String
        let setupInstructions: String     // Morpho-based recommendations
    }

    // MARK: - All Machine Exercises

    static let allMachineExercises: [MachineExerciseData] = [

        // =============================================
        // MARK: - Pure Kraft (Gym80) — Sygnum Line
        // =============================================

        MachineExerciseData(
            exerciseName: "Chest Press (Gym80 Sygnum)",
            category: "compound", primaryMuscle: "chest_upper",
            secondaryMuscles: "anterior_deltoid,triceps_lateral",
            tempoConcentric: 1.0, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "Ascending cam — resistance increases at lockout. Excellent for progressive overload at end ROM.",
            stretchBonus: true,
            machineName: "Gym80 Sygnum Chest Press", manufacturer: "Pure Kraft (Gym80)",
            machineType: "plate_loaded",
            resistanceProfile: "ascending", startingResistance: 12.0,
            weightStackMin: 0, weightStackMax: 200, weightIncrement: 2.5,
            seatAdjustable: true, padAdjustable: true,
            camProfileNotes: "Ascending cam. Resistance ~30% harder at lockout vs bottom.",
            setupInstructions: "Height > 185cm: seat position 1-2. Height < 170cm: seat position 5-6. Handles should align with mid-chest."
        ),
        MachineExerciseData(
            exerciseName: "Shoulder Press (Gym80 Sygnum)",
            category: "compound", primaryMuscle: "anterior_deltoid",
            secondaryMuscles: "lateral_deltoid,triceps_long",
            tempoConcentric: 1.0, tempoEccentric: 2.5, tempoPause: 0.5,
            biomechanicalNotes: "Ascending cam profile matches deltoid strength curve — lighter at stretch, heavier at lockout.",
            stretchBonus: false,
            machineName: "Gym80 Sygnum Shoulder Press", manufacturer: "Pure Kraft (Gym80)",
            machineType: "plate_loaded",
            resistanceProfile: "ascending", startingResistance: 8.0,
            weightStackMin: 0, weightStackMax: 150, weightIncrement: 2.5,
            seatAdjustable: true, padAdjustable: false,
            camProfileNotes: "Ascending cam. Natural deltoid strength curve match.",
            setupInstructions: "Height > 185cm: seat at lowest. Height < 170cm: seat at position 4. Grip handles at ear level in starting position."
        ),
        MachineExerciseData(
            exerciseName: "Lat Pulldown (Gym80 Sygnum)",
            category: "compound", primaryMuscle: "lats_upper",
            secondaryMuscles: "biceps_long,rear_delts",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 1.0,
            biomechanicalNotes: "Converging grip path engages lower lats more effectively than straight bar.",
            stretchBonus: true,
            machineName: "Gym80 Sygnum Lat Pulldown", manufacturer: "Pure Kraft (Gym80)",
            machineType: "selectorized",
            resistanceProfile: "ascending", startingResistance: 5.0,
            weightStackMin: 5, weightStackMax: 120, weightIncrement: 5.0,
            seatAdjustable: true, padAdjustable: true,
            camProfileNotes: "Ascending cam — resistance peaks at contracted position.",
            setupInstructions: "Thigh pad snug against quads. Height > 180cm: adjust thigh pad up 1 notch. Full stretch at top, elbows to pockets."
        ),
        MachineExerciseData(
            exerciseName: "Seated Row (Gym80 Sygnum)",
            category: "compound", primaryMuscle: "lats_lower",
            secondaryMuscles: "traps_mid,rhomboids,biceps_short",
            tempoConcentric: 1.0, tempoEccentric: 3.0, tempoPause: 1.0,
            biomechanicalNotes: "Chest pad stabilizes spine. Ascending cam increases load at peak contraction.",
            stretchBonus: true,
            machineName: "Gym80 Sygnum Seated Row", manufacturer: "Pure Kraft (Gym80)",
            machineType: "plate_loaded",
            resistanceProfile: "ascending", startingResistance: 10.0,
            weightStackMin: 0, weightStackMax: 180, weightIncrement: 2.5,
            seatAdjustable: true, padAdjustable: true,
            camProfileNotes: "Ascending cam. Peak resistance at full contraction.",
            setupInstructions: "Chest pad at sternum height. Height > 180cm: seat at lowest. Arms fully extended at start position."
        ),
        MachineExerciseData(
            exerciseName: "Leg Press (Gym80 Sygnum)",
            category: "compound", primaryMuscle: "quadriceps",
            secondaryMuscles: "glute_max,hamstrings",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "45° sled angle. Ascending cam — heaviest at lockout where quads are strongest.",
            stretchBonus: false,
            machineName: "Gym80 Sygnum Leg Press", manufacturer: "Pure Kraft (Gym80)",
            machineType: "plate_loaded",
            resistanceProfile: "ascending", startingResistance: 35.0,
            weightStackMin: 0, weightStackMax: 400, weightIncrement: 2.5,
            seatAdjustable: true, padAdjustable: false,
            camProfileNotes: "Ascending cam. ~35kg sled tare weight.",
            setupInstructions: "Height > 185cm: back pad at lowest, full ROM. Height < 170cm: back pad 2 notches up. Feet shoulder-width, mid-platform."
        ),
        MachineExerciseData(
            exerciseName: "Leg Extension (Gym80 Sygnum)",
            category: "isolation", primaryMuscle: "quadriceps",
            secondaryMuscles: "",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 1.0,
            biomechanicalNotes: "Ascending cam matches quad strength curve. Seat recline increases rectus femoris stretch.",
            stretchBonus: true,
            machineName: "Gym80 Sygnum Leg Extension", manufacturer: "Pure Kraft (Gym80)",
            machineType: "selectorized",
            resistanceProfile: "ascending", startingResistance: 3.0,
            weightStackMin: 5, weightStackMax: 100, weightIncrement: 5.0,
            seatAdjustable: true, padAdjustable: true,
            camProfileNotes: "Ascending cam. Heaviest at full extension.",
            setupInstructions: "Pivot axis at lateral knee joint. Height > 180cm: back pad fully reclined for max RF stretch. Ankle pad on lower shins."
        ),
        MachineExerciseData(
            exerciseName: "Leg Curl (Gym80 Sygnum)",
            category: "isolation", primaryMuscle: "hamstrings",
            secondaryMuscles: "",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "Seated position pre-stretches hamstrings at hip. Ascending cam peaks at full flexion.",
            stretchBonus: true,
            machineName: "Gym80 Sygnum Seated Leg Curl", manufacturer: "Pure Kraft (Gym80)",
            machineType: "selectorized",
            resistanceProfile: "ascending", startingResistance: 3.0,
            weightStackMin: 5, weightStackMax: 100, weightIncrement: 5.0,
            seatAdjustable: true, padAdjustable: true,
            camProfileNotes: "Ascending cam. Pre-stretch at hip joint.",
            setupInstructions: "Pivot at lateral knee. Height > 180cm: seat fully back. Thigh pad snug, ankle pad on Achilles."
        ),
        MachineExerciseData(
            exerciseName: "Hack Squat (Gym80 Sygnum)",
            category: "compound", primaryMuscle: "quadriceps",
            secondaryMuscles: "glute_max",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "Fixed back angle reduces spinal load. Ascending cam heavier at top.",
            stretchBonus: false,
            machineName: "Gym80 Sygnum Hack Squat", manufacturer: "Pure Kraft (Gym80)",
            machineType: "plate_loaded",
            resistanceProfile: "ascending", startingResistance: 25.0,
            weightStackMin: 0, weightStackMax: 300, weightIncrement: 2.5,
            seatAdjustable: false, padAdjustable: true,
            camProfileNotes: "Ascending cam. ~25kg sled tare.",
            setupInstructions: "Height > 185cm: feet higher on platform for full ROM. Height < 170cm: feet mid-platform. Shoulder pads snug."
        ),
        MachineExerciseData(
            exerciseName: "Hip Thrust (Gym80 Sygnum)",
            category: "compound", primaryMuscle: "glute_max",
            secondaryMuscles: "hamstrings",
            tempoConcentric: 1.0, tempoEccentric: 2.0, tempoPause: 1.5,
            biomechanicalNotes: "Dedicated hip thrust machine. Belt-driven for consistent resistance through ROM.",
            stretchBonus: false,
            machineName: "Gym80 Sygnum Hip Thrust", manufacturer: "Pure Kraft (Gym80)",
            machineType: "plate_loaded",
            resistanceProfile: "linear", startingResistance: 15.0,
            weightStackMin: 0, weightStackMax: 250, weightIncrement: 2.5,
            seatAdjustable: true, padAdjustable: true,
            camProfileNotes: "Belt-driven linear resistance.",
            setupInstructions: "Back pad at scapula level. Height > 180cm: bench height at max. Feet flat, knees at 90° at top."
        ),
        MachineExerciseData(
            exerciseName: "Calf Raise (Gym80 Sygnum)",
            category: "isolation", primaryMuscle: "calves",
            secondaryMuscles: "",
            tempoConcentric: 1.0, tempoEccentric: 3.0, tempoPause: 2.0,
            biomechanicalNotes: "Standing position targets gastrocnemius. Full stretch at bottom critical.",
            stretchBonus: true,
            machineName: "Gym80 Sygnum Standing Calf", manufacturer: "Pure Kraft (Gym80)",
            machineType: "plate_loaded",
            resistanceProfile: "linear", startingResistance: 10.0,
            weightStackMin: 0, weightStackMax: 200, weightIncrement: 2.5,
            seatAdjustable: false, padAdjustable: true,
            camProfileNotes: "Linear. Shoulder pad adjustment for height.",
            setupInstructions: "Height > 185cm: shoulder pad at highest. Balls of feet on edge, heels hanging off."
        ),

        // =============================================
        // MARK: - Hammer Strength — Iso-Lateral Line
        // =============================================

        MachineExerciseData(
            exerciseName: "Chest Press (Hammer Strength)",
            category: "compound", primaryMuscle: "chest_upper",
            secondaryMuscles: "anterior_deltoid,triceps_lateral",
            tempoConcentric: 1.0, tempoEccentric: 2.5, tempoPause: 0.5,
            biomechanicalNotes: "Iso-lateral design allows independent arm training. Plate-loaded, linear leverage.",
            stretchBonus: true,
            machineName: "Hammer Strength ISO Chest Press", manufacturer: "Hammer Strength",
            machineType: "plate_loaded",
            resistanceProfile: "linear", startingResistance: 14.0,
            weightStackMin: 0, weightStackMax: 200, weightIncrement: 2.5,
            seatAdjustable: true, padAdjustable: false,
            camProfileNotes: "Linear leverage. Each arm independent (~7kg per arm tare).",
            setupInstructions: "Height > 185cm: seat at lowest, handles at lower chest. Height < 170cm: seat at 3-4. Grip width matches shoulder width."
        ),
        MachineExerciseData(
            exerciseName: "Incline Press (Hammer Strength)",
            category: "compound", primaryMuscle: "chest_upper",
            secondaryMuscles: "anterior_deltoid,triceps_long",
            tempoConcentric: 1.0, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "~30° press angle. Iso-lateral allows unilateral work to fix imbalances.",
            stretchBonus: true,
            machineName: "Hammer Strength ISO Incline Press", manufacturer: "Hammer Strength",
            machineType: "plate_loaded",
            resistanceProfile: "linear", startingResistance: 12.0,
            weightStackMin: 0, weightStackMax: 180, weightIncrement: 2.5,
            seatAdjustable: true, padAdjustable: false,
            camProfileNotes: "Linear leverage. 30° press angle.",
            setupInstructions: "Height > 180cm: seat at lowest. Handles should align with upper chest/clavicle at start."
        ),
        MachineExerciseData(
            exerciseName: "Decline Press (Hammer Strength)",
            category: "compound", primaryMuscle: "chest_lower",
            secondaryMuscles: "triceps_lateral,anterior_deltoid",
            tempoConcentric: 1.0, tempoEccentric: 2.5, tempoPause: 0.5,
            biomechanicalNotes: "Downward press angle. Reduced shoulder stress compared to flat/incline.",
            stretchBonus: true,
            machineName: "Hammer Strength ISO Decline Press", manufacturer: "Hammer Strength",
            machineType: "plate_loaded",
            resistanceProfile: "linear", startingResistance: 14.0,
            weightStackMin: 0, weightStackMax: 200, weightIncrement: 2.5,
            seatAdjustable: true, padAdjustable: false,
            camProfileNotes: "Linear leverage. Decline angle ~15°.",
            setupInstructions: "Height > 180cm: seat at lowest. Height < 170cm: seat at 2-3. Press path should feel natural."
        ),
        MachineExerciseData(
            exerciseName: "Shoulder Press (Hammer Strength)",
            category: "compound", primaryMuscle: "anterior_deltoid",
            secondaryMuscles: "lateral_deltoid,triceps_long",
            tempoConcentric: 1.0, tempoEccentric: 2.5, tempoPause: 0.5,
            biomechanicalNotes: "Iso-lateral overhead press. Converging arc mimics natural shoulder movement.",
            stretchBonus: false,
            machineName: "Hammer Strength ISO Shoulder Press", manufacturer: "Hammer Strength",
            machineType: "plate_loaded",
            resistanceProfile: "linear", startingResistance: 10.0,
            weightStackMin: 0, weightStackMax: 150, weightIncrement: 2.5,
            seatAdjustable: true, padAdjustable: false,
            camProfileNotes: "Linear leverage. Converging press arc.",
            setupInstructions: "Height > 185cm: seat at lowest, grips at shoulder level. Height < 170cm: seat at 3-4."
        ),
        MachineExerciseData(
            exerciseName: "Iso Row (Hammer Strength)",
            category: "compound", primaryMuscle: "lats_upper",
            secondaryMuscles: "traps_mid,rhomboids,biceps_long",
            tempoConcentric: 1.0, tempoEccentric: 3.0, tempoPause: 1.0,
            biomechanicalNotes: "Chest-supported, reduces lower back involvement. Iso-lateral for unilateral work.",
            stretchBonus: true,
            machineName: "Hammer Strength ISO Row", manufacturer: "Hammer Strength",
            machineType: "plate_loaded",
            resistanceProfile: "linear", startingResistance: 10.0,
            weightStackMin: 0, weightStackMax: 180, weightIncrement: 2.5,
            seatAdjustable: true, padAdjustable: true,
            camProfileNotes: "Linear leverage. Chest pad supported.",
            setupInstructions: "Chest pad at sternum. Height > 180cm: seat at lowest. Full stretch at bottom, squeeze at top."
        ),
        MachineExerciseData(
            exerciseName: "Lat Pull (Hammer Strength)",
            category: "compound", primaryMuscle: "lats_upper",
            secondaryMuscles: "biceps_long,rear_delts",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "Iso-lateral lat pull. Independent arms expose strength imbalances.",
            stretchBonus: true,
            machineName: "Hammer Strength ISO Lat Pull", manufacturer: "Hammer Strength",
            machineType: "plate_loaded",
            resistanceProfile: "linear", startingResistance: 8.0,
            weightStackMin: 0, weightStackMax: 160, weightIncrement: 2.5,
            seatAdjustable: true, padAdjustable: true,
            camProfileNotes: "Linear leverage. Wide grip handles.",
            setupInstructions: "Thigh pad snug. Height > 180cm: adjust thigh pad up. Full overhead stretch at top of each rep."
        ),
        MachineExerciseData(
            exerciseName: "Low Row (Hammer Strength)",
            category: "compound", primaryMuscle: "lats_lower",
            secondaryMuscles: "traps_mid,erector_spinae,biceps_short",
            tempoConcentric: 1.0, tempoEccentric: 2.5, tempoPause: 1.0,
            biomechanicalNotes: "Floor-based row. Targets lower lats and mid-back thickness.",
            stretchBonus: false,
            machineName: "Hammer Strength Low Row", manufacturer: "Hammer Strength",
            machineType: "plate_loaded",
            resistanceProfile: "linear", startingResistance: 12.0,
            weightStackMin: 0, weightStackMax: 200, weightIncrement: 2.5,
            seatAdjustable: true, padAdjustable: true,
            camProfileNotes: "Linear leverage. Floor-based.",
            setupInstructions: "Chest pad at mid-sternum. Height > 180cm: foot platform at furthest. Full extension at start."
        ),
        MachineExerciseData(
            exerciseName: "V-Squat (Hammer Strength)",
            category: "compound", primaryMuscle: "quadriceps",
            secondaryMuscles: "glute_max,hamstrings",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "V-shaped sled path. More upright torso than hack squat, reduced back stress.",
            stretchBonus: false,
            machineName: "Hammer Strength V-Squat", manufacturer: "Hammer Strength",
            machineType: "plate_loaded",
            resistanceProfile: "linear", startingResistance: 30.0,
            weightStackMin: 0, weightStackMax: 350, weightIncrement: 2.5,
            seatAdjustable: false, padAdjustable: true,
            camProfileNotes: "Linear leverage. V-track path. ~30kg tare.",
            setupInstructions: "Height > 185cm: feet higher on platform. Height < 170cm: feet mid-platform. Shoulder pads snug."
        ),

        // =============================================
        // MARK: - Panatta — FW/HP Line
        // =============================================

        MachineExerciseData(
            exerciseName: "Chest Press (Panatta FW)",
            category: "compound", primaryMuscle: "chest_upper",
            secondaryMuscles: "anterior_deltoid,triceps_lateral",
            tempoConcentric: 1.0, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "Descending cam — resistance decreases at lockout. Maximizes tension at stretched position.",
            stretchBonus: true,
            machineName: "Panatta FW Chest Press", manufacturer: "Panatta",
            machineType: "plate_loaded",
            resistanceProfile: "descending", startingResistance: 15.0,
            weightStackMin: 0, weightStackMax: 200, weightIncrement: 2.5,
            seatAdjustable: true, padAdjustable: true,
            camProfileNotes: "Descending cam — heaviest at stretch, lighter at lockout. Ideal for hypertrophy.",
            setupInstructions: "Height > 185cm: seat at position 1. Height < 170cm: seat at 4-5. Handles at nipple line."
        ),
        MachineExerciseData(
            exerciseName: "Shoulder Press (Panatta FW)",
            category: "compound", primaryMuscle: "anterior_deltoid",
            secondaryMuscles: "lateral_deltoid,triceps_long",
            tempoConcentric: 1.0, tempoEccentric: 2.5, tempoPause: 0.5,
            biomechanicalNotes: "Descending cam profile — max load at bottom where stretch is greatest.",
            stretchBonus: false,
            machineName: "Panatta FW Shoulder Press", manufacturer: "Panatta",
            machineType: "plate_loaded",
            resistanceProfile: "descending", startingResistance: 10.0,
            weightStackMin: 0, weightStackMax: 150, weightIncrement: 2.5,
            seatAdjustable: true, padAdjustable: false,
            camProfileNotes: "Descending cam — peak load at stretch.",
            setupInstructions: "Height > 185cm: seat at lowest. Handles at ear level in start position."
        ),
        MachineExerciseData(
            exerciseName: "Leg Press (Panatta HP)",
            category: "compound", primaryMuscle: "quadriceps",
            secondaryMuscles: "glute_max,hamstrings",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "Horizontal press with descending cam. Max resistance at deep position.",
            stretchBonus: false,
            machineName: "Panatta HP Leg Press", manufacturer: "Panatta",
            machineType: "plate_loaded",
            resistanceProfile: "descending", startingResistance: 40.0,
            weightStackMin: 0, weightStackMax: 500, weightIncrement: 2.5,
            seatAdjustable: true, padAdjustable: false,
            camProfileNotes: "Descending cam. ~40kg sled tare. Heaviest at bottom.",
            setupInstructions: "Height > 185cm: back pad fully reclined. Height < 170cm: back pad 2 notches forward. Feet shoulder-width."
        ),
        MachineExerciseData(
            exerciseName: "Lat Pulldown (Panatta FW)",
            category: "compound", primaryMuscle: "lats_upper",
            secondaryMuscles: "biceps_long,rear_delts",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 1.0,
            biomechanicalNotes: "Descending cam peaks resistance at full lat stretch. Superior for lat hypertrophy.",
            stretchBonus: true,
            machineName: "Panatta FW Lat Pulldown", manufacturer: "Panatta",
            machineType: "selectorized",
            resistanceProfile: "descending", startingResistance: 5.0,
            weightStackMin: 5, weightStackMax: 110, weightIncrement: 5.0,
            seatAdjustable: true, padAdjustable: true,
            camProfileNotes: "Descending cam — peak at stretch overhead.",
            setupInstructions: "Thigh pad snug. Height > 180cm: thigh pad up. Full stretch at top, slow eccentric."
        ),
        MachineExerciseData(
            exerciseName: "Seated Row (Panatta FW)",
            category: "compound", primaryMuscle: "lats_lower",
            secondaryMuscles: "traps_mid,rhomboids,biceps_short",
            tempoConcentric: 1.0, tempoEccentric: 3.0, tempoPause: 1.0,
            biomechanicalNotes: "Descending cam — heaviest at full arm extension for max lat stretch load.",
            stretchBonus: true,
            machineName: "Panatta FW Seated Row", manufacturer: "Panatta",
            machineType: "plate_loaded",
            resistanceProfile: "descending", startingResistance: 12.0,
            weightStackMin: 0, weightStackMax: 180, weightIncrement: 2.5,
            seatAdjustable: true, padAdjustable: true,
            camProfileNotes: "Descending cam — maximum resistance at stretch.",
            setupInstructions: "Chest pad at sternum. Height > 180cm: seat at lowest. Full arm extension at start."
        ),
        MachineExerciseData(
            exerciseName: "Hack Squat (Panatta HP)",
            category: "compound", primaryMuscle: "quadriceps",
            secondaryMuscles: "glute_max",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "Descending cam — heavier at bottom where quads are in stretch. Excellent for hypertrophy.",
            stretchBonus: true,
            machineName: "Panatta HP Hack Squat", manufacturer: "Panatta",
            machineType: "plate_loaded",
            resistanceProfile: "descending", startingResistance: 28.0,
            weightStackMin: 0, weightStackMax: 300, weightIncrement: 2.5,
            seatAdjustable: false, padAdjustable: true,
            camProfileNotes: "Descending cam. ~28kg sled tare.",
            setupInstructions: "Height > 185cm: feet low on platform for max quad stretch. Height < 170cm: feet mid-platform."
        ),

        // =============================================
        // MARK: - Eleiko — Prestera Line + Racks
        // =============================================

        MachineExerciseData(
            exerciseName: "Chest Press (Eleiko Prestera)",
            category: "compound", primaryMuscle: "chest_upper",
            secondaryMuscles: "anterior_deltoid,triceps_lateral",
            tempoConcentric: 1.0, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "Smooth linear resistance. Premium bearings for consistent feel throughout ROM.",
            stretchBonus: true,
            machineName: "Eleiko Prestera Chest Press", manufacturer: "Eleiko",
            machineType: "selectorized",
            resistanceProfile: "linear", startingResistance: 5.0,
            weightStackMin: 5, weightStackMax: 150, weightIncrement: 2.5,
            seatAdjustable: true, padAdjustable: false,
            camProfileNotes: "Linear resistance. Precision bearings.",
            setupInstructions: "Height > 185cm: seat at lowest. Height < 170cm: seat at 3-4. Handles at mid-chest."
        ),
        MachineExerciseData(
            exerciseName: "Leg Press (Eleiko Prestera)",
            category: "compound", primaryMuscle: "quadriceps",
            secondaryMuscles: "glute_max,hamstrings",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "Linear resistance, 45° sled. Precision engineering for smooth travel.",
            stretchBonus: false,
            machineName: "Eleiko Prestera Leg Press", manufacturer: "Eleiko",
            machineType: "plate_loaded",
            resistanceProfile: "linear", startingResistance: 32.0,
            weightStackMin: 0, weightStackMax: 400, weightIncrement: 2.5,
            seatAdjustable: true, padAdjustable: false,
            camProfileNotes: "Linear. 45° sled angle. ~32kg tare.",
            setupInstructions: "Height > 185cm: back pad fully reclined. Feet shoulder-width on mid-platform."
        ),
        MachineExerciseData(
            exerciseName: "Competition Squat Rack (Eleiko)",
            category: "compound", primaryMuscle: "quadriceps",
            secondaryMuscles: "glute_max,hamstrings,erector_spinae",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "IPF-spec squat rack with Eleiko competition barbell (20kg). Band pegs available.",
            stretchBonus: true,
            machineName: "Eleiko Competition Squat Rack", manufacturer: "Eleiko",
            machineType: "rack",
            resistanceProfile: "linear", startingResistance: 20.0,
            weightStackMin: 0, weightStackMax: 500, weightIncrement: 0.5,
            seatAdjustable: false, padAdjustable: false,
            camProfileNotes: "Free weight. Eleiko competition bar = 20kg.",
            setupInstructions: "J-hooks at armpit height. Height > 185cm: hooks at position 10-12. Height < 170cm: hooks at 7-8. Safety arms at parallel depth."
        ),
        MachineExerciseData(
            exerciseName: "Competition Bench Rack (Eleiko)",
            category: "compound", primaryMuscle: "chest_upper",
            secondaryMuscles: "anterior_deltoid,triceps_lateral",
            tempoConcentric: 1.0, tempoEccentric: 2.5, tempoPause: 0.5,
            biomechanicalNotes: "IPF-spec bench with Eleiko competition barbell. Precise J-hook spacing.",
            stretchBonus: true,
            machineName: "Eleiko Competition Bench", manufacturer: "Eleiko",
            machineType: "rack",
            resistanceProfile: "linear", startingResistance: 20.0,
            weightStackMin: 0, weightStackMax: 400, weightIncrement: 0.5,
            seatAdjustable: false, padAdjustable: false,
            camProfileNotes: "Free weight. Eleiko competition bar = 20kg.",
            setupInstructions: "Eyes under bar. Height > 185cm: wider unrack width. Arch and leg drive, bar path to lower chest."
        ),

        // =============================================
        // MARK: - Technogym — Selection Line
        // =============================================

        MachineExerciseData(
            exerciseName: "Chest Press (Technogym Selection)",
            category: "compound", primaryMuscle: "chest_upper",
            secondaryMuscles: "anterior_deltoid,triceps_lateral",
            tempoConcentric: 1.0, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "Weight stack with smooth linear feel. Ergonomic handle positions.",
            stretchBonus: true,
            machineName: "Technogym Selection Chest Press", manufacturer: "Technogym",
            machineType: "selectorized",
            resistanceProfile: "linear", startingResistance: 4.0,
            weightStackMin: 5, weightStackMax: 100, weightIncrement: 5.0,
            seatAdjustable: true, padAdjustable: false,
            camProfileNotes: "Linear weight stack. Smooth cable-pulley system.",
            setupInstructions: "Height > 180cm: seat at lowest. Height < 170cm: seat at 3-4. Handles at mid-chest height."
        ),
        MachineExerciseData(
            exerciseName: "Shoulder Press (Technogym Selection)",
            category: "compound", primaryMuscle: "anterior_deltoid",
            secondaryMuscles: "lateral_deltoid,triceps_long",
            tempoConcentric: 1.0, tempoEccentric: 2.5, tempoPause: 0.5,
            biomechanicalNotes: "Converging press path with linear resistance. Comfortable for all body types.",
            stretchBonus: false,
            machineName: "Technogym Selection Shoulder Press", manufacturer: "Technogym",
            machineType: "selectorized",
            resistanceProfile: "linear", startingResistance: 4.0,
            weightStackMin: 5, weightStackMax: 100, weightIncrement: 5.0,
            seatAdjustable: true, padAdjustable: false,
            camProfileNotes: "Linear weight stack.",
            setupInstructions: "Handles at ear level when seated. Height > 180cm: seat at lowest."
        ),
        MachineExerciseData(
            exerciseName: "Lat Machine (Technogym Selection)",
            category: "compound", primaryMuscle: "lats_upper",
            secondaryMuscles: "biceps_long,rear_delts",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "Standard lat pulldown with smooth cable path. Reliable for progressive overload.",
            stretchBonus: true,
            machineName: "Technogym Selection Lat Machine", manufacturer: "Technogym",
            machineType: "selectorized",
            resistanceProfile: "linear", startingResistance: 4.0,
            weightStackMin: 5, weightStackMax: 100, weightIncrement: 5.0,
            seatAdjustable: true, padAdjustable: true,
            camProfileNotes: "Linear weight stack.",
            setupInstructions: "Thigh pads snug. Height > 180cm: adjust up. Grip slightly wider than shoulders."
        ),
        MachineExerciseData(
            exerciseName: "Leg Press (Technogym Selection)",
            category: "compound", primaryMuscle: "quadriceps",
            secondaryMuscles: "glute_max,hamstrings",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "Selectorized leg press with linear resistance. Lower max load than plate-loaded.",
            stretchBonus: false,
            machineName: "Technogym Selection Leg Press", manufacturer: "Technogym",
            machineType: "selectorized",
            resistanceProfile: "linear", startingResistance: 10.0,
            weightStackMin: 10, weightStackMax: 200, weightIncrement: 5.0,
            seatAdjustable: true, padAdjustable: false,
            camProfileNotes: "Linear weight stack. Lower max capacity.",
            setupInstructions: "Height > 180cm: back pad reclined. Feet shoulder-width, mid-platform."
        ),
        MachineExerciseData(
            exerciseName: "Leg Extension (Technogym Selection)",
            category: "isolation", primaryMuscle: "quadriceps",
            secondaryMuscles: "",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 1.0,
            biomechanicalNotes: "Smooth linear resistance. Seat back angle adjustable for RF stretch.",
            stretchBonus: true,
            machineName: "Technogym Selection Leg Extension", manufacturer: "Technogym",
            machineType: "selectorized",
            resistanceProfile: "linear", startingResistance: 3.0,
            weightStackMin: 5, weightStackMax: 100, weightIncrement: 5.0,
            seatAdjustable: true, padAdjustable: true,
            camProfileNotes: "Linear weight stack.",
            setupInstructions: "Pivot at lateral knee. Height > 180cm: back pad reclined for stretch. Ankle pad on lower shins."
        ),
        MachineExerciseData(
            exerciseName: "Leg Curl (Technogym Selection)",
            category: "isolation", primaryMuscle: "hamstrings",
            secondaryMuscles: "",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "Prone leg curl. Linear resistance, smooth cable path.",
            stretchBonus: true,
            machineName: "Technogym Selection Prone Leg Curl", manufacturer: "Technogym",
            machineType: "selectorized",
            resistanceProfile: "linear", startingResistance: 3.0,
            weightStackMin: 5, weightStackMax: 80, weightIncrement: 5.0,
            seatAdjustable: false, padAdjustable: true,
            camProfileNotes: "Linear weight stack.",
            setupInstructions: "Hips flat on bench. Ankle pad just above heel. Height > 180cm: pad at lowest position."
        ),
        MachineExerciseData(
            exerciseName: "Seated Row (Technogym Selection)",
            category: "compound", primaryMuscle: "lats_lower",
            secondaryMuscles: "traps_mid,rhomboids,biceps_short",
            tempoConcentric: 1.0, tempoEccentric: 3.0, tempoPause: 1.0,
            biomechanicalNotes: "Selectorized seated row. Chest pad support, linear resistance.",
            stretchBonus: true,
            machineName: "Technogym Selection Seated Row", manufacturer: "Technogym",
            machineType: "selectorized",
            resistanceProfile: "linear", startingResistance: 4.0,
            weightStackMin: 5, weightStackMax: 100, weightIncrement: 5.0,
            seatAdjustable: true, padAdjustable: true,
            camProfileNotes: "Linear weight stack.",
            setupInstructions: "Chest pad at sternum. Height > 180cm: seat at lowest. Full extension at start."
        ),
        MachineExerciseData(
            exerciseName: "Rear Delt Fly (Technogym Selection)",
            category: "isolation", primaryMuscle: "posterior_deltoid",
            secondaryMuscles: "traps_mid,rhomboids",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 1.0,
            biomechanicalNotes: "Pec deck reversed for rear delts. Smooth linear resistance.",
            stretchBonus: true,
            machineName: "Technogym Selection Pec Deck/Rear Delt", manufacturer: "Technogym",
            machineType: "selectorized",
            resistanceProfile: "linear", startingResistance: 3.0,
            weightStackMin: 5, weightStackMax: 80, weightIncrement: 5.0,
            seatAdjustable: true, padAdjustable: false,
            camProfileNotes: "Linear weight stack. Dual function pec/rear delt.",
            setupInstructions: "Handles at shoulder height. Height > 180cm: seat at lowest. Slight forward lean for rear delt bias."
        ),
        MachineExerciseData(
            exerciseName: "Abdominal Crunch (Technogym Selection)",
            category: "isolation", primaryMuscle: "rectus_abdominis",
            secondaryMuscles: "obliques",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 1.0,
            biomechanicalNotes: "Selectorized ab crunch. Controlled spinal flexion with adjustable resistance.",
            stretchBonus: true,
            machineName: "Technogym Selection Ab Crunch", manufacturer: "Technogym",
            machineType: "selectorized",
            resistanceProfile: "linear", startingResistance: 3.0,
            weightStackMin: 5, weightStackMax: 80, weightIncrement: 5.0,
            seatAdjustable: true, padAdjustable: true,
            camProfileNotes: "Linear weight stack.",
            setupInstructions: "Chest pad at upper chest. Focus on spinal flexion, not hip flexion."
        ),
    ]
}
