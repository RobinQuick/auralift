# CLAUDE.md

> Project-specific rules and patterns for AI assistants working on AUREA

## Project Overview

**Name:** AUREA
**Description:** AI-driven iOS bodybuilding app combining Computer Vision pose estimation, biomechanical morpho-analysis, prestige league system, and bio-decisional intelligence
**Stack:** SwiftUI, CoreData (programmatic model), AVFoundation, Vision framework, HealthKit

When generating UI text, labels, or dashboard content, use plain non-technical language suitable for executives (e.g., DSI). Avoid statistical jargon like MAPE, WMAPE unless explicitly requested.

---

## Business Logic & Calculations

When implementing calculations or business logic, always ask me to confirm the formula BEFORE coding it. Show the formula in plain language with a concrete example (e.g., 'For a prediction of 80 and actual of 100, the score would be 80/100 = 80%'). Do not invent sophisticated statistical approaches when a simple one is requested.

---

## Code Style & Conventions

### General
- Swift strict typing — no `Any` unless interfacing with CoreData/Objective-C
- Use early returns and `guard` to reduce nesting
- Maximum function length: ~50 lines (extract if longer)
- Maximum file length: ~300 lines (split if longer)
- Prefer `let` over `var`, value types over reference types when possible
- Use `// MARK: -` sections to organize files

### Naming
```swift
// Variables and functions: camelCase
let userName = "John"
func getUserById(_ id: UUID) -> UserProfile? {}

// Types, protocols, enums: PascalCase
struct PoseFrame {}
protocol ServiceProtocol {}
enum RankTier: String, CaseIterable {}

// Constants in enums: camelCase cases
enum AureaTheme {
    enum Spacing {
        static let sm: CGFloat = 8
    }
}

// Files: PascalCase matching primary type
// UserProfile+CoreDataClass.swift, PoseKeypoints.swift, WorkoutLiveView.swift
```

### File Organization
```
AuraLift/
├── App/                    # Entry point, AppDelegate, ContentView (tab nav)
├── Core/
│   ├── Extensions/         # Color+AuraLift, View+Extensions, Date+Extensions
│   ├── Persistence/        # PersistenceController, SeedDataLoader
│   ├── Protocols/          # ServiceProtocol, RepositoryProtocol
│   └── Theme/              # Theme.swift, ViewModifiers.swift
├── Models/
│   ├── CoreData/           # 12 entity classes (Entity+CoreDataClass.swift)
│   └── Enums/              # RankTier, EquipmentType, ExerciseRisk, MuscleGroupType, CyclePhase
├── Services/               # Domain-organized service classes
│   ├── Camera/             # CameraManager, FrameProcessor
│   ├── PoseAnalysis/       # PoseAnalysisManager, PoseKeypoints, FormAnalyzer
│   ├── MorphoScanner/      # MorphoScannerService, BiomechanicsEngine
│   ├── VelocityTracker/    # VBTService, RPECalculator
│   ├── Ranking/            # RankingEngine, LeaderboardService
│   ├── BioAdaptive/        # BioAdaptiveService, CycleSyncService, RecoveryHeatmapEngine
│   ├── HealthKit/          # HealthKitManager, HealthDataModels
│   ├── Nutrition/          # NutritionService, SupplementAdvisor
│   ├── Audio/              # AudioManager, AnnouncerService, BPMSyncEngine
│   ├── AR/                 # GhostModeManager, PerfectFormAvatar
│   └── Science/            # ScienceUpdateService, TrainingProtocolUpdater
├── ViewModels/             # 7 ObservableObject view models
└── Views/                  # SwiftUI views organized by feature
    ├── Components/         # NeonButton, GlowCard, CyberpunkTabBar, etc.
    ├── Dashboard/
    ├── Workout/
    ├── MorphoScan/
    ├── Ranking/
    ├── Recovery/
    ├── Nutrition/
    └── Profile/
```

### Import Order
```swift
// 1. Foundation/System frameworks
import Foundation
import SwiftUI
import CoreData

// 2. Apple frameworks
import AVFoundation
import Vision
import HealthKit

// 3. Project imports (implicit in single-module Swift apps)
```

---

## SwiftUI Patterns

