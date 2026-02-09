# Tech Stack — AUREA

> Native iOS app built entirely with Apple frameworks

## Overview

| Layer | Technology | Rationale |
|-------|------------|-----------|
| UI | SwiftUI | Declarative, reactive, native iOS |
| State | @Published + ObservableObject | Built-in Combine integration |
| Persistence | CoreData (programmatic model) | Local-first, no server needed |
| Camera | AVFoundation | Full capture pipeline control |
| Pose Detection | Vision (VNDetectHumanBodyPoseRequest) | Apple's on-device ML, no third-party |
| Health Data | HealthKit | HRV, sleep, resting HR, activity |
| AR | ARKit | Ghost mode, form overlay |
| Audio | AVFoundation + AVSpeechSynthesizer | Announcer cues, BPM sync |

## Frontend (SwiftUI)

### Framework
- **Choice:** SwiftUI (iOS 16+)
- **Rationale:** Declarative UI matches reactive data flow from camera/pose pipeline. Native performance for real-time overlay rendering.

### State Management
- **Choice:** `@StateObject` / `@ObservedObject` + `@Published`
- **Pattern:** MVVM — Views observe ViewModels, ViewModels coordinate Services
- **No third-party:** Combine is sufficient for reactive pipelines

### Design System
- **Theme:** Custom `AuraTheme` enum (spacing, radius, fonts, shadows, animation)
- **Colors:** `Color+AuraLift.swift` extension with cyberpunk palette
- **Modifiers:** Custom ViewModifiers (.neonGlow, .cyberpunkText, .darkCard, .pulse)
- **Components:** NeonButton, NeonOutlineButton, GlowCard, CyberpunkTabBar

## Data Layer (CoreData)

### Database
- **Choice:** CoreData with SQLite backing store
- **Rationale:** Local-first (no server), built-in relationship support, optimized for iOS
- **Model:** 100% programmatic (no .xcdatamodeld) — built in `PersistenceController.buildManagedObjectModel()`

### Schema
- 12 entities, 5 enums (see [database-schema.md](./database-schema.md))
- Merge policy: `NSMergeByPropertyObjectTrumpMergePolicy`
- Preview support: in-memory store for SwiftUI previews

## Computer Vision Pipeline

### Camera
- **Choice:** AVFoundation (`AVCaptureSession`)
- **Resolution:** 720p (`.hd1280x720`)
- **Format:** BGRA pixel format for Vision compatibility
- **Threading:** Dedicated session + data output queues

### Pose Estimation
- **Choice:** Vision framework (`VNDetectHumanBodyPoseRequest`)
- **Joints:** 19 body joints with confidence filtering (>= 0.3)
- **Processing:** 30fps throttle + backpressure guard on dedicated queue

### Form Analysis
- **Approach:** Joint angle computation via atan2, exercise-specific angle thresholds
- **Output:** 0-100 form score per rep, bar path deviation, ROM measurement

## Health & Biometric Integration

### HealthKit
- **Data read:** HRV, sleep duration, sleep quality, resting heart rate, active energy
- **Usage:** Recovery readiness scoring, bio-adaptive training adjustments
- **Privacy:** Read-only, user must grant permission

## Audio

### Announcer
- **Choice:** AVSpeechSynthesizer for dynamic cues, pre-recorded clips for e-sport moments
- **BPM sync:** Tempo training with audio beat matching

## Development Tools

| Tool | Purpose |
|------|---------|
| Xcode 15+ | IDE, build, deploy |
| Swift 5.9+ | Language |
| SwiftUI Previews | Rapid UI iteration |
| Instruments | Profiling (Core Animation, Time Profiler) |
| Physical iPhone | Required for camera/pose testing |

## Environment Requirements

```
Xcode >= 15.0
Swift >= 5.9
iOS Deployment Target >= 16.0
Physical device for camera features
```

## Key Dependencies

**Zero third-party dependencies.** The entire app uses only Apple frameworks:

```
Foundation, SwiftUI, CoreData, Combine,
AVFoundation, Vision, HealthKit, ARKit,
CoreGraphics, CoreMedia, QuartzCore
```
