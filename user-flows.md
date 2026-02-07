# User Flows — AuraLift

> Key user journeys for an AI bodybuilding app with pose detection and gamification

## Overview

AuraLift is a local-first iOS app. No sign-up, no server. Users launch the app and are immediately in the experience. The first-run onboarding collects morpho-anatomical data to personalize everything.

---

## 1. First Launch / Onboarding Flow

```
┌─────────────────┐
│   App Launch     │
│  (first time)    │
└────────┬────────┘
         ▼
┌─────────────────┐
│  Welcome Screen  │
│  "YOUR BODY.     │
│   YOUR RULES."   │
│  [GET STARTED]   │
└────────┬────────┘
         ▼
┌─────────────────┐
│  Basic Profile   │
│  Username        │
│  Height / Weight │
│  Biological Sex  │
│  (optional)      │
└────────┬────────┘
         ▼
┌─────────────────┐
│  Camera Perm.    │
│  Request camera  │
│  access          │
└────────┬────────┘
         ▼
┌─────────────────┐
│  Morpho Scan     │
│  Stand in frame  │
│  T-pose capture  │
│  Limb ratios     │
│  computed        │
└────────┬────────┘
         ▼
┌─────────────────┐
│  Scan Results    │
│  Body type card  │
│  Exercise recs   │
│  Risk profile    │
└────────┬────────┘
         ▼
┌─────────────────┐
│   Dashboard      │
│  Rank: Iron      │
│  XP: 0           │
│  "Start your     │
│   first workout" │
└─────────────────┘
```

### Key Decisions
- No account creation (local-first)
- Morpho scan happens ONCE during onboarding (can be re-done from Profile)
- Camera permission is requested before the scan, with clear explanation
- If camera is denied: skip scan, show guidance to enable later

---

## 2. Live Workout Flow (Core Loop)

```
┌─────────────────┐
│   Dashboard      │
│  or Workout Tab  │
│  [START WORKOUT] │
└────────┬────────┘
         ▼
┌─────────────────┐
│ Exercise Picker  │
│  Categorized by  │
│  push/pull/legs  │
│  Risk-coded per  │
│  morpho scan     │
└────────┬────────┘
         ▼
┌─────────────────┐
│  Camera Starts   │
│  Pose skeleton   │
│  overlays body   │
└────────┬────────┘
         ▼
┌──────────────────────────────────────┐
│           LIVE HUD ACTIVE            │
│                                      │
│  Exercise name + Set #    Combo      │
│                                      │
│  [VELOCITY]        [FORM SCORE]      │
│   0.85 m/s           92%            │
│                                      │
│           [REPS: 8]                  │
│                                      │
│  ──── Rep Detection Loop ────        │
│  PoseFrame → FormAnalyzer → Score    │
│           → VBTService → Velocity    │
│           → Auto-stop check          │
│                                      │
│  [FLIP]            [END SESSION]     │
└──────────────────────┬───────────────┘
                       │
         ┌─────────────┴─────────────┐
         │   Per-rep events:         │
         │   • Rep counted           │
         │   • FormScore displayed   │
         │   • Velocity recorded     │
         │   • XP earned             │
         │   • Combo updated         │
         │   • Announcer cue         │
         └─────────────┬─────────────┘
                       ▼
┌─────────────────┐
│ Session Summary  │
│  Total volume    │
│  XP earned       │
│  LP change       │
│  Best set stats  │
│  Form average    │
└────────┬────────┘
         ▼
┌─────────────────┐
│   Dashboard      │
│  Updated rank    │
│  Updated XP bar  │
└─────────────────┘
```

### States to Handle
- **No person detected:** "Step into frame" guidance overlay
- **Low confidence pose:** Skeleton partially drawn, form score paused
- **Auto-stop triggered:** Set ends, announcer cues "velocity dropping, set complete"
- **Camera flip:** Front/back camera swap mid-session
- **Permission denied:** Redirect to settings prompt

---

## 3. Morpho Scan Flow

```
┌─────────────────┐
│  Profile Tab     │
│  or Onboarding   │
│  [SCAN BODY]     │
└────────┬────────┘
         ▼
┌─────────────────┐
│  Scan Guide      │
│  "Stand 2m away" │
│  "T-pose"        │
│  "Hold still"    │
└────────┬────────┘
         ▼
┌─────────────────┐
│  Camera Active   │
│  Pose detected   │
│  Joints tracked  │
│  [CAPTURE]       │
└────────┬────────┘
         ▼
┌─────────────────┐
│  Processing...   │
│  BiomechanicsEng │
│  computes ratios │
└────────┬────────┘
         ▼
┌─────────────────┐
│  Results Card    │
│  Torso / Femur   │
│  Humerus / Tibia │
│  ratios shown    │
│                  │
│  Exercise Risk   │
│  Profile updated │
│  ✅ Optimal (12) │
│  ⚠️ Caution (5)  │
│  🔴 Risk (3)     │
└─────────────────┘
```

