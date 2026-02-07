# TEST_GUIDE.md — AuraLift Physical Device Testing

> Guide for testing the 5 key features of AuraLift on a physical iPhone.
> Simulator is insufficient — camera, pose detection, HealthKit, and haptics require real hardware.

---

## Prerequisites

- **Device**: iPhone 12 or later (A14+ chip for Vision body pose)
- **iOS**: 17.0+
- **Xcode**: 15.0+ with valid signing team
- **Setup**: Stand 2-3 meters from phone, use a tripod or prop phone against a wall
- **Lighting**: Well-lit room, avoid backlighting (silhouette kills pose detection)

---

## 1. Camera & Pose Estimation (Phase 2)

### What to Test
Real-time body pose detection via Vision framework with skeleton overlay.

### Steps

1. Launch app → tap **Workout** tab
2. Grant camera permission when prompted
3. **Verify**: Live camera preview fills the screen
4. Step into frame — **Verify**: Orange skeleton overlay appears on your body within ~0.5s
5. Move around — **Verify**: Skeleton tracks your movements smoothly (no freezing, no lag >200ms)
6. Tap **FLIP** button — **Verify**: Camera toggles front/back, skeleton re-detects after toggle
7. Step out of frame — **Verify**: Skeleton disappears cleanly (no stale overlay)
8. Walk back in — **Verify**: Skeleton re-appears without app restart

### Red Flags
- Black screen after granting permission → `CameraManager.configureSession()` failed
- Skeleton frozen or jittery → `FrameProcessor` backpressure or threading issue
- App crash on camera toggle → `AVCaptureSession` input swap race condition
- High CPU (>50%) at idle → frame processing not throttled properly

### Permission Denial Test
1. Go to Settings → AuraLift → disable Camera
2. Return to Workout tab — **Verify**: No crash, shows appropriate messaging
3. Re-enable camera, return to app — **Verify**: Camera resumes

---

## 2. Morpho-Anatomical Scanner (Phase 3)

### What to Test
T-pose body proportion measurement, segment ratios, and morphotype classification.

### Steps

1. **Workout** tab or dedicated **Morpho Scan** tab → tap **BEGIN SCAN**
2. Grant camera permission if not already done
3. Stand 2m away in a **T-pose** (arms extended horizontally)
4. **Verify**: Blue T-pose silhouette guide visible on screen
5. **Verify**: Confidence ring (top-right) increases as you align (green ≥ 70%)
6. Tap **CAPTURE** when confidence ring is green
7. **Verify**: Progress bar fills as 15 frames are captured (~2s)
8. **Verify**: "ANALYZING PROPORTIONS..." processing view appears
9. **Verify**: Results screen shows:
   - Body segment ratios (femur/torso, tibia/femur, humerus/torso, arm span/height, shoulder/hip)
   - Deviation bars showing how you compare to population averages
   - Morphotype classification badge (e.g., "Proportional", "Long Torso")
   - Exercise risk profile grouped by optimal/caution/high risk
10. Dismiss results → re-enter scan → **Verify**: "Last scan: [date]" shown

### Red Flags
- Capture stuck at 0% → T-pose confidence never reached threshold
- "SCAN FAILED" immediately → `computeMeasurements` returned nil (joints missing)
- All ratios showing 0 → height calibration failed
- Morphotype always "Proportional" → deviation thresholds too lenient

### Permission Denial Test
1. Deny camera permission → **Verify**: "CAMERA ACCESS DENIED" view with Settings link (not black screen)

---

## 3. Form Analysis & VBT (Phases 4 + 5)

### What to Test
Rep counting with form scoring, velocity tracking, fatigue detection, and auto-stop.

### Steps

1. Start a workout session → select **Barbell Back Squat** from exercise picker
2. Enter weight (e.g., 60 kg)
3. Position yourself sideways to camera (profile view for squat angles)
4. Perform a squat rep:
   - **Verify**: Rep counter increments from 0 → 1
   - **Verify**: Form score updates (0-100%)
   - **Verify**: Live velocity readout appears during the ascending (concentric) phase
   - **Verify**: Phase indicator changes (descending → at bottom → ascending → at top)
