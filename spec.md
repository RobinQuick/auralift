# Product Specification — AuraLift

> AI-driven iOS bodybuilding app with Computer Vision, Biomechanics, and E-sport Gamification

## Overview

**Product Name:** AuraLift
**One-liner:** The first bodybuilding app that sees your body, understands your anatomy, and gamifies every rep.
**Problem Statement:** Most lifters train with generic programs that ignore their unique skeletal proportions, have no real-time form feedback, and lack meaningful motivation systems beyond basic logging.

## Target Users

| Persona | Description | Primary Goal |
|---------|-------------|--------------|
| Intermediate Lifter | 1-3 years experience, understands basics | Optimize training for their body type, track velocity |
| Form-Obsessed Athlete | Any level, injury-conscious | Real-time form scoring to prevent injuries |
| Competitive Soul | Gamification-driven, social | Rank up, compete on leaderboards, earn XP |

## Core Features (10 Phases)

### Phase 1: Foundation (COMPLETE)
- **What:** App skeleton, CoreData model (12 entities), cyberpunk theme, tab navigation
- **Status:** Done — 81 Swift files, seed data, all stub views

### Phase 2: Camera & Pose Estimation (COMPLETE)
- **What:** AVFoundation camera pipeline → Vision pose detection → real-time skeleton overlay
- **Status:** Done — CameraManager, FrameProcessor, PoseAnalysisManager, PoseKeypoints, WorkoutLiveView with HUD
- **Key specs:** 720p, 30fps throttle, backpressure guard, 19-joint skeleton

### Phase 3: Morpho-Anatomical Scanner (COMPLETE)
- **What:** Computer vision body scan to measure limb ratios (femur/torso, humerus/torso, etc.)
- **Why:** Determines which exercises are optimal, caution, or high-risk for the user's anatomy
- **Key entities:** MorphoScan, BiomechanicsEngine
- **Status:** Done — MorphoScannerService (T-pose validation, multi-frame averaging, segment computation), BiomechanicsEngine (risk rules, alternatives), MorphoScanViewModel (5-state flow), MorphoScanView (camera+guide+confidence ring), ScanResultsView (ratios+risk profile)

### Phase 4: Form Analysis Engine (COMPLETE)
- **What:** Real-time joint angle analysis for exercise-specific form scoring
- **Why:** 0-100 form score per rep, identifies ROM issues, bar path deviation, tempo adherence
- **Key entities:** FormAnalyzer, RepCounter, WorkoutViewModel
- **Status:** Done — FormAnalyzer (9 exercise profiles with ideal angles, issue detection, bar path tracking), RepCounter (phase state machine for automatic rep detection), WorkoutViewModel (full pipeline integration with Combine, CoreData persistence of WorkoutSession/WorkoutSet), ExercisePickerView (CoreData-backed with risk badges), WorkoutLiveView (ViewModel-driven HUD with form issue banners, weight input, session summary)

### Phase 5: Velocity-Based Training (VBT) (COMPLETE)
- **What:** Track concentric/eccentric velocity from pose data, auto-stop sets on velocity loss
- **Why:** Science-based autoregulation — stop before junk volume
- **Key entities:** VBTService, RPECalculator, VelocityZone
- **Status:** Done — VBTService (joint position tracking, height-based calibration, velocity smoothing, per-rep concentric/peak velocity, fatigue detection with auto-stop at 20% loss), RPECalculator (Gonzalez-Badillo velocity-RPE curves, exercise-specific 1RM at velocity, RIR estimation, velocity zones), RepCounter updated with velocity in RepEvent, WorkoutViewModel fully integrated with fatigue/RPE/velocity tracking, WorkoutLiveView live velocity HUD with loss indicator and auto-stop banner, SetTrackerView rewritten with real data and velocity trend chart

### Phase 6: E-Sport Ranking System (COMPLETE)
- **What:** 9-tier ranking (Iron→Challenger), science-based LP from bodyweight ratios, promotion series
- **Why:** Gamification drives retention; strength standards provide meaningful progression
- **Key entities:** RankingEngine, LeaderboardService, StrengthStandards, RankTier
- **Status:** Done — RankingEngine (LP formula: weight/BW × reps × velocity/form modifiers, gender adjustment, 9 exercises with NSCA-based bodyweight ratio standards per tier), LeaderboardService (CoreData ranking records, personal bests, LP progress tracking), Promotion Series (3 consecutive workouts with increasing LP to advance), WorkoutViewModel integration (LP calculated and recorded on session end), RankingView (real data from CoreData: tier badge with icon, LP progress bar, promotion series UI, rank factors, session history), LeaderboardView (personal best sessions ranked by LP), RankTier enum extended with color/iconName

