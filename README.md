# AUREA

### Engineered Aesthetics

> The most advanced AI-powered bodybuilding app ever built for iPhone. Real-time computer vision coaching, biomechanical body scanning, velocity-based training, and a prestige league system — all running 100% on-device with zero third-party dependencies.

---

## Why AUREA?

Most fitness apps count reps. AUREA **sees** you. Using Apple's Vision framework and real-time pose estimation (19 skeletal joints at 30fps), AUREA analyzes your exercise form, measures bar velocity, detects fatigue, and adapts your entire training program — live, during your set.

No cloud. No subscriptions to external APIs. No data leaves your phone. Everything runs on the Neural Engine in your pocket.

---

## Core Features

### Real-Time Form Analysis
Your iPhone camera tracks 19 body joints in real-time during every rep. AUREA scores your form across 9 exercise profiles (Squat, Bench, Deadlift, OHP, Row, RDL, Pull-Up, Lat Pulldown, Hip Thrust), detects issues like knee cave, elbow flare, and back rounding, and gives you instant feedback with severity-graded alerts.

### Morpho-Anatomical Scanner
Stand in a T-pose for 3 seconds. AUREA measures your limb proportions — femur-to-torso ratio, arm span, shoulder-to-hip width — classifies your morphotype, and identifies which exercises are biomechanically optimal, risky, or should be swapped entirely based on your unique anatomy.

### Velocity-Based Training (VBT)
Every rep is measured in meters per second. AUREA tracks concentric and eccentric velocity, calculates RPE from load-velocity curves (Gonzalez-Badillo method), estimates reps in reserve, detects fatigue via velocity loss percentage, and auto-stops your set when velocity drops beyond 20% — the same protocol used by elite strength coaches.

### AR Ghost Mode
A translucent green skeleton overlay shows you the biomechanically perfect form for your body proportions and the current exercise. Match the ghost. Beat the ghost. Earn bonus LP.

### AUREA Blueprint (Smart Programming)
A 12-week periodized training program generated from your morpho scan, gym equipment, and goals. Uses the Pareto 80/20 principle — 80% volume on your priority muscles, 20% maintenance. Includes an anti-bullshit filter that bans inefficient exercises (no shrugs, no forearm curls). Machine intelligence prefers branded equipment (Hammer Strength, Technogym, Panatta, Gym80, Eleiko) when your gym has them, with morpho-specific exercise swaps and explanations for every choice.

### Recovery & BioAdaptive Intelligence
Connects to Apple HealthKit to pull HRV, resting heart rate, sleep quality, and active energy. Combines these into a readiness score (0-100) that auto-adjusts your training: deloads when your HRV drops, switches to Volume Mode when recovery is below 35%, and respects menstrual cycle phases with RPE caps and volume adjustments.

### Muscle Recovery Heatmap
An exponential decay model tracks recovery state for 24 individual muscle groups based on your training history. Each muscle has a science-based recovery rate (large muscles recover slower, small muscles faster). The heatmap shows you exactly which muscles are recovered and which need more time.

### Nutrition & Body Composition
TDEE calculated from dual-method averaging (Mifflin-St Jeor + Katch-McArdle). Automatic carb cycling based on training day intensity. Greek Ideal golden ratio scoring (shoulder/waist 1.618, chest/waist 1.44) with priority muscle recommendations. 10 evidence-based supplement recommendations with dosage, timing, and evidence grades.

### Prestige League System
A competitive ranking system inspired by e-sports. LP (League Points) are earned from every session based on weight-to-bodyweight ratios, rep velocity, and form quality. Nine rank tiers from Iron to Challenger with promotion series. Plus the AUREA Prestige League — a parallel tier system (Member through Architect) with season resets and a Black Card for the elite.

### Audio Coaching & Haptics
Three AI persona modes — Spartan (aggressive), Analyst (data-driven), Mentor (encouraging) — with context-aware voice lines for reps, combos, form issues, and rank-ups. Procedural sound effects generated via AVAudioEngine (no audio files needed). Haptic feedback patterns that escalate with workout intensity.

### Social & Sharing
Create or join guilds. View personal leaderboards ranked by LP. Generate shareable session cards (rendered as images) showing your tier, stats, form score, and velocity data.

### Gamification
Daily missions (Cyber-Ops) with XP rewards. Training streaks with multiplier bonuses. A Season Pass with tiered rewards across the season. XP progression system with tier advancement.

### Monetization
StoreKit 2 integration with a premium tier (AUREA Pro). Feature gating for VBT, Ghost Mode, and Blueprint. Paywall with product cards, restore purchases, and beta unlock. Season Pass with free and premium reward tracks.

---

## Equipment Intelligence

AUREA ships with 35 branded machine exercises across 5 premium manufacturers:

| Brand | Machines | Specialty |
|-------|----------|-----------|
| **Hammer Strength** | 8 | Plate-loaded leverage machines |
| **Technogym** | 7 | Selectorized smart equipment |
| **Panatta** | 7 | Italian performance machines |
| **Pure Kraft / Gym80** | 7 | German engineering precision |
| **Eleiko** | 6 | Competition-grade free weights |

Each machine includes resistance profile modeling (ascending, descending, linear) that adjusts velocity calculations, and morpho-based setup instructions (seat height, pad position) calibrated to your body measurements.

---

## Intelligence Layer

### AUREA Brain
The central decision engine. Enforces morpho constraints (bans exercises that are dangerous for your proportions), cycle constraints (RPE caps during luteal/menstrual phases), and VBT kill switches (stops sets when velocity collapses). Generates pre-session briefs.

