# AuraLift

> AI-driven iOS bodybuilding app with Computer Vision, Biomechanics, and E-sport Gamification

## What is AuraLift?

AuraLift uses your iPhone camera to analyze exercise form in real-time, measure your body proportions for personalized training, and gamifies your workouts with an e-sport ranking system.

## Documentation

| File | Purpose |
|------|---------|
| [spec.md](./spec.md) | Product specification and feature roadmap |
| [architecture.md](./architecture.md) | System design, data flow, MVVM+Services |
| [database-schema.md](./database-schema.md) | CoreData entities (12) and relationships |
| [design-system.md](./design-system.md) | Cyberpunk visual language (colors, spacing, components) |
| [user-flows.md](./user-flows.md) | User journeys (onboarding, workout, ranking) |
| [tech-stack.md](./tech-stack.md) | Technology choices (100% Apple frameworks) |
| [CLAUDE.md](./CLAUDE.md) | AI assistant coding conventions |

## Phase Status

| Phase | Feature | Status |
|-------|---------|--------|
| 1 | Foundation (CoreData + theme + skeleton) | COMPLETE |
| 2 | Camera & Pose Estimation | COMPLETE |
| 3 | Morpho-Anatomical Scanner | COMPLETE |
| 4 | Form Analysis Engine | COMPLETE |
| 5 | Velocity-Based Training | COMPLETE |
| 6 | E-Sport Ranking System | COMPLETE |
| 6.5 | Equipment & Brands (35 machines, 5 brands) | COMPLETE |
| 7 | Recovery & BioAdaptive | COMPLETE |
| 8 | Nutrition & Body Composition | COMPLETE |
| 9 | Audio & Announcer | Pending |
| 10 | AR & Social | Pending |

## Tech Stack

- **SwiftUI** + **CoreData** (programmatic model)
- **AVFoundation** for camera pipeline
- **Vision** for pose estimation (19 joints)
- **HealthKit** for recovery data
- **Zero third-party dependencies**

## Requirements

- Xcode 15+, Swift 5.9+, iOS 16+
- Physical iPhone for camera/pose features