### Phase 6.5: Equipment & Brands (COMPLETE)
- **What:** Premium machine database (35 exercises, 5 brands), resistance profiles, tare weights
- **Why:** Accurate LP calculation for machines; morpho-based setup recommendations
- **Key entities:** MachineSeedData, MachineSpec (resistanceProfile, startingResistance)
- **Status:** Done — 35 machine exercises across Pure Kraft/Gym80 (10, Sygnum line, ascending cam), Hammer Strength (8, ISO-Lateral, plate-loaded), Panatta (6, FW/HP line, descending cam), Eleiko (4, Prestera + competition), Technogym (9, Selection line, selectorized). VBTService applies resistance profile modifier (ascending ×0.90, descending ×1.10). Each machine has morpho-based setupInstructions

### Phase 7: Recovery & BioAdaptive (COMPLETE)
- **What:** HealthKit integration (HRV, sleep, resting HR), muscle recovery heatmap, readiness scoring, auto-deload, menstrual cycle-sync training
- **Why:** Prevent overtraining, adapt volume to recovery status
- **Key entities:** HealthKitManager, BioAdaptiveService, RecoveryHeatmapEngine, CycleSyncService, RecoveryViewModel
- **Status:** Done — HealthKitManager (async HRV/sleep/HR/energy queries with 14-day history), RecoveryHeatmapEngine (exponential recovery model with 24 muscle-specific rates, volume-based fatigue tracking, per-muscle recovery zones), BioAdaptiveService (readiness scoring: HRV 35% + Sleep 30% + HR 15% + Muscle 20%, auto-deload triggers: HRV drop >15% / velocity decline 2+ sessions / sleep deficit → -20% to -25% load), CycleSyncService (HealthKit menstrual flow → CyclePhase, 28-day model, manual fallback), RecoveryHeatmapView (readiness ring, deload banner, training adjustment card, Heatmap/Biometrics segment picker, expandable muscle recovery rows), BioMetricsView (component score rings, metric cards with score bars, cycle sync card, HRV trend)

### Phase 8: Nutrition & Body Composition (COMPLETE)
- **What:** Dynamic macro calculator with carb cycling, Golden Ratio body analysis, evidence-based supplement advisor, Greek ideal nutrition plans
- **Why:** Nutrition is 50% of bodybuilding results — precision nutrition tied to body composition goals
- **Key entities:** NutritionService, SupplementAdvisor, NutritionViewModel, NutritionDashboardView, BodyStatsView, SupplementView
- **Status:** Done — MorphoScannerService updated (height estimation from pose proportions, body fat estimation from silhouette ratios, Golden Ratio Engine with 4 Greek ideal ratios + priority muscle groups + 20/80 actionable summary). NutritionService (TDEE via Mifflin-St Jeor + Katch-McArdle averaging, protein 1.8-2.5g/kg lean mass by goal, carb cycling: rest -30%, light -15%, moderate 0%, intense +20%, HealthKit bidirectional weight/bodyFat, Greek ideal nutrition plan "SCULPT PROTOCOL"). SupplementAdvisor (10 evidence-based supplements: Creatine/Whey/D3 essential, Omega-3/Magnesium/Caffeine/EGCG/Iron conditional, L-Carnitine/Ashwagandha optional, evidence badges A/B/C, female-specific Iron recommendation). NutritionDashboardView (goal selector Cut/Maintenance/Lean Bulk/Bulk, calorie ring, macro rings P/C/F, water bar, SCULPT PROTOCOL plan card, carb cycling indicator). BodyStatsView (Golden Ratio score ring, radar chart with RadarShape, ratio deviations with status dots, priority muscles pills, 20/80 action card, body composition stats). SupplementView (stack summary badges, priority sections Essential/Recommended/Optional with evidence badges)

### Phase 9: Audio & Announcer
- **What:** E-sport announcer voice cues, BPM sync for tempo training, motivational audio
- **Why:** Hands-free feedback during heavy lifts

### Phase 10: AR & Social
- **What:** Ghost mode (AR overlay of perfect form), guild wars, social leaderboards
- **Why:** Advanced features for retention and community

## Out of Scope (v1)

- Backend/cloud sync (local-first with CoreData)
- Apple Watch companion app
- Video recording/playback
- Multi-person tracking (single user only)
- Custom exercise builder UI (exercises are pre-seeded)

## Success Metrics

| Metric | Target | How We Measure |
|--------|--------|----------------|
| Camera → Pose latency | < 33ms per frame | CACurrentMediaTime profiling |
| Form score accuracy | > 85% agreement with coach assessment | Validation study |
| Session retention | 3+ workouts/week average | CoreData session records |
| Rank progression engagement | 70% users check rank weekly | App analytics |

## Constraints

- **Platform:** iOS 16+ only (Vision body pose requires iOS 14+, modern APIs need 16+)
- **Hardware:** Physical device required for camera features (no Simulator support for AVCaptureSession)
- **Privacy:** All data stored locally in CoreData; camera frames processed in-memory only, never saved
- **Battery:** 720p + 30fps throttle to balance accuracy vs thermal/battery