### Metabolic Flux
Adaptive TDEE that learns from your weight trend. Uses 14-day exponential moving average smoothing, then adjusts weekly: cuts calories when fat loss stalls, increases when losing too fast, pulls back when bulking goes sideways. Every adjustment includes a plain-language reason.

### Persona Engine
Replaces static voice packs with dynamic personas that adapt their tone to your training state. Stealth mode automatically hides weight and calorie displays if you log more than 5 times in a day (eating disorder protection).

---

## Design Language

AUREA uses a clinical luxury aesthetic built for OLED displays:

- **Background**: Pure black (#000000) — every pixel is off
- **Primary**: Gold (#D4AF37) — prestige, achievement, brand
- **Secondary**: Silver (#C0C0C0) — data, metrics, neutral
- **Success**: Muted green (#4CAF50) — recovery, completion
- **Alert**: Muted rose (#CF6679) — warnings, danger
- **Prestige**: Bright gold (#FFD700) — elite achievements
- **Mystic**: Deep purple (#7C4DFF) — special features

Custom SwiftUI view modifiers (`.aureaGlow()`, `.aureaCard()`, `.aureaText()`) enforce visual consistency across 43 view files.

---

## Architecture

```
MVVM + Services — 133 Swift files, 18 CoreData entities
```

- **Zero third-party dependencies** — 100% Apple frameworks
- **Programmatic CoreData** — no `.xcdatamodeld`, entire model built in code
- **Thread-safe pipeline**: Camera queue → Frame processor (backpressure-protected) → Vision inference → Main thread UI
- **Combine-driven**: All reactive state flows through `@Published` + `sink` with `[weak self]`
- **`@MainActor` ViewModels**: All 12 ViewModels annotated for thread safety
- **`os.Logger` throughout**: Zero `print()` statements, structured logging with subsystem/category
- **Privacy-first**: Camera frames processed on-device, no network calls, HealthKit data stays local

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI |
| Data | CoreData (programmatic model) |
| Camera | AVFoundation (720p, 30fps) |
| Pose | Vision framework (VNDetectHumanBodyPoseRequest) |
| Health | HealthKit (HRV, sleep, HR, energy, menstrual) |
| Audio | AVSpeechSynthesizer + AVAudioEngine |
| Haptics | UIFeedbackGenerator (pre-warmed) |
| Payments | StoreKit 2 |
| Dependencies | **None** |

---

## Requirements

- iPhone with A12 chip or later (Neural Engine required for pose estimation)
- iOS 16.0+
- Xcode 15+, Swift 5.9+
- Physical device for camera, HealthKit, and haptic features

---

## Build

```bash
# Generate Xcode project from project.yml
xcodegen generate

# Build
xcodebuild -scheme AuraLift -destination 'platform=iOS,name=Your iPhone'
```

---

## Project Structure

```
AuraLift/
├── App/                          # Entry point, ContentView, AppDelegate
├── Core/
│   ├── Constants/                # Brand vocabulary (Aurea namespace)
│   ├── Extensions/               # Color, View, Date extensions
│   ├── Persistence/              # CoreData controller, seed data (18 entities)
│   ├── Protocols/                # Service + Repository protocols
│   └── Theme/                    # AureaTheme, ViewModifiers
├── Models/
│   ├── CoreData/                 # 18 entity classes
│   └── Enums/                    # RankTier, Morphotype, CyclePhase, etc.
├── Services/
│   ├── AR/                       # Ghost Mode, Perfect Form Avatar
│   ├── Audio/                    # AudioManager, Announcer, BPM Sync
│   ├── BioAdaptive/              # Recovery, Cycle Sync, Heatmap Engine
│   ├── Camera/                   # CameraManager, FrameProcessor
│   ├── HealthKit/                # HealthKit queries, data models
│   ├── Intelligence/             # AUREA Brain, Persona, Metabolic Flux
│   ├── League/                   # Prestige tier system
│   ├── Monetization/             # StoreKit 2, Premium Manager
│   ├── MorphoScanner/            # Body scanning, Biomechanics Engine
│   ├── Nutrition/                # TDEE, macros, supplements
│   ├── PoseAnalysis/             # Pose estimation, Form Analyzer
│   ├── Ranking/                  # LP engine, Strength Standards
│   ├── SmartProgram/             # Pareto builder, Overload, Live Swap
│   ├── Social/                   # Guilds, Share Cards
│   └── VelocityTracker/          # VBT, RPE Calculator
├── ViewModels/                   # 12 @MainActor ObservableObjects
└── Views/                        # 43 SwiftUI views
    ├── Components/               # Reusable (buttons, cards, overlays)
    ├── Dashboard/                # Home, XP, Streaks, Daily Ops
    ├── League/                   # Prestige tier dashboard
    ├── Monetization/             # Paywall, Season Pass
    ├── MorphoScan/               # Scanner, Results
    ├── Nutrition/                # Macros, Body Stats, Supplements
    ├── Profile/                  # Settings, Audio config
    ├── Ranking/                  # LP ranking, Leaderboard, Guilds
    ├── Recovery/                 # Heatmap, Biometrics
    ├── SmartProgram/             # Blueprint wizard, Coach, Gym editor
    ├── Social/                   # Social dashboard, Share cards
    └── Workout/                  # Live session, Exercise picker
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [spec.md](./spec.md) | Full product specification |
| [architecture.md](./architecture.md) | System design and data flows |
| [database-schema.md](./database-schema.md) | All 18 CoreData entities |
| [design-system.md](./design-system.md) | Clinical luxury visual language |
| [user-flows.md](./user-flows.md) | User journey maps |
| [tech-stack.md](./tech-stack.md) | Technology decisions |

---

## License

Proprietary. All rights reserved.