5. Perform 5+ reps:
   - **Verify**: Velocity loss % increases as you fatigue
   - **Verify**: RIR badge shows estimated reps in reserve
   - If velocity loss exceeds 20%: **Verify**: Auto-stop alert banner appears
6. Tap **FINISH SET**:
   - **Verify**: Set summary shows reps, avg form, avg velocity, peak velocity, RPE, velocity zone
   - **Verify**: XP earned displayed (base 10/rep + form bonus + combo bonus)
7. Perform a second set → **Verify**: Set number increments, velocity resets for new set

### Form Issue Detection
- Perform a squat with intentional knee cave → **Verify**: "Knee Cave" issue appears in banner
- Perform bench press with wide elbows → **Verify**: "Elbow Flare" issue detected

### Ghost Mode
1. During workout, tap **GHOST** button in control bar
2. **Verify**: Semi-transparent neon green dashed skeleton appears (ideal form overlay)
3. **Verify**: Ghost skeleton matches your body proportions (limb lengths from MorphoScan)
4. Perform a rep → **Verify**: Ghost shows ideal position for each phase
5. Complete a rep → **Verify**: Floating "+LP" gold particle near body
6. Tap **GHOST** again → **Verify**: Ghost overlay disappears

### Red Flags
- Rep counter fires multiple times per rep → smoothing window too small
- Form score always 100 or always 0 → angle computation broken
- Velocity always 0 → VBT calibration failed (no height data)
- Ghost skeleton offset from body → anchor frame coordinate mismatch

---

## 4. E-Sport Ranking & Social (Phases 6 + 10)

### What to Test
LP calculation, tier progression, promotion series, guild CRUD, and share cards.

### Steps — Ranking

1. Complete a full workout (3+ sets)
2. At session summary → **Verify**: LP earned displayed with tier color
3. Navigate to **Ranking** tab:
   - **Verify**: Current tier badge with correct icon and color
   - **Verify**: LP progress bar shows position within current tier
   - **Verify**: Rank factors: strength-to-weight ratio, form quality, velocity score
   - **Verify**: Recent sessions list with LP history
4. After multiple sessions reaching tier threshold:
   - **Verify**: Promotion series UI appears (3 circles to fill)
   - **Verify**: Consecutive increasing LP sessions fill circles
   - **Verify**: 3/3 wins → tier promotion with announcement

### Steps — Social

1. From Ranking tab → tap **SOCIAL HUB** card at bottom
2. **Verify**: SocialDashboardView opens with Guild/Leaderboard/Share segments
3. **Guild** segment:
   - Tap **CREATE GUILD** → enter name + tag → tap **CREATE**
   - **Verify**: Guild banner shows name, tag, war record (0-0)
   - **Verify**: Current user appears as "Leader" with real LP
   - Tap **LEAVE GUILD** → **Verify**: Empty state returns
4. **Leaderboard** segment:
   - **Verify**: Personal best sessions ranked by LP (or empty state if no sessions)
5. **Share** segment:
   - Tap **GENERATE CARD** → **Verify**: Cyberpunk-styled session card preview (390x520pt)
   - Card shows: tier badge, username, exercise, stats grid, LP earned, golden ratio %
   - Tap **SHARE** → **Verify**: iOS share sheet opens with card image

### Red Flags
- LP always 0 → `RankingEngine.calculateWorkoutLP` returning 0 (check bodyweight is set)
- Tier not advancing → promotion series not tracking consecutive wins
- Guild create fails silently → CoreData save error
- Share card blank → `ImageRenderer` failed (check @MainActor)

---

## 5. Recovery & BioAdaptive (Phase 7)

### What to Test
HealthKit integration, readiness scoring, muscle recovery heatmap, and cycle sync.

