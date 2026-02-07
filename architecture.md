# Architecture — AuraLift iOS

> MVVM + Services architecture for SwiftUI with CoreData

## High-Level Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                       VIEWS (SwiftUI)                         │
│  Dashboard │ Workout │ MorphoScan │ Ranking │ Recovery │ ...  │
│            │ LiveView│            │         │          │       │
│  Components: NeonButton, GlowCard, CyberpunkTabBar, etc.     │
└──────────────────────┬───────────────────────────────────────┘
                       │ @StateObject / @ObservedObject
                       ▼
┌──────────────────────────────────────────────────────────────┐
│                    VIEWMODELS (ObservableObject)               │
│  DashboardVM │ WorkoutVM │ MorphoScanVM │ RankingVM │ ...     │
│              │           │              │           │          │
│  @Published state + business logic coordination               │
└──────────────────────┬───────────────────────────────────────┘
                       │ calls
                       ▼
┌──────────────────────────────────────────────────────────────┐
│                     SERVICES (ServiceProtocol)                │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐        │
│  │ Camera   │ │ Pose     │ │ Morpho   │ │ Velocity │        │
│  │ Manager  │ │ Analysis │ │ Scanner  │ │ Tracker  │        │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐        │
│  │ Ranking  │ │ Bio      │ │ Health   │ │ Nutrition│        │
│  │ Engine   │ │ Adaptive │ │ Kit      │ │ Service  │        │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐                     │
│  │ Audio    │ │ AR       │ │ Science  │                      │
│  │ Manager  │ │ Manager  │ │ Service  │                      │
│  └──────────┘ └──────────┘ └──────────┘                      │
└──────────────────────┬───────────────────────────────────────┘
                       │ reads/writes
                       ▼
┌──────────────────────────────────────────────────────────────┐
│                    CORE DATA (Persistence)                     │
│  PersistenceController → NSPersistentContainer                │
│  12 Entities (programmatic model, no .xcdatamodeld)           │
│  SeedDataLoader → ExerciseSeedData                            │
└──────────────────────────────────────────────────────────────┘
                       │
          ┌────────────┴────────────┐
          ▼                         ▼
┌──────────────────┐     ┌──────────────────┐
│  Apple Frameworks │     │  Device Hardware  │
│  Vision, HealthKit│     │  Camera, Sensors  │
│  ARKit, AVFound.  │     │  Accelerometer    │
└──────────────────┘     └──────────────────┘
```

## Directory Structure

```
AuraLift/
├── App/                        # App entry point and root navigation
│   ├── AuraLiftApp.swift       # @main entry, CoreData injection
│   ├── AppDelegate.swift       # UIApplicationDelegate for lifecycle
│   └── ContentView.swift       # Tab navigation (5 tabs + CyberpunkTabBar)
│
├── Core/                       # Framework-level shared code
│   ├── Extensions/             # Color+AuraLift, View+Extensions, Date+Extensions
│   ├── Persistence/            # PersistenceController, SeedDataLoader, ExerciseSeedData
│   ├── Protocols/              # ServiceProtocol, RepositoryProtocol
│   └── Theme/                  # AuraTheme (spacing, radius, fonts), ViewModifiers
│
├── Models/                     # Data layer
│   ├── CoreData/               # 12 @objc NSManagedObject subclasses
│   └── Enums/                  # RankTier, EquipmentType, ExerciseRisk, etc.
│
├── Services/                   # Business logic (10 domains)
│   ├── Camera/                 # CameraManager, FrameProcessor
│   ├── PoseAnalysis/           # PoseAnalysisManager, PoseKeypoints, FormAnalyzer
│   ├── MorphoScanner/          # MorphoScannerService, BiomechanicsEngine
│   ├── VelocityTracker/        # VBTService, RPECalculator
│   ├── Ranking/                # RankingEngine, LeaderboardService
│   ├── BioAdaptive/            # BioAdaptiveService, CycleSyncService, RecoveryHeatmapEngine
│   ├── HealthKit/              # HealthKitManager, HealthDataModels
│   ├── Nutrition/              # NutritionService, SupplementAdvisor
│   ├── Audio/                  # AudioManager, AnnouncerService, BPMSyncEngine
│   ├── AR/                     # GhostModeManager, PerfectFormAvatar
│   └── Science/                # ScienceUpdateService, TrainingProtocolUpdater
│
├── ViewModels/                 # 7 ObservableObject view models
│   ├── DashboardViewModel.swift
│   ├── WorkoutViewModel.swift
│   ├── MorphoScanViewModel.swift
│   ├── RankingViewModel.swift
│   ├── RecoveryViewModel.swift
│   ├── NutritionViewModel.swift
│   └── ProfileViewModel.swift
│
├── Views/                      # SwiftUI views by feature
│   ├── Components/             # NeonButton, GlowCard, CyberpunkTabBar, etc.
│   ├── Dashboard/              # DashboardView, XPProgressBar
│   ├── Workout/                # WorkoutLiveView, ExercisePickerView, SetTrackerView
│   ├── MorphoScan/             # MorphoScanView, ScanResultsView
│   ├── Ranking/                # RankingView, LeaderboardView, GuildView
│   ├── Recovery/               # RecoveryHeatmapView, BioMetricsView
│   ├── Nutrition/              # NutritionDashboardView, SupplementView
│   └── Profile/                # ProfileView
│
├── Resources/
│   ├── Assets.xcassets
│   ├── Fonts/
│   └── Sounds/
│
└── Info.plist                  # NSCameraUsageDescription
```

## Data Flow

### Camera → Pose → HUD Pipeline
```
AVCaptureSession (CameraManager)
    │ CMSampleBuffer @ camera fps
    ▼
