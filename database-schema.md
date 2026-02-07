# Database Schema — CoreData

> Programmatic CoreData model for AuraLift (no .xcdatamodeld)

## Overview

All 12 entities are built in `PersistenceController.buildManagedObjectModel()`. The model is 100% code-defined using `NSEntityDescription`, `NSAttributeDescription`, and `NSRelationshipDescription`.

**Persistence:** `NSPersistentContainer` with SQLite store (in-memory for previews)
**Merge Policy:** `NSMergeByPropertyObjectTrumpMergePolicy`
**Auto-merge:** `automaticallyMergesChangesFromParent = true`

---

## Entity Relationship Diagram

```
┌──────────────────┐     1:N     ┌──────────────────┐
│   UserProfile    │────────────►│    MorphoScan    │
│                  │             └──────────────────┘
│  id (UUID)       │
│  username        │     1:N     ┌──────────────────┐     1:N (ordered)
│  email?          │────────────►│ WorkoutSession   │────────────────────►┌────────────────┐
│  heightCm        │             │  totalVolume     │                     │  WorkoutSet    │
│  weightKg        │             │  averageFormScore│                     │  reps, weightKg│
│  currentRankTier │             │  comboMultiplier │                     │  formScore     │
│  currentLP       │             └──────────────────┘                     │  velocity data │
│  totalXP         │                                                      └───────┬────────┘
│                  │     1:N     ┌──────────────────┐                             │ N:1
│                  │────────────►│  RankingRecord   │                     ┌───────┴────────┐
│                  │             └──────────────────┘                     │    Exercise    │
│                  │                                                      │  name, category│
│                  │     1:N     ┌──────────────────┐                     │  tempo defaults│
│                  │────────────►│RecoverySnapshot  │                     │  riskLevel     │
│                  │             └──────────────────┘                     └───┬───────┬────┘
│                  │                      ▲                                   │       │
│                  │     1:N     ┌────────┴─────────┐              1:1 opt   │  M:N  │
│                  │────────────►│  NutritionLog    │       ┌────────────────┘       │
│                  │             └──────────────────┘       ▼                        ▼
│                  │                                 ┌────────────┐         ┌──────────────┐
│                  │     1:1 opt                     │ MachineSpec│         │ MuscleGroup  │
│                  │────────────►GuildMembership     │            │         │ recovery data│
└──────────────────┘                                 └────────────┘         └──────────────┘
```

---

## Core Entities

### UserProfile
The central user entity. All workout, ranking, and recovery data relates back here.

| Attribute | Type | Optional | Default | Description |
|-----------|------|----------|---------|-------------|
| id | UUID | NO | auto | Primary key |
| username | String | NO | | Display name |
| email | String | YES | | Email address |
| dateOfBirth | Date | YES | | Birthday |
| biologicalSex | String | YES | | male/female/other |
| heightCm | Double | YES | | Height in cm |
| weightKg | Double | YES | | Weight in kg |
| bodyFatPercentage | Double | YES | | Body fat % |
| currentRankTier | String | YES | "iron" | RankTier raw value |
| currentLP | Int32 | YES | 0 | Legend Points |
| totalXP | Int64 | YES | 0 | Experience points |
| createdAt | Date | NO | | Creation timestamp |
| updatedAt | Date | NO | | Last update |

**Relationships:** morphoScans (1:N), workoutSessions (1:N), rankingRecords (1:N), recoverySnapshots (1:N), nutritionLogs (1:N), guildMembership (1:1 optional)

---

### MorphoScan
Morpho-anatomical body scan storing limb ratios for biomechanical exercise recommendations.

| Attribute | Type | Optional | Description |
|-----------|------|----------|-------------|
| id | UUID | NO | Primary key |
| scanDate | Date | NO | When scan was taken |
| torsoLength | Double | YES | Torso length (cm) |
| femurLength | Double | YES | Femur length (cm) |
| tibiaLength | Double | YES | Tibia length (cm) |
| humerusLength | Double | YES | Humerus length (cm) |
| forearmLength | Double | YES | Forearm length (cm) |
| shoulderWidth | Double | YES | Biacromial width (cm) |
| hipWidth | Double | YES | Hip width (cm) |
| armSpan | Double | YES | Full arm span (cm) |
| femurToTorsoRatio | Double | YES | Computed ratio |
| tibiaToFemurRatio | Double | YES | Computed ratio |
| humerusToTorsoRatio | Double | YES | Computed ratio |
| rawPoseData | Binary | YES | Raw Vision pose data |

**Relationships:** userProfile (N:1)

---

### Exercise
Exercise definitions with biomechanical metadata and tempo defaults.