### Prerequisites
- Grant HealthKit permissions (HRV, sleep, resting HR, active energy)
- Wear Apple Watch overnight for HRV/sleep data
- Have at least 1 week of workout history for muscle recovery data

### Steps

1. Navigate to **Recovery** tab
2. Grant HealthKit permissions when prompted
3. **Verify**: Readiness ring shows overall score (0-100)
4. **Verify**: Component breakdown:
   - HRV score (35% weight) — vs 14-day baseline
   - Sleep score (30% weight) — hours slept
   - Resting HR score (15% weight)
   - Muscle recovery score (20% weight)
5. **Heatmap** segment:
   - **Verify**: Muscle groups shown with recovery zone colors (green/yellow/orange/red)
   - **Verify**: Recently trained muscles show lower recovery %
   - Expand a muscle row → **Verify**: Volume sets, last trained time, estimated full recovery
6. **Biometrics** segment:
   - **Verify**: Component score rings (HRV/Sleep/HR/Muscle)
   - **Verify**: HRV trend card (current vs 14-day average + delta %)
   - If female profile: **Verify**: Cycle sync card with phase + intensity/volume guidance

### Auto-Deload Detection
1. Simulate poor recovery: workout late at night with poor sleep
2. Return next day → **Verify**: Deload banner appears if:
   - HRV dropped >15% vs baseline, OR
   - 2 consecutive sessions with velocity decline, OR
   - 3+ day sleep deficit detected
3. **Verify**: Training adjustment card shows -20% load recommendation

### Red Flags
- All readiness components at 0 → HealthKit queries returning empty (check permissions)
- Muscle heatmap all green after recent training → `RecoveryHeatmapEngine.logVolume()` not called
- Cycle phase showing "Unknown" → `CycleSyncService` needs menstrual flow data in Health app
- Crash on Recovery tab → HealthKit background query failing without authorization

---

## Audio & Announcer Quick Checks (Phase 9)

These tests complement the workout flow above.

1. During a workout:
   - Complete a rep → **Verify**: Short tone beep + voice announcement ("Rep 1!")
   - Hit 3-rep combo → **Verify**: Combo tone + "Three-rep combo!" voice
   - Finish a set → **Verify**: Chord SFX + haptic feedback
2. Navigate to **Profile** → **Audio & Announcer**:
   - Switch voice packs (E-Sport / Sober Coach / Spartan Warrior) → **Verify**: Preview plays different voice
   - Adjust volume sliders → **Verify**: Volume changes apply
   - Toggle haptics off → **Verify**: No haptic feedback during workout

---

## Common Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Black camera screen | Permission not granted | Settings → AuraLift → Camera |
| No skeleton overlay | Vision not detecting pose | Better lighting, step back further |
| Rep counter not working | Wrong exercise profile | Ensure correct exercise selected |
| Velocity always 0 | No height calibration | Set height in Profile or do MorphoScan |
| HealthKit data empty | Permissions denied | Settings → Health → AuraLift → enable all |
| Share card blank | ImageRenderer threading | Should run on @MainActor |
| Ghost skeleton wrong size | No MorphoScan data | Perform a MorphoScan first |
| Audio not playing | Silent mode on | Check device ringer switch |

---

## Testing Checklist

- [ ] Camera permission grant/deny flow
- [ ] Skeleton overlay tracking (front + back camera)
- [ ] MorphoScan complete flow (T-pose → capture → results)
- [ ] Rep counting accuracy (at least 10 reps of squats)
- [ ] Form issue detection (intentional bad form)
- [ ] Velocity readout during concentric phase
- [ ] Auto-stop alert at 20% velocity loss
- [ ] Ghost mode toggle and ideal overlay
- [ ] LP calculation and tier display after session
- [ ] Guild create/leave flow
- [ ] Share card generation and iOS share sheet
- [ ] HealthKit data in Recovery tab
- [ ] Readiness score with real biometrics
- [ ] Muscle recovery heatmap after workout
- [ ] Audio announcements during workout
- [ ] Haptic feedback during reps
- [ ] Voice pack switching in settings