FrameProcessor (throttle 30fps + backpressure)
    │ CVPixelBuffer
    ▼
PoseAnalysisManager (VNDetectHumanBodyPoseRequest)
    │ PoseFrame (19 joints, confidence-filtered)
    ▼
@Published currentPoseFrame → SwiftUI
    │
    ├──► PoseOverlayView (Canvas: neon skeleton + joint dots)
    ├──► FormAnalyzer (joint angles → form score)
    └──► VBTService (joint velocity → bar speed)
```

### Workout Session Flow
```
User taps START → WorkoutSession created
    │
    ├── Camera starts → Pose detection begins
    ├── Exercise selected → FormAnalyzer configured
    │
    ▼ Per-rep loop:
    PoseFrame stream → FormAnalyzer → formScore
                     → VBTService → velocity, ROM, tempo
                     → RPECalculator → autoStop check
    │
    ▼ Rep completed:
    WorkoutSet created (velocity + form + tempo + XP)
    │
    ├── RankingEngine → LP change, combo multiplier
    ├── XP system → totalXP update
    └── AnnouncerService → audio feedback
    │
    ▼ Session ends:
    WorkoutSession finalized (aggregates computed)
    MuscleGroup recovery scores updated
```

## Navigation Model

5-tab architecture via `CyberpunkTabBar`:

| Tab | View | Accent Color | Purpose |
|-----|------|-------------|---------|
| Dashboard | DashboardView | Neon Blue | XP, rank, recent activity |
| Workout | WorkoutLiveView | Cyber Orange | Live camera + pose + HUD |
| Ranking | RankingView | Neon Gold | Leaderboard, guild wars |
| Recovery | RecoveryHeatmapView | Neon Green | Muscle map, HRV, sleep |
| Profile | ProfileView | Neon Purple | Settings, morpho history |

## Threading Model

| Queue | Label | QoS | Purpose |
|-------|-------|-----|---------|
| Main | - | .userInteractive | SwiftUI, @Published writes |
| Camera Session | `com.auralift.camera.session` | .default | AVCaptureSession config |
| Camera Data | `com.auralift.camera.dataOutput` | .default | Frame delivery |
| Frame Processor | `com.auralift.frameProcessor` | .userInitiated | Vision inference |

## Key Design Decisions

### ADR-001: Programmatic CoreData Model
- **Context:** Needed 12 entities with complex relationships
- **Decision:** Build `NSManagedObjectModel` entirely in code, no `.xcdatamodeld`
- **Consequences:** Full control over model, easier to version, but requires manual relationship wiring

### ADR-002: Vision Framework for Pose Estimation
- **Context:** Need real-time body pose tracking for form analysis
- **Decision:** Use Apple's `VNDetectHumanBodyPoseRequest` (19 joints)
- **Consequences:** No third-party ML dependency, iOS 14+ required, good accuracy for compound lifts

### ADR-003: E-Sport Ranking System
- **Context:** Gamification to drive engagement
- **Decision:** 9-tier ranking system (Iron → Challenger) with LP/XP dual currency
- **Consequences:** Complex scoring formula needed, but strong retention mechanic

### ADR-004: Backpressure Frame Processing
- **Context:** Vision inference is slower than camera frame rate
- **Decision:** 30fps throttle + boolean backpressure guard (drop frames, never queue)
- **Consequences:** Smooth UI, no memory buildup, but some frames are skipped