| Attribute | Type | Optional | Default | Description |
|-----------|------|----------|---------|-------------|
| id | UUID | NO | | Primary key |
| name | String | NO | | Exercise name |
| category | String | YES | | push/pull/legs/core |
| primaryMuscle | String | YES | | Main target muscle |
| secondaryMuscles | String | YES | | Comma-separated list |
| equipmentType | String | YES | | EquipmentType raw value |
| defaultTempoConcentric | Double | YES | 1.0 | Concentric tempo (s) |
| defaultTempoEccentric | Double | YES | 3.0 | Eccentric tempo (s) |
| defaultTempoPause | Double | YES | 0.5 | Pause tempo (s) |
| biomechanicalNotes | String | YES | | Leverage/ROM notes |
| stretchPositionBonus | Bool | YES | false | Stretch-mediated hypertrophy |
| riskLevel | String | YES | "optimal" | ExerciseRisk raw value |
| isCustom | Bool | YES | false | User-created exercise |

**Relationships:** machineSpec (1:1 optional), workoutSets (1:N), muscleGroups (M:N)

---

### MachineSpec
Gym machine specifications for form cues and setup.

| Attribute | Type | Optional | Default | Description |
|-----------|------|----------|---------|-------------|
| id | UUID | NO | | Primary key |
| machineName | String | NO | | Machine name |
| manufacturer | String | YES | | Brand |
| machineType | String | YES | | cable/plate-loaded/etc |
| cablePositionHigh | Bool | YES | false | High cable attachment |
| cablePositionMid | Bool | YES | false | Mid cable attachment |
| cablePositionLow | Bool | YES | false | Low cable attachment |
| seatAdjustable | Bool | YES | false | Has seat adjustment |
| padAdjustable | Bool | YES | false | Has pad adjustment |
| weightStackMin | Double | YES | | Min weight (kg) |
| weightStackMax | Double | YES | | Max weight (kg) |
| weightIncrement | Double | YES | | Increment size (kg) |
| camProfileNotes | String | YES | | Cam/leverage notes |
| setupInstructions | String | YES | | Setup guidance |

**Relationships:** exercise (N:1)

---

### WorkoutSession
A single workout session with aggregated performance metrics.

| Attribute | Type | Optional | Default | Description |
|-----------|------|----------|---------|-------------|
| id | UUID | NO | | Primary key |
| startTime | Date | NO | | Session start |
| endTime | Date | YES | | Session end |
| totalVolume | Double | YES | | Total kg lifted |
| totalXPEarned | Int32 | YES | 0 | XP earned this session |
| lpChange | Int32 | YES | 0 | LP gained/lost |
| averageFormScore | Double | YES | | Mean form score (0-100) |
| comboMultiplier | Double | YES | 1.0 | Peak combo achieved |
| peakVelocity | Double | YES | | Max bar velocity (m/s) |
| sessionNotes | String | YES | | User notes |

**Relationships:** userProfile (N:1), workoutSets (1:N ordered)

---

### WorkoutSet
Individual set with real-time velocity, form, and tempo data.

| Attribute | Type | Optional | Default | Description |
|-----------|------|----------|---------|-------------|
| id | UUID | NO | | Primary key |
| setNumber | Int16 | YES | | Set # in session |
| reps | Int16 | YES | | Rep count |
| weightKg | Double | YES | | Load in kg |
| averageConcentricVelocity | Double | YES | | Mean concentric m/s |
| peakConcentricVelocity | Double | YES | | Peak concentric m/s |
| velocityLossPercent | Double | YES | | Velocity decay (%) |
| autoStopped | Bool | YES | false | Auto-stopped by VBT |
| formScore | Double | YES | | Form quality (0-100) |
| barPathDeviation | Double | YES | | Bar path deviation |
| romDegrees | Double | YES | | Range of motion (deg) |
| tempoActualConcentric | Double | YES | | Actual concentric tempo |
| tempoActualEccentric | Double | YES | | Actual eccentric tempo |
| rpe | Double | YES | | Rate of perceived exertion |
| xpEarned | Int32 | YES | 0 | XP for this set |
| comboTag | String | YES | | Combo identifier |
| timestamp | Date | YES | | Set completion time |

**Relationships:** exercise (N:1), workoutSession (N:1)

---

### RankingRecord
Historical ranking snapshots for progress tracking.

| Attribute | Type | Optional | Description |
|-----------|------|----------|-------------|
| id | UUID | NO | Primary key |
| recordDate | Date | NO | Snapshot date |
| tier | String | YES | RankTier raw value |
| lpAtRecord | Int32 | YES | LP at time of record |
| strengthToWeightRatio | Double | YES | Strength/weight metric |
| formQualityAverage | Double | YES | Rolling form average |
| velocityScore | Double | YES | Velocity performance |

