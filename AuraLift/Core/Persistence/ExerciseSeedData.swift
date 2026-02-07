import Foundation

/// Pre-loaded exercise database with major compound and isolation lifts.
struct ExerciseSeedData {
    struct ExerciseData {
        let name: String
        let category: String         // "compound" or "isolation"
        let primaryMuscle: String    // MuscleGroupType raw value
        let secondaryMuscles: String // Comma-separated
        let equipmentType: String    // EquipmentType raw value
        let tempoConcentric: Double
        let tempoEccentric: Double
        let tempoPause: Double
        let biomechanicalNotes: String
        let stretchBonus: Bool
        let riskLevel: String        // ExerciseRisk raw value
    }

    static let allExercises: [ExerciseData] = [
        // MARK: - Compound Lower Body

        ExerciseData(
            name: "Barbell Back Squat",
            category: "compound",
            primaryMuscle: "quadriceps",
            secondaryMuscles: "glute_max,hamstrings,erector_spinae",
            equipmentType: "barbell",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "Long femurs increase forward lean. Consider heel elevation or front squat variant.",
            stretchBonus: true,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Barbell Front Squat",
            category: "compound",
            primaryMuscle: "quadriceps",
            secondaryMuscles: "glute_max,rectus_abdominis",
            equipmentType: "barbell",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "More upright torso position. Better for long-femured lifters.",
            stretchBonus: true,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Romanian Deadlift",
            category: "compound",
            primaryMuscle: "hamstrings",
            secondaryMuscles: "glute_max,erector_spinae",
            equipmentType: "barbell",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 1.0,
            biomechanicalNotes: "Excellent stretch-mediated hypertrophy for hamstrings. Maintain neutral spine.",
            stretchBonus: true,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Conventional Deadlift",
            category: "compound",
            primaryMuscle: "erector_spinae",
            secondaryMuscles: "glute_max,hamstrings,quadriceps,forearms",
            equipmentType: "barbell",
            tempoConcentric: 1.0, tempoEccentric: 2.0, tempoPause: 0.5,
            biomechanicalNotes: "Long torso + short arms increases lower back demand. Consider sumo variant.",
            stretchBonus: false,
            riskLevel: "caution"
        ),
        ExerciseData(
            name: "Sumo Deadlift",
            category: "compound",
            primaryMuscle: "glute_max",
            secondaryMuscles: "quadriceps,hamstrings,adductors",
            equipmentType: "barbell",
            tempoConcentric: 1.0, tempoEccentric: 2.0, tempoPause: 0.5,
            biomechanicalNotes: "Shorter range of motion. Better for long-torso, short-arm lifters.",
            stretchBonus: false,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Bulgarian Split Squat",
            category: "compound",
            primaryMuscle: "quadriceps",
            secondaryMuscles: "glute_max,hamstrings",
            equipmentType: "dumbbell",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 1.0,
            biomechanicalNotes: "Great stretch on hip flexors and quads. Addresses bilateral deficits.",
            stretchBonus: true,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Leg Press",
            category: "compound",
            primaryMuscle: "quadriceps",
            secondaryMuscles: "glute_max,hamstrings",
            equipmentType: "machine",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "Foot position alters emphasis. High and wide = more glute/hamstring.",
            stretchBonus: false,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Hip Thrust",
            category: "compound",
            primaryMuscle: "glute_max",
            secondaryMuscles: "hamstrings",
            equipmentType: "barbell",
            tempoConcentric: 1.0, tempoEccentric: 2.0, tempoPause: 1.0,
            biomechanicalNotes: "Peak contraction at lockout. Optimal glute activation pattern.",
            stretchBonus: false,
            riskLevel: "optimal"
        ),

        // MARK: - Isolation Lower Body

        ExerciseData(
            name: "Leg Extension",
            category: "isolation",
            primaryMuscle: "quadriceps",
            secondaryMuscles: "",
            equipmentType: "machine",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 1.0,
            biomechanicalNotes: "High stretch at bottom position. Seat back position affects rectus femoris stretch.",
            stretchBonus: true,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Leg Curl (Lying)",
            category: "isolation",
            primaryMuscle: "hamstrings",
            secondaryMuscles: "",
            equipmentType: "machine",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "Stretches hamstrings at the hip. Avoid hyperextending lower back.",
            stretchBonus: true,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Calf Raise (Standing)",
            category: "isolation",
            primaryMuscle: "calves",
            secondaryMuscles: "",
            equipmentType: "machine",
            tempoConcentric: 1.0, tempoEccentric: 3.0, tempoPause: 2.0,
            biomechanicalNotes: "Full ROM critical. 2-second stretch at bottom for soleus recruitment.",
            stretchBonus: true,
            riskLevel: "optimal"
        ),

        // MARK: - Compound Upper Body (Push)

        ExerciseData(
            name: "Barbell Bench Press",
            category: "compound",
            primaryMuscle: "chest_upper",
            secondaryMuscles: "anterior_deltoid,triceps_long,triceps_lateral",
            equipmentType: "barbell",
            tempoConcentric: 1.0, tempoEccentric: 2.5, tempoPause: 0.5,
            biomechanicalNotes: "Long arms increase ROM. Arch reduces effective range but protects shoulders.",
            stretchBonus: true,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Incline Barbell Press",
            category: "compound",
            primaryMuscle: "chest_upper",
            secondaryMuscles: "anterior_deltoid,triceps_long",
            equipmentType: "barbell",
            tempoConcentric: 1.0, tempoEccentric: 2.5, tempoPause: 0.5,
            biomechanicalNotes: "30-45 degree angle optimal for upper chest. Steeper angles shift to front delts.",
            stretchBonus: true,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Dumbbell Bench Press",
            category: "compound",
            primaryMuscle: "chest_lower",
            secondaryMuscles: "anterior_deltoid,triceps_long",
            equipmentType: "dumbbell",
            tempoConcentric: 1.0, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "Greater ROM than barbell. Better pec stretch at bottom.",
            stretchBonus: true,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Overhead Press",
            category: "compound",
            primaryMuscle: "anterior_deltoid",
            secondaryMuscles: "lateral_deltoid,triceps_long,traps_upper",
            equipmentType: "barbell",
            tempoConcentric: 1.0, tempoEccentric: 2.5, tempoPause: 0.5,
            biomechanicalNotes: "Shoulder mobility required. Long-armed lifters have mechanical disadvantage.",
            stretchBonus: false,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Dips (Chest)",
            category: "compound",
            primaryMuscle: "chest_lower",
            secondaryMuscles: "anterior_deltoid,triceps_long,triceps_lateral",
            equipmentType: "bodyweight",
            tempoConcentric: 1.0, tempoEccentric: 3.0, tempoPause: 1.0,
            biomechanicalNotes: "Forward lean emphasizes chest. Upright emphasizes triceps. Watch shoulder depth.",
            stretchBonus: true,
            riskLevel: "caution"
        ),

        // MARK: - Compound Upper Body (Pull)

        ExerciseData(
            name: "Barbell Row",
            category: "compound",
            primaryMuscle: "lats_upper",
            secondaryMuscles: "traps_mid,rhomboids,biceps_long,rear_delts",
            equipmentType: "barbell",
            tempoConcentric: 1.0, tempoEccentric: 2.5, tempoPause: 0.5,
            biomechanicalNotes: "Torso angle affects lat vs. trap recruitment. More upright = more traps.",
            stretchBonus: false,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Pull-Up",
            category: "compound",
            primaryMuscle: "lats_upper",
            secondaryMuscles: "biceps_long,biceps_short,forearms,rear_delts",
            equipmentType: "bodyweight",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "Wide grip = more lat width. Narrow/chin-up = more biceps and lat stretch.",
            stretchBonus: true,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Lat Pulldown",
            category: "compound",
            primaryMuscle: "lats_upper",
            secondaryMuscles: "biceps_long,forearms,rear_delts",
            equipmentType: "cable",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "Slight lean back engages more lats. Full stretch at top critical.",
            stretchBonus: true,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Seated Cable Row",
            category: "compound",
            primaryMuscle: "lats_lower",
            secondaryMuscles: "traps_mid,rhomboids,biceps_short",
            equipmentType: "cable",
            tempoConcentric: 1.0, tempoEccentric: 2.5, tempoPause: 1.0,
            biomechanicalNotes: "V-grip for lower lats. Wide grip for upper back thickness.",
            stretchBonus: true,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "T-Bar Row",
            category: "compound",
            primaryMuscle: "lats_lower",
            secondaryMuscles: "traps_mid,rhomboids,erector_spinae",
            equipmentType: "barbell",
            tempoConcentric: 1.0, tempoEccentric: 2.5, tempoPause: 0.5,
            biomechanicalNotes: "Neutral grip reduces bicep involvement. Good for thickness.",
            stretchBonus: false,
            riskLevel: "optimal"
        ),

        // MARK: - Isolation Upper Body

        ExerciseData(
            name: "Cable Fly",
            category: "isolation",
            primaryMuscle: "chest_upper",
            secondaryMuscles: "anterior_deltoid",
            equipmentType: "cable",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 1.0,
            biomechanicalNotes: "Constant tension through ROM. Adjust cable height for upper/lower emphasis.",
            stretchBonus: true,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Lateral Raise",
            category: "isolation",
            primaryMuscle: "lateral_deltoid",
            secondaryMuscles: "traps_upper",
            equipmentType: "dumbbell",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "Slight forward lean reduces impingement risk. Control the negative.",
            stretchBonus: false,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Cable Lateral Raise",
            category: "isolation",
            primaryMuscle: "lateral_deltoid",
            secondaryMuscles: "",
            equipmentType: "cable",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "Better resistance curve than dumbbells. Behind-body position for stretch.",
            stretchBonus: true,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Face Pull",
            category: "isolation",
            primaryMuscle: "rear_delts",
            secondaryMuscles: "traps_mid,rhomboids",
            equipmentType: "cable",
            tempoConcentric: 1.0, tempoEccentric: 2.0, tempoPause: 1.0,
            biomechanicalNotes: "External rotation at end range. Critical for shoulder health.",
            stretchBonus: false,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Barbell Curl",
            category: "isolation",
            primaryMuscle: "biceps_short",
            secondaryMuscles: "biceps_long,brachialis",
            equipmentType: "barbell",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "EZ-bar reduces wrist strain. Strict form prevents momentum cheating.",
            stretchBonus: false,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Incline Dumbbell Curl",
            category: "isolation",
            primaryMuscle: "biceps_long",
            secondaryMuscles: "biceps_short",
            equipmentType: "dumbbell",
            tempoConcentric: 1.5, tempoEccentric: 3.5, tempoPause: 0.5,
            biomechanicalNotes: "Maximizes long head stretch. Incline bench at 45-60 degrees.",
            stretchBonus: true,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Tricep Pushdown",
            category: "isolation",
            primaryMuscle: "triceps_lateral",
            secondaryMuscles: "triceps_medial",
            equipmentType: "cable",
            tempoConcentric: 1.0, tempoEccentric: 2.5, tempoPause: 0.5,
            biomechanicalNotes: "Rope for peak contraction, bar for heavier loads.",
            stretchBonus: false,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Overhead Tricep Extension",
            category: "isolation",
            primaryMuscle: "triceps_long",
            secondaryMuscles: "",
            equipmentType: "cable",
            tempoConcentric: 1.0, tempoEccentric: 3.0, tempoPause: 1.0,
            biomechanicalNotes: "Stretches long head maximally. Critical for tricep hypertrophy.",
            stretchBonus: true,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Rear Delt Fly (Machine)",
            category: "isolation",
            primaryMuscle: "posterior_deltoid",
            secondaryMuscles: "traps_mid,rhomboids",
            equipmentType: "machine",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 1.0,
            biomechanicalNotes: "Slow negatives for maximum time under tension.",
            stretchBonus: true,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Dumbbell Shrug",
            category: "isolation",
            primaryMuscle: "traps_upper",
            secondaryMuscles: "",
            equipmentType: "dumbbell",
            tempoConcentric: 1.0, tempoEccentric: 2.0, tempoPause: 1.5,
            biomechanicalNotes: "Elevate and squeeze. Avoid rolling shoulders.",
            stretchBonus: false,
            riskLevel: "optimal"
        ),

        // MARK: - Core

        ExerciseData(
            name: "Cable Crunch",
            category: "isolation",
            primaryMuscle: "rectus_abdominis",
            secondaryMuscles: "obliques",
            equipmentType: "cable",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 1.0,
            biomechanicalNotes: "Flex spine, don't hip hinge. Progressive overload with cable weight.",
            stretchBonus: true,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Hanging Leg Raise",
            category: "isolation",
            primaryMuscle: "rectus_abdominis",
            secondaryMuscles: "obliques",
            equipmentType: "bodyweight",
            tempoConcentric: 1.5, tempoEccentric: 3.0, tempoPause: 0.5,
            biomechanicalNotes: "Posterior pelvic tilt at top. Avoid swinging.",
            stretchBonus: true,
            riskLevel: "optimal"
        ),
        ExerciseData(
            name: "Pallof Press",
            category: "isolation",
            primaryMuscle: "obliques",
            secondaryMuscles: "transverse_abdominis,rectus_abdominis",
            equipmentType: "cable",
            tempoConcentric: 1.5, tempoEccentric: 1.5, tempoPause: 2.0,
            biomechanicalNotes: "Anti-rotation training. Hold at full extension for core stability.",
            stretchBonus: false,
            riskLevel: "optimal"
        ),
    ]
}