### View Structure
```swift
struct ExampleView: View {
    // 1. Environment & injected state
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: ExampleViewModel

    // 2. Local state
    @State private var isLoading = false

    // 3. Body
    var body: some View {
        // Main layout
    }

    // 4. Extracted subviews as computed properties
    private var headerSection: some View { ... }

    // 5. Action methods
    private func handleSubmit() { ... }
}
```

### Service Pattern
```swift
// All services conform to ServiceProtocol
final class ExampleService: ObservableObject, ServiceProtocol {
    var isAvailable: Bool { /* check readiness */ }

    func initialize() async throws {
        // Async setup
    }
}
```

### CoreData Pattern
- All 12 entities built **programmatically** in `PersistenceController.buildManagedObjectModel()`
- **NO** `.xcdatamodeld` files — model is 100% code-defined
- Entity classes: `@objc(EntityName) public class EntityName: NSManagedObject`
- Use convenience initializers with default values
- Repositories conform to `RepositoryProtocol<Entity>` for generic CRUD

---

## Threading Model

| Queue | Label | Purpose |
|-------|-------|---------|
| Main | `DispatchQueue.main` | SwiftUI updates, @Published writes |
| Camera Session | `com.auralift.camera.session` | AVCaptureSession start/stop/config |
| Camera Data | `com.auralift.camera.dataOutput` | Frame delivery callbacks |
| Frame Processor | `com.auralift.frameProcessor` | Vision inference (backpressure-protected) |

---

## AUREA Design System (Clinical Luxury)

### Colors
```swift
Color.aureaVoid            // #000000 — OLED black background
Color.aureaPrimary         // #D4AF37 — primary accent (Gold)
Color.aureaSecondary       // #C0C0C0 — secondary accent (Silver)
Color.aureaSuccess         // #4CAF50 — success states (Muted green)
Color.aureaAlert           // #CF6679 — danger states (Muted rose)
Color.aureaPrestige        // #FFD700 — achievements (Gold)
Color.aureaMystic          // #7C4DFF — special/elite (Purple)
Color.aureaWhite           // #F5F5F0 — clinical white text
Color.aureaSurface         // #0A0A0F — card backgrounds
Color.aureaSurfaceElevated // #12121A — elevated surfaces
```

Legacy aliases (`Color.neonBlue`, `.auraBlack`, etc.) still compile via `Color+AuraLift.swift`.

### View Modifiers
```swift
.aureaGlow(color:radius:cornerRadius:)  // Gold border + shadow
.aureaText(color:)                       // Colored text + glow shadow
.aureaCard()                             // Dark card background
.pulse()                                 // Repeating scale animation
.aureaBackground()                       // Full-screen OLED black
```

Legacy aliases (`.neonGlow()`, `.darkCard()`, `.auraBackground()`) still compile via ViewModifiers.swift.

---

## Do NOT

- Never use `.xcdatamodeld` — model is programmatic
- Never use `Any` type unless required by Objective-C bridging
- Never block the main thread with Vision/AVFoundation work
- Never leave `print()` in production code (use os_log if needed)
- Never create SwiftUI views over 200 lines (extract components)
- Never hardcode colors — use `Color.aureaPrimary` etc. from `Color+AuraLift`
- Never skip `[weak self]` in closure captures for class instances

## Do

- Write self-documenting Swift code with clear naming
- Use `// MARK: -` to organize file sections
- Handle all camera/HealthKit permission states gracefully
- Use `@Published` + `ObservableObject` for reactive state
- Keep Vision inference on background threads with backpressure
- Use `AureaTheme` constants for all spacing, radii, fonts (legacy `AuraTheme` alias available)
- Test on physical device for camera/pose features

---

## Commands

```bash
# Build (Xcode)
xcodebuild -scheme AuraLift -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# This is an iOS project — no npm, no web server
# Build and run through Xcode or xcodebuild
```

---

## Git & Version Control

Before running `git push`, verify the current git remote URL and authenticated account match the intended repository. Run `git remote -v` and `gh auth status` first. If there's a mismatch, stop and tell me rather than retrying the push.

---

## Workflow Conventions

For large multi-phase implementations: after generating files, provide a short summary checklist of what was created/modified with file paths. When a phase is complete, ask if I want to commit before moving to the next phase.

---

## Resources

- [Architecture](./architecture.md)
- [Database Schema](./database-schema.md)
- [Design System](./design-system.md)
- [User Flows](./user-flows.md)
- [Product Spec](./spec.md)