**Relationships:** userProfile (N:1)

---

### MuscleGroup
Muscle groups for recovery tracking and exercise targeting.

| Attribute | Type | Optional | Default | Description |
|-----------|------|----------|---------|-------------|
| id | UUID | NO | | Primary key |
| name | String | NO | | MuscleGroupType display name |
| bodyRegion | String | YES | | upper/lower/core |
| currentRecoveryScore | Double | YES | 100.0 | Recovery % (0-100) |
| weeklyVolumeSets | Int16 | YES | 0 | Sets this week |
| lastTrainedDate | Date | YES | | Last training date |

**Relationships:** exercises (M:N), recoverySnapshots (1:N)

---

### RecoverySnapshot
Daily recovery metrics from HealthKit and user input.

| Attribute | Type | Optional | Description |
|-----------|------|----------|-------------|
| id | UUID | NO | Primary key |
| snapshotDate | Date | NO | Date of snapshot |
| hrvValue | Double | YES | Heart Rate Variability (ms) |
| sleepHours | Double | YES | Total sleep (hours) |
| sleepQualityScore | Double | YES | Sleep quality (0-100) |
| restingHeartRate | Double | YES | Resting HR (bpm) |
| activeEnergyBurned | Double | YES | Active kcal |
| cyclePhase | String | YES | CyclePhase raw value |
| overallReadiness | Double | YES | Computed readiness (0-100) |

**Relationships:** userProfile (N:1), muscleGroup (N:1 optional)

---

### NutritionLog
Daily nutrition tracking with macro and supplement data.

| Attribute | Type | Optional | Description |
|-----------|------|----------|-------------|
| id | UUID | NO | Primary key |
| logDate | Date | NO | Date of log |
| targetCalories | Double | YES | Goal kcal |
| actualCalories | Double | YES | Consumed kcal |
| proteinGrams | Double | YES | Protein (g) |
| carbsGrams | Double | YES | Carbs (g) |
| fatGrams | Double | YES | Fat (g) |
| waterLiters | Double | YES | Water intake (L) |
| creatineGrams | Double | YES | Creatine (g) |
| wheyProteinGrams | Double | YES | Whey protein (g) |

**Relationships:** userProfile (N:1)

---

### ScienceInsight
Science-based training protocol updates (standalone, no relationships).

| Attribute | Type | Optional | Default | Description |
|-----------|------|----------|---------|-------------|
| id | UUID | NO | | Primary key |
| fetchDate | Date | NO | | When fetched |
| topic | String | YES | | Research topic |
| source | String | YES | | Source/citation |
| summary | String | YES | | Plain-language summary |
| recommendedTempoChange | String | YES | | Tempo adjustment |
| recommendedRestChange | String | YES | | Rest period adjustment |
| appliedToExercises | String | YES | | Affected exercises |
| isActive | Bool | YES | true | Currently active |

---

### GuildMembership
E-sport guild/team membership for social features.

| Attribute | Type | Optional | Default | Description |
|-----------|------|----------|---------|-------------|
| id | UUID | NO | | Primary key |
| guildName | String | NO | | Guild name |
| guildTag | String | YES | | Short tag (e.g. [AUR]) |
| joinDate | Date | NO | | Date joined |
| role | String | YES | "member" | member/officer/leader |
| guildWarWins | Int32 | YES | 0 | War victories |
| guildWarLosses | Int32 | YES | 0 | War defeats |

**Relationships:** userProfile (N:1)

---

## Enums (5)

| Enum | Cases | Usage |
|------|-------|-------|
| `RankTier` | iron, bronze, silver, gold, platinum, diamond, master, grandmaster, challenger | UserProfile.currentRankTier, RankingRecord.tier |
| `EquipmentType` | barbell, dumbbell, cable, machine, smithMachine, bodyweight, band, kettlebell | Exercise.equipmentType |
| `ExerciseRisk` | optimal, caution, highRisk | Exercise.riskLevel (morpho-based) |
| `MuscleGroupType` | 30 individual muscles (chest_upper, lats_lower, quadriceps, etc.) | MuscleGroup.name mapping |
| `CyclePhase` | menstrual, follicular, ovulatory, luteal | RecoverySnapshot.cyclePhase |

---

## Seed Data

`SeedDataLoader` handles first-launch seeding:
- **Exercises**: Pre-loaded compound and isolation movements with tempo defaults
- **MuscleGroups**: All 30 muscle groups from `MuscleGroupType` with body regions

`ExerciseSeedData` provides the exercise catalog.