---

## 4. Ranking & Leaderboard Flow

```
┌─────────────────┐
│  Ranking Tab     │
│  Current tier    │
│  LP progress bar │
│  [LEADERBOARD]   │
│  [GUILD]         │
└────────┬────────┘
    ┌────┴────┐
    ▼         ▼
Leaderboard  Guild
    │         │
    │    ┌────┴────────┐
    │    │ Guild View   │
    │    │ Members list │
    │    │ War stats    │
    │    └─────────────┘
    │
    ▼
┌─────────────────┐
│  Leaderboard     │
│  Weekly / All    │
│  Your rank #     │
│  Top performers  │
│  Tier breakdown  │
└─────────────────┘
```

### Rank Progression
```
Iron (0 LP) → Bronze (100) → Silver (250) → Gold (500) →
Platinum (800) → Diamond (1200) → Master (1800) →
Grandmaster (2500) → Challenger (3500)
```

LP earned per session based on: form score, velocity performance, volume, consistency.

---

## 5. Recovery & Bio-Adaptive Flow

```
┌─────────────────┐
│  Recovery Tab    │
│  Muscle Heatmap  │
│  (body map)      │
└────────┬────────┘
         ▼
┌─────────────────┐
│  Tap muscle      │
│  group for       │
│  detail view     │
│                  │
│  Recovery %      │
│  Last trained    │
│  Weekly volume   │
└─────────────────┘

┌─────────────────┐
│  Bio Metrics     │
│  HRV trend       │
│  Sleep quality   │
│  Resting HR      │
│  Readiness score │
│                  │
│  Cycle phase     │
│  (if enabled)    │
│  Training adj.   │
└─────────────────┘
```

### HealthKit Permission Flow
```
First access → HealthKit permission sheet → User approves/denies
If denied: Show manual entry option for sleep/HRV
If approved: Auto-sync HRV, sleep, resting HR, active energy
```

---

## 6. Dashboard Flow

```
┌─────────────────────────────────┐
│         DASHBOARD               │
│                                 │
│  [Rank Badge]  GOLD - 523 LP   │
│  ████████████░░░░ → Platinum    │
│                                 │
│  [XP Bar]  12,450 XP           │
│  ██████████████████████         │
│                                 │
│  RECENT SESSIONS                │
│  ┌─────────────────────┐       │
│  │ Today - Chest/Tri   │       │
│  │ 87% form · 2.1k vol │       │
│  └─────────────────────┘       │
│  ┌─────────────────────┐       │
│  │ Yesterday - Back    │       │
│  │ 91% form · 1.8k vol │       │
│  └─────────────────────┘       │
│                                 │
│  RECOVERY STATUS                │
│  Readiness: 82% ████████░░     │
│  Next: Legs (recovered)         │
│                                 │
│  [START WORKOUT]                │
└─────────────────────────────────┘
```

---

## 7. Profile & Settings Flow

```
┌─────────────────┐
│  Profile Tab     │
├─────────────────┤
│ User Info        │
│  Name, stats     │
│  [Edit Profile]  │
├─────────────────┤
│ Morpho History   │
│  Past scans      │
│  [New Scan]      │
├─────────────────┤
│ Preferences      │
│  Units (kg/lb)   │
│  Cycle tracking  │
│  Announcer voice │
│  Audio volume    │
├─────────────────┤
│ Data             │
│  Export data     │
│  Clear data      │
├─────────────────┤
│ About            │
│  Version         │
│  Licenses        │
└─────────────────┘
```

---

## 8. Error & Edge Cases

### Camera Permission Denied
```
Workout tab → No camera → Permission denied view →
  "CAMERA ACCESS REQUIRED" message →
  [OPEN SETTINGS] button → iOS Settings redirect
```

### No Pose Detected During Workout
```
Camera active but no body → Overlay message:
  "Step into frame" → Skeleton appears when detected →
  HUD activates
```

### HealthKit Permission Denied
```
Recovery tab → No HealthKit → Manual entry fallback:
  User can input sleep hours, perceived readiness manually
```

### Empty States

| View | Empty State | CTA |
|------|-------------|-----|
| Dashboard (first launch) | "Welcome, Shadow Athlete" | Start first workout |
| Workout sessions | "No sessions yet" | Start workout |
| Morpho scan | "Scan your body to unlock personalized training" | Start scan |
| Leaderboard | "Complete workouts to appear on the leaderboard" | Start workout |
| Recovery heatmap | "Train a muscle group to see recovery data" | Start workout |
